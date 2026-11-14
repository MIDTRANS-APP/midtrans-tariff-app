"""GCC customs tariff <-> Excel.

  export  JSON -> Excel the team edits   : tariff_excel.py export live.json out.xlsx
  build   Excel -> JSON the apps download: tariff_excel.py build edited.xlsx live.json new.json report.xlsx

`build` checks the sheet, refuses a file the app would reject (fewer than 12,000 lines,
count mismatch, bad codes), writes the JSON in the exact shape of the live file, and a
report of added / removed / changed lines against the live file.
"""
import datetime as dt
import json
import re
import sys

from openpyxl import Workbook, load_workbook
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.worksheet.datavalidation import DataValidation

MIN_ROWS = 12000  # AppConfig.minTariffRows in the GCC app: a smaller file is ignored by the app
DEFAULT_NOTE = ("Reference import only. Final classification, duty, exemptions and import status "
                "require official GCC customs confirmation.")
DEFAULT_SOURCE_ROW = "GCC unified customs tariff — bilingual reference import"
DEFAULT_SOURCE_STATUS = "reference_import_pending_official_confirmation"

# import_status -> (Excel label, unit_ar, unit_en)
STATUS = {
    "value": ("عادي (على القيمة)", "القيمة", "Value"),
    "special": ("سلع خاصة", "سلع خاصة", "Special goods"),
    "prohibited": ("ممنوع استيراده", "ممنوع استيراده", "Prohibited"),
    "unspecified": ("غير محدّد", "", ""),
}
LABEL_TO_STATUS = {v[0]: k for k, v in STATUS.items()}

COLS = [  # header, width
    ("رقم البند (12 رقماً)", 18),
    ("الوصف بالعربية", 60),
    ("Description (English)", 60),
    ("حالة الاستيراد", 18),
    ("الرسم الجمركي %", 16),
    ("ملاحظة (اختياري)", 40),
]


def fmt_pct(v):
    return f"{v:g}%"


def make_row(code, d_ar, d_en, status, duty, note, reviewed):
    """One line in exactly the live file's field order."""
    unit_ar, unit_en = STATUS[status][1], STATUS[status][2]
    has_duty = duty is not None
    pct_ar = fmt_pct(duty) if has_duty else "غير محدّد"
    pct_en = fmt_pct(duty) if has_duty else "Not specified"
    return {
        "hs_code": code,
        "hs_code_spaced": " ".join(code[i:i + 2] for i in range(0, 12, 2)),
        "heading": f"{code[:2]}.{code[2:4]}",
        "description_ar": d_ar,
        "description_en": d_en,
        "category_ar": f"الفصل {code[:2]} — البند {code[:2]}.{code[2:4]}",
        "category_en": f"Chapter {code[:2]} — Heading {code[:2]}.{code[2:4]}",
        "unit_ar": unit_ar,
        "unit_en": unit_en,
        "unit": unit_ar,
        "import_status": status,
        "duty_rate": float(duty) if has_duty else "",
        "duty_rate_ar": pct_ar,
        "duty_rate_en": pct_en,
        "duty_status": "percent" if has_duty else "unspecified",
        "additional_fees": "",
        "additional_fees_ar": "—",
        "additional_fees_en": "—",
        "service_fee_status": "not_applicable",
        "total_fee": float(duty) if has_duty else "",
        "total_fee_ar": pct_ar,
        "total_fee_en": pct_en,
        "total_fee_status": "percent" if has_duty else "unspecified",
        "export_tax": "",
        "export_tax_ar": "—",
        "export_tax_en": "—",
        "export_tax_status": "not_applicable",
        "export_service_fee_per_ton_ar": "—",
        "export_service_fee_per_ton_en": "—",
        "source": DEFAULT_SOURCE_ROW,
        "source_status": DEFAULT_SOURCE_STATUS,
        "last_reviewed": reviewed,
        "approved_by": "",
        "notes": note or DEFAULT_NOTE,
    }


INSTRUCTIONS = [
    ("كيف تعدّل التعرفة الخليجية دون إصدار جديد للتطبيق", True),
    ("", False),
    ("1. عدّل ورقة «البنود» فقط. كل سطر بند واحد. لا تغيّر عناوين الأعمدة ولا ترتيبها.", False),
    ("2. رقم البند: 12 رقماً بالضبط، أرقام فقط (مثال 010121100001). تُقبل النقاط والمسافات وتُحذف تلقائياً.", False),
    ("   إن كان العمود أرقاماً في Excel وضاع الصفر في أوله، يُعاد تلقائياً.", False),
    ("3. الوصف: العربي أو الإنكليزي على الأقل. اكتب الشرطات في أول الوصف كما في التعرفة (- أو - -).", False),
    ("4. حالة الاستيراد: اختر من القائمة: عادي (على القيمة) / سلع خاصة / ممنوع استيراده / غير محدّد.", False),
    ("5. الرسم الجمركي %: رقم فقط (5 تعني 5%). اتركه فارغاً إن لم يكن للبند نسبة.", False),
    ("6. ملاحظة: اختيارية. إن تُركت فارغة توضع الملاحظة المعتادة (مرجعي، والتأكيد من الجمارك).", False),
    ("7. لإضافة بند: أضف سطراً جديداً في أي مكان. لحذف بند: احذف سطره كاملاً. الترتيب لا يهم.", False),
    ("8. في ورقة «الإعدادات»: اكتب تاريخ المراجعة ومصدر التعديل (رقم القرار مثلاً).", False),
    ("", False),
    ("بعد التعبئة: أرسل الملف إلى Claude. الأداة تفحصه وترفض أي خطأ (رقم ناقص، بند مكرر، حالة غير معروفة،", False),
    ("أقل من 12,000 بند)، ثم تعطي تقريراً بالبنود المضافة والمحذوفة والمعدّلة لتراجعه قبل النشر.", False),
    ("بعد موافقتك يُرفع الملف إلى موقع ميدترانس، والتطبيقات تأخذه خلال 12 ساعة دون أي إصدار جديد.", False),
]


def export(live_path, out_path):
    live = json.load(open(live_path, encoding="utf-8"))
    rows = sorted(live["rows"], key=lambda r: r["hs_code"])
    wb = Workbook()
    ws = wb.active
    ws.title = "البنود"
    ws.sheet_view.rightToLeft = True
    head_fill = PatternFill("solid", fgColor="1F3A5F")
    for i, (h, w) in enumerate(COLS, 1):
        c = ws.cell(row=1, column=i, value=h)
        c.font = Font(bold=True, color="FFFFFF")
        c.fill = head_fill
        c.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
        ws.column_dimensions[c.column_letter].width = w
    for r in rows:
        duty = r["duty_rate"] if r["duty_status"] == "percent" else None
        note = "" if r["notes"] == DEFAULT_NOTE else r["notes"]
        ws.append([r["hs_code"], r["description_ar"], r["description_en"],
                   STATUS[r["import_status"]][0], duty, note])
    n = ws.max_row
    for row in ws.iter_rows(min_row=2, max_row=n, min_col=1, max_col=1):
        row[0].number_format = "@"
    dv = DataValidation(type="list", formula1='"' + ",".join(v[0] for v in STATUS.values()) + '"',
                        allow_blank=False, showErrorMessage=True,
                        errorTitle="حالة غير معروفة", error="اختر من القائمة")
    dv.add(f"D2:D{n + 5000}")
    ws.add_data_validation(dv)
    dn = DataValidation(type="decimal", operator="between", formula1="0", formula2="1000",
                        allow_blank=True, showErrorMessage=True,
                        errorTitle="رقم غير صالح", error="اكتب رقماً بين 0 و 1000، أو اتركه فارغاً")
    dn.add(f"E2:E{n + 5000}")
    ws.add_data_validation(dn)
    ws.freeze_panes = "B2"
    ws.auto_filter.ref = f"A1:F{n}"

    st = wb.create_sheet("الإعدادات")
    st.sheet_view.rightToLeft = True
    st["A1"], st["B1"] = "تاريخ المراجعة (YYYY-MM-DD)", dt.date.today().isoformat()
    st["A2"], st["B2"] = "مصدر التعديل", ""
    st["A4"] = "الملف الحالي على الموقع:"
    st["B4"] = live["source"]
    st["A5"], st["B5"] = "عدد البنود فيه", live["count"]
    for c in ("A1", "A2", "A4", "A5"):
        st[c].font = Font(bold=True)
    st.column_dimensions["A"].width = 30
    st.column_dimensions["B"].width = 80

    ins = wb.create_sheet("تعليمات", 0)
    ins.sheet_view.rightToLeft = True
    ins.column_dimensions["A"].width = 130
    for i, (t, bold) in enumerate(INSTRUCTIONS, 1):
        ins.cell(row=i, column=1, value=t).font = Font(bold=bold, size=14 if bold else 12)
    wb.active = 1
    wb.save(out_path)
    print(f"exported {len(rows)} lines -> {out_path}")


def norm(v):
    return re.sub(r"\s+", " ", "" if v is None else str(v)).strip()


def clean_code(v):
    if v is None:
        return ""
    if isinstance(v, float) and v.is_integer():
        v = int(v)
    s = re.sub(r"\D", "", str(v))
    if 0 < len(s) < 12 and isinstance(v, int):
        s = s.zfill(12)  # Excel dropped the leading zero(s)
    return s


def text(v):
    return "" if v is None else str(v).strip()


def build(xlsx_path, live_path, out_path, report_path):
    wb = load_workbook(xlsx_path, data_only=True)
    ws = wb["البنود"]
    st = wb["الإعدادات"]
    reviewed = text(st["B1"].value)
    if isinstance(st["B1"].value, (dt.date, dt.datetime)):
        reviewed = st["B1"].value.strftime("%Y-%m-%d")
    origin = text(st["B2"].value)

    errors, rows, seen = [], [], {}
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", reviewed):
        errors.append(f"الإعدادات B1: تاريخ المراجعة «{reviewed}» ليس بالشكل YYYY-MM-DD")
    headers = [text(c.value) for c in ws[1][:len(COLS)]]
    if headers != [h for h, _ in COLS]:
        errors.append(f"عناوين الأعمدة تغيّرت: {headers}")
    for i, cells in enumerate(ws.iter_rows(min_row=2, max_col=len(COLS), values_only=True), 2):
        code_v, d_ar, d_en, st_label, duty_v, note = cells
        if all(v is None or text(v) == "" for v in cells):
            continue
        code = clean_code(code_v)
        d_ar, d_en, st_label, note = text(d_ar), text(d_en), text(st_label), text(note)
        if len(code) != 12:
            errors.append(f"السطر {i}: رقم البند «{code_v}» ليس 12 رقماً")
            continue
        if code in seen:
            errors.append(f"السطر {i}: البند {code} مكرر (سبق في السطر {seen[code]})")
            continue
        seen[code] = i
        if not d_ar and not d_en:
            errors.append(f"السطر {i}: البند {code} بلا وصف")
        status = LABEL_TO_STATUS.get(st_label) or (st_label if st_label in STATUS else None)
        if not status:
            errors.append(f"السطر {i}: حالة الاستيراد «{st_label}» غير معروفة")
            continue
        duty = None
        if duty_v is not None and text(duty_v) != "":
            try:
                duty = float(str(duty_v).replace("%", "").strip())
            except ValueError:
                errors.append(f"السطر {i}: الرسم «{duty_v}» ليس رقماً")
                continue
            if not 0 <= duty <= 1000:
                errors.append(f"السطر {i}: الرسم {duty} خارج 0–1000")
                continue
        rows.append(make_row(code, d_ar, d_en, status, duty, note, reviewed))

    if len(rows) < MIN_ROWS:
        errors.append(f"عدد البنود {len(rows)} أقل من {MIN_ROWS}: التطبيق يرفض ملفاً بهذا الحجم")
    if errors:
        print(f"REFUSED: {len(errors)} error(s)")
        for e in errors[:200]:
            print(" -", e)
        sys.exit(1)

    # Excel turns \r\n into \n: keep the live wording when only line endings differ
    live = {r["hs_code"]: r for r in json.load(open(live_path, encoding="utf-8"))["rows"]}
    for r in rows:
        old = live.get(r["hs_code"])
        if old:
            for f in ("description_ar", "description_en", "notes"):
                if norm(old.get(f)) == norm(r[f]):
                    r[f] = old[f]

    rows.sort(key=lambda r: r["hs_code"])
    label = f"MIDTRANS GCC unified customs tariff bilingual reference import ({reviewed})"
    if origin:
        label += f" — {origin}"
    out = {"source": label, "count": len(rows), "rows": rows}
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, separators=(",", ":"))

    # report against the live file
    new = {r["hs_code"]: r for r in rows}
    watched = ["description_ar", "description_en", "import_status", "duty_rate", "notes"]
    rep = Workbook()
    s = rep.active
    s.title = "الملخص"
    s.sheet_view.rightToLeft = True
    added = sorted(set(new) - set(live))
    removed = sorted(set(live) - set(new))
    changed = []
    for c in sorted(set(new) & set(live)):
        for f in watched:
            if str(live[c].get(f)) != str(new[c].get(f)):
                changed.append((c, f, live[c].get(f), new[c].get(f)))
    for r in [("البنود في الملف الجديد", len(rows)), ("البنود على الموقع الآن", len(live)),
              ("مضاف", len(added)), ("محذوف", len(removed)), ("تعديلات", len(changed))]:
        s.append(r)
    s.column_dimensions["A"].width = 28
    for title, data, head in [
        ("مضاف", [(c, new[c]["description_ar"], new[c]["duty_rate_ar"]) for c in added], ("البند", "الوصف", "الرسم")),
        ("محذوف", [(c, live[c]["description_ar"], live[c]["duty_rate_ar"]) for c in removed], ("البند", "الوصف", "الرسم")),
        ("معدّل", [(c, f, str(a), str(b)) for c, f, a, b in changed], ("البند", "الحقل", "قبل", "بعد")),
    ]:
        sh = rep.create_sheet(title)
        sh.sheet_view.rightToLeft = True
        sh.append(head)
        for cell in sh[1]:
            cell.font = Font(bold=True)
        for d in data:
            sh.append(d)
        for col, w in zip("ABCD", (16, 60, 40, 40)):
            sh.column_dimensions[col].width = w
    rep.save(report_path)
    print(f"OK {len(rows)} lines -> {out_path}")
    print(f"added {len(added)}, removed {len(removed)}, changed fields {len(changed)} -> {report_path}")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "export" and len(sys.argv) == 4:
        export(sys.argv[2], sys.argv[3])
    elif cmd == "build" and len(sys.argv) == 6:
        build(*sys.argv[2:6])
    else:
        print(__doc__)
        sys.exit(2)
