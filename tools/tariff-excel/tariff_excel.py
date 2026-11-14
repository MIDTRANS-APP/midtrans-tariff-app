"""Syrian customs tariff <-> Excel.

  export  JSON -> Excel the team edits   : tariff_excel.py export live.json out.xlsx
  build   Excel -> JSON the app downloads: tariff_excel.py build edited.xlsx live.json new.json report.xlsx

Lines the sheet leaves unchanged are copied from the live file untouched. Changed and new
lines are rebuilt from the sheet and stamped with the source, date and approval written in
the «الإعدادات» sheet; the file's source block records them as a new amendment.
`build` refuses a file the app would reject (fewer than 5,000 lines, bad codes, duplicates).
"""
import copy
import datetime as dt
import json
import re
import sys

from openpyxl import Workbook, load_workbook
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.worksheet.datavalidation import DataValidation

MIN_ROWS = 5000  # AppConfig.minTariffRows in the Syrian app
NEG_AR, NEG_EN = "القائمة السلبية", "Negative List"
EXEMPT_AR, EXEMPT_EN = "معفى من الرسم", "Exempt"

CATEGORIES = {
    "المواد الكيميائية واللدائن": "Chemicals, Plastics and Rubber",
    "الآلات والمعدات الكهربائية": "Machinery and Electrical Equipment",
    "المنسوجات والملابس": "Textiles and Clothing",
    "المعادن والمنتجات المعدنية": "Metals and Metal Products",
    "الحيوانات والمنتجات الحيوانية": "Animals and Animal Products",
    "المركبات والأثاث": "Vehicles, Furniture and Miscellaneous Manufactured Articles",
    "المنتجات الغذائية والمشروبات": "Food Products and Beverages",
    "الخشب والورق": "Wood, Paper and Related Products",
    "المعادن والوقود": "Minerals and Fuels",
    "الجلود والفراء": "Leather, Hides and Furs",
    "بنود خاصة": "Special Provisions",
}
UNITS = {
    "وزن": "Weight",
    "فاتورة": "Invoice value",
    "عدد": "Number",
    "قطعة": "Piece",
    "متر مكعب": "Cubic metre",
    "KVA كيلو فولت امبير": "KVA Kilovolt Ampere",
    "KVA كيلو فولت أمبير": "KVA Kilovolt Ampere",
}

COLS = [  # header, width, live field
    ("رقم البند (8 أرقام)", 14, "hs_code"),
    ("الوصف بالعربية", 55, "description_ar"),
    ("Description (English)", 55, "description_en"),
    ("الفئة", 26, "category_ar"),
    ("الوحدة", 14, "unit_ar"),
    ("رسم الاستيراد", 14, "duty_rate"),
    ("الرسوم الإضافية", 14, "additional_fees"),
    ("الرسم الكلي", 14, "total_fee"),
    ("رسم التصدير", 12, "export_tax"),
    ("بدل خدمات التصدير للطن", 16, "export_service_fee_per_ton_ar"),
    ("ملاحظة التعديل (عربي، اختياري)", 40, "decree_amendment_ar"),
    ("استُبدل بالبند/البنود (اختياري)", 22, "replaced_by"),
]
HEADERS = [c[0] for c in COLS]


def fmt_num(v):
    """Display text of a number, the way the live file writes it."""
    v = round(v, 2) if abs(v) >= 1 else round(v, 4)
    return f"{v:.4f}".rstrip("0").rstrip(".")


def text(v):
    return "" if v is None else str(v).strip()


def norm(v):
    return re.sub(r"\s+", " ", text(v))


# ---------- one fee cell: live row -> Excel value, Excel value -> live fields ----------

FEES = [  # (excel col index, value field, status field, allowed words)
    (5, "duty_rate", "duty_status", ("negative", "exempt")),
    (6, "additional_fees", "service_fee_status", ("negative",)),
    (7, "total_fee", "total_fee_status", ("negative", "percent")),
    (8, "export_tax", "export_tax_status", ()),
]


def fee_to_cell(row, field, status_field):
    st = row[status_field]
    if st in ("numeric",):
        return row[field]
    if st == "not_listed":
        return None
    return row[f"{field}_ar"]  # القائمة السلبية / معفى من الرسم / 20%


def cell_to_fee(v, allowed):
    """-> (value, ar, en, status) or raises ValueError."""
    if v is None or text(v) == "":
        return "", "", "", "not_listed"
    if isinstance(v, (int, float)) and not isinstance(v, bool):
        num = int(v) if float(v).is_integer() else float(v)
        s = fmt_num(float(v))
        return num, s, s, "numeric"
    s = text(v)
    if re.fullmatch(r"-?\d+(\.\d+)?", s):
        return cell_to_fee(float(s), allowed)
    if "negative" in allowed and s in (NEG_AR, "قائمة سلبية", NEG_EN):
        return "", NEG_AR, NEG_EN, "negative_list"
    if "exempt" in allowed and s.startswith("معفى"):
        return "", EXEMPT_AR, EXEMPT_EN, "exempt"
    m = re.fullmatch(r"(\d+(\.\d+)?)\s*%", s)
    if "percent" in allowed and m:
        p = f"{float(m.group(1)):g}%"
        return "", p, p, "percent_of_invoice"
    raise ValueError(s)


def export_fee_en(ar):
    if ar in ("قائمة سلبية", NEG_AR):
        return NEG_EN
    return re.sub(r"^عدد\s*/", "Number /", ar)


def row_to_cells(r):
    return [
        r["hs_code"], r["description_ar"], r["description_en"], r["category_ar"], r["unit_ar"] or None,
        fee_to_cell(r, "duty_rate", "duty_status"),
        fee_to_cell(r, "additional_fees", "service_fee_status"),
        fee_to_cell(r, "total_fee", "total_fee_status"),
        fee_to_cell(r, "export_tax", "export_tax_status"),
        r["export_service_fee_per_ton_ar"] or None,
        r.get("decree_amendment_ar") or None,
        r.get("replaced_by") or None,
    ]


def cells_key(cells):
    """Comparable form of a sheet line (numbers by value, text without spacing noise)."""
    out = []
    for v in cells:
        if isinstance(v, (int, float)) and not isinstance(v, bool):
            out.append(round(float(v), 6))
        elif v is None or text(v) == "":
            out.append("")
        else:
            s = norm(v)
            out.append(round(float(s), 6) if re.fullmatch(r"-?\d+(\.\d+)?", s) else s)
    return out


# ---------------------------------- export ----------------------------------

INSTRUCTIONS = [
    ("كيف تعدّل التعرفة السورية دون إصدار جديد للتطبيق", True),
    ("", False),
    ("1. عدّل ورقة «البنود» فقط. كل سطر بند واحد. لا تغيّر عناوين الأعمدة ولا ترتيبها.", False),
    ("2. رقم البند: 8 أرقام بالضبط (مثال 01012100). إن ضاع الصفر في أوله يُعاد تلقائياً.", False),
    ("3. الفئة والوحدة: اختر من القائمة. الوحدة تُترك فارغة إن لم تكن للبند وحدة.", False),
    ("4. أعمدة الرسوم (الاستيراد، الإضافية، الكلي، التصدير):", False),
    ("   • رقم: اكتب الرقم فقط (225 أو 6.6667).", False),
    ("   • القائمة السلبية: اكتب «القائمة السلبية» (رسم الاستيراد والإضافية والكلي).", False),
    ("   • معفى: اكتب «معفى من الرسم» (رسم الاستيراد فقط).", False),
    ("   • نسبة من الفاتورة: اكتب مثل 20% (الرسم الكلي فقط).", False),
    ("   • غير مدرج: اترك الخانة فارغة.", False),
    ("5. بدل خدمات التصدير للطن: كما هو مكتوب في الجدول (2، أو عدد / 2، أو قائمة سلبية).", False),
    ("6. ملاحظة التعديل: تظهر للمستخدم تحت البند (مثال: تخفيض رسم الاستيراد الكلي من 53 إلى 27).", False),
    ("7. استُبدل بـ: إن ألغى قرارٌ هذا البند واستبدله، اكتب الرقم الجديد (أو أكثر مفصولة بفاصلة).", False),
    ("8. لإضافة بند: أضف سطراً جديداً. لحذف بند: احذف سطره كاملاً. الترتيب لا يهم.", False),
    ("9. في ورقة «الإعدادات»: اكتب تاريخ المراجعة ومصدر التعديل (رقم القرار وتاريخه). هذا النص", False),
    ("   يظهر للمستخدم كمصدر على كل بند عدّلته أو أضفته؛ البنود التي لم تلمسها تبقى بمصدرها القديم.", False),
    ("", False),
    ("بعد التعبئة: أرسل الملف إلى Claude. الأداة تفحصه وترفض أي خطأ، ثم تعطي تقريراً بالبنود المضافة", False),
    ("والمحذوفة والمعدّلة (قبل وبعد) لتراجعه. بعد موافقتك يُرفع الملف إلى موقع ميدترانس، والتطبيق يأخذه", False),
    ("خلال 12 ساعة دون أي إصدار جديد.", False),
]


def export(live_path, out_path):
    live = json.load(open(live_path, encoding="utf-8"))
    rows = sorted(live["rows"], key=lambda r: r["hs_code"])
    wb = Workbook()
    ws = wb.active
    ws.title = "البنود"
    ws.sheet_view.rightToLeft = True
    fill = PatternFill("solid", fgColor="1F3A5F")
    for i, (h, w, _) in enumerate(COLS, 1):
        c = ws.cell(row=1, column=i, value=h)
        c.font = Font(bold=True, color="FFFFFF")
        c.fill = fill
        c.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
        ws.column_dimensions[c.column_letter].width = w
    ws.row_dimensions[1].height = 34
    for r in rows:
        ws.append(row_to_cells(r))
    n = ws.max_row
    for (cell,) in ws.iter_rows(min_row=2, max_row=n, min_col=1, max_col=1):
        cell.number_format = "@"
    for (cell,) in ws.iter_rows(min_row=2, max_row=n, min_col=12, max_col=12):
        cell.number_format = "@"

    lists = wb.create_sheet("قوائم")
    for i, c in enumerate(CATEGORIES, 1):
        lists.cell(row=i, column=1, value=c)
    for i, u in enumerate(UNITS, 1):
        lists.cell(row=i, column=2, value=u)
    lists.sheet_state = "hidden"
    last = n + 3000
    dv = DataValidation(type="list", formula1=f"=قوائم!$A$1:$A${len(CATEGORIES)}", allow_blank=False,
                        showErrorMessage=True, errorTitle="فئة غير معروفة", error="اختر من القائمة")
    dv.add(f"D2:D{last}")
    du = DataValidation(type="list", formula1=f"=قوائم!$B$1:$B${len(UNITS)}", allow_blank=True,
                        showErrorMessage=True, errorTitle="وحدة غير معروفة", error="اختر من القائمة أو اترك فارغاً")
    du.add(f"E2:E{last}")
    ws.add_data_validation(dv)
    ws.add_data_validation(du)
    ws.freeze_panes = "B2"
    ws.auto_filter.ref = f"A1:L{n}"

    st = wb.create_sheet("الإعدادات")
    st.sheet_view.rightToLeft = True
    src = live["source"]
    st["A1"], st["B1"] = "تاريخ المراجعة (YYYY-MM-DD)", dt.date.today().isoformat()
    st["A2"], st["B2"] = "مصدر التعديل (بالإنكليزية، يظهر للمستخدم)", ""
    st["C2"] = "مثال: Syrian Customs decree No. 12 of 2027, received 2027-01-15"
    st["A4"], st["B4"] = "الملف الحالي على الموقع", src.get("name", "")
    st["A5"], st["B5"] = "آخر مراجعة له", src.get("last_reviewed", "")
    st["A6"], st["B6"] = "عدد البنود فيه", src.get("record_count", len(rows))
    for c in ("A1", "A2", "A4", "A5", "A6"):
        st[c].font = Font(bold=True)
    st.column_dimensions["A"].width = 40
    st.column_dimensions["B"].width = 80
    st.column_dimensions["C"].width = 60

    ins = wb.create_sheet("تعليمات", 0)
    ins.sheet_view.rightToLeft = True
    ins.column_dimensions["A"].width = 120
    for i, (t, bold) in enumerate(INSTRUCTIONS, 1):
        ins.cell(row=i, column=1, value=t).font = Font(bold=bold, size=14 if bold else 12)
    wb.active = 1
    wb.save(out_path)
    print(f"exported {len(rows)} lines -> {out_path}")


# ---------------------------------- build ----------------------------------

def clean_code(v):
    if v is None:
        return ""
    if isinstance(v, float) and v.is_integer():
        v = int(v)
    s = re.sub(r"\D", "", str(v))
    if 0 < len(s) < 8 and isinstance(v, int):
        s = s.zfill(8)
    return s


def build(xlsx_path, live_path, out_path, report_path):
    live_doc = json.load(open(live_path, encoding="utf-8"))
    live = {r["hs_code"]: r for r in live_doc["rows"]}
    wb = load_workbook(xlsx_path, data_only=True)
    ws, st = wb["البنود"], wb["الإعدادات"]
    reviewed = st["B1"].value
    reviewed = reviewed.strftime("%Y-%m-%d") if isinstance(reviewed, (dt.date, dt.datetime)) else text(reviewed)
    origin = text(st["B2"].value)

    errors, out_rows, seen, touched = [], [], {}, []
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", reviewed):
        errors.append(f"الإعدادات B1: تاريخ المراجعة «{reviewed}» ليس بالشكل YYYY-MM-DD")
    if [text(c.value) for c in ws[1][:len(COLS)]] != HEADERS:
        errors.append("عناوين الأعمدة في ورقة «البنود» تغيّرت")

    for i, cells in enumerate(ws.iter_rows(min_row=2, max_col=len(COLS), values_only=True), 2):
        cells = list(cells)
        if all(v is None or text(v) == "" for v in cells):
            continue
        code = clean_code(cells[0])
        if len(code) != 8:
            errors.append(f"السطر {i}: رقم البند «{cells[0]}» ليس 8 أرقام")
            continue
        if code in seen:
            errors.append(f"السطر {i}: البند {code} مكرر (سبق في السطر {seen[code]})")
            continue
        seen[code] = i
        cells[0] = code
        old = live.get(code)
        if old and cells_key(cells) == cells_key(row_to_cells(old)):
            out_rows.append(old)  # untouched: keep the live line exactly
            continue

        d_ar, d_en, cat, unit = (text(c) for c in cells[1:5])
        if not d_ar and not d_en:
            errors.append(f"السطر {i}: البند {code} بلا وصف")
        if cat not in CATEGORIES:
            errors.append(f"السطر {i}: الفئة «{cat}» غير معروفة")
        if unit and unit not in UNITS:
            errors.append(f"السطر {i}: الوحدة «{unit}» غير معروفة")
        fees = {}
        for col, field, status_field, allowed in FEES:
            try:
                fees[field] = (status_field, cell_to_fee(cells[col], allowed))
            except ValueError as e:
                errors.append(f"السطر {i}: «{HEADERS[col]}» = «{e}» غير مفهوم")
        exp_svc = text(cells[9])
        if exp_svc.replace(".", "", 1).isdigit():
            exp_svc = fmt_num(float(exp_svc))
        note_ar = text(cells[10])
        repl = [clean_code(x) for x in re.split(r"[,،\s]+", text(cells[11])) if x]
        for x in repl:
            if len(x) != 8:
                errors.append(f"السطر {i}: «استُبدل بـ» فيه رقم «{x}» ليس 8 أرقام")
        if len(fees) < len(FEES) or cat not in CATEGORIES or (unit and unit not in UNITS):
            continue

        r = copy.deepcopy(old) if old else {}
        r.update({
            "hs_code": code,
            "description_ar": d_ar if not old or norm(old["description_ar"]) != norm(d_ar) else old["description_ar"],
            "description_en": d_en if not old or norm(old["description_en"]) != norm(d_en) else old["description_en"],
            "category_ar": cat, "category_en": CATEGORIES[cat],
            "unit_ar": unit, "unit_en": UNITS.get(unit, ""), "unit": unit,
        })
        for field, (status_field, (val, ar, en, status)) in fees.items():
            r[field], r[f"{field}_ar"], r[f"{field}_en"], r[status_field] = val, ar, en, status
        r["export_service_fee_per_ton_ar"] = exp_svc
        r["export_service_fee_per_ton_en"] = export_fee_en(exp_svc)
        r["source"] = origin
        r["source_status"] = "midtrans_excel_update"
        r["in_latest_amendment"] = not repl
        r["last_reviewed"] = reviewed
        r["approved_by"] = f"MIDTRANS (owner), {reviewed}"
        r["notes"] = (f"Replaced by {', '.join(repl)} under: {origin}; figures kept for reference only." if repl
                      else f"Figures from: {origin} (approved by MIDTRANS on {reviewed}).")
        if note_ar:
            r["decree_amendment_ar"] = note_ar
        else:
            r.pop("decree_amendment_ar", None)
        if repl:
            r["replaced_by"] = ", ".join(repl)
        else:
            r.pop("replaced_by", None)
        out_rows.append(r)
        touched.append(code)

    removed = sorted(set(live) - set(seen))
    if (touched or removed) and not origin:
        errors.append("الإعدادات B2: اكتب مصدر التعديل (يظهر للمستخدم على البنود المعدّلة)")
    if len(out_rows) < MIN_ROWS:
        errors.append(f"عدد البنود {len(out_rows)} أقل من {MIN_ROWS}: التطبيق يرفض ملفاً بهذا الحجم")
    if errors:
        print(f"REFUSED: {len(errors)} error(s)")
        for e in errors[:200]:
            print(" -", e)
        sys.exit(1)

    out_rows.sort(key=lambda r: r["hs_code"])
    source = copy.deepcopy(live_doc["source"])
    if touched or removed:
        source["last_reviewed"] = reviewed
        source["record_count"] = len(out_rows)
        source["amended_lines"] = sum(1 for r in out_rows if r.get("in_latest_amendment") is not False)
        source["kept_lines_not_in_amendment"] = len(out_rows) - source["amended_lines"]
        source.setdefault("later_amendments", []).append({
            "name": f"{origin} (approved by MIDTRANS on {reviewed}, from Excel)",
            "status": "midtrans_excel_update",
            "received": reviewed,
            "codes": touched,
            "removed": removed,
            "replaced": {c: r["replaced_by"] for c in touched for r in [next(x for x in out_rows if x["hs_code"] == c)]
                         if r.get("replaced_by")},
        })
    doc = dict(live_doc)
    doc["source"] = source
    doc["rows"] = out_rows
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(doc, f, ensure_ascii=False, separators=(",", ":"))

    # ---------- report ----------
    new = {r["hs_code"]: r for r in out_rows}
    added = [c for c in touched if c not in live]
    changed = []
    for c in touched:
        if c in live:
            for h, a, b in zip(HEADERS, row_to_cells(live[c]), row_to_cells(new[c])):
                if cells_key([a]) != cells_key([b]):
                    changed.append((c, h, a, b))
    rep = Workbook()
    s = rep.active
    s.title = "الملخص"
    s.sheet_view.rightToLeft = True
    for r in [("البنود في الملف الجديد", len(out_rows)), ("البنود على الموقع الآن", len(live)),
              ("مضاف", len(added)), ("محذوف", len(removed)), ("بنود معدّلة", len(touched) - len(added)),
              ("مصدر التعديل", origin), ("تاريخ المراجعة", reviewed)]:
        s.append(r)
    s.column_dimensions["A"].width = 28
    s.column_dimensions["B"].width = 70
    for title, data, head in [
        ("مضاف", [(c, new[c]["description_ar"], new[c]["total_fee_ar"]) for c in added], ("البند", "الوصف", "الرسم الكلي")),
        ("محذوف", [(c, live[c]["description_ar"], live[c]["total_fee_ar"]) for c in removed], ("البند", "الوصف", "الرسم الكلي")),
        ("معدّل", changed, ("البند", "العمود", "قبل", "بعد")),
    ]:
        sh = rep.create_sheet(title)
        sh.sheet_view.rightToLeft = True
        sh.append(head)
        for cell in sh[1]:
            cell.font = Font(bold=True)
        for d in data:
            sh.append(list(d))
        for col, w in zip("ABCD", (14, 50, 40, 40)):
            sh.column_dimensions[col].width = w
    rep.save(report_path)
    print(f"OK {len(out_rows)} lines -> {out_path}")
    print(f"added {len(added)}, removed {len(removed)}, changed lines {len(touched) - len(added)} -> {report_path}")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "export" and len(sys.argv) == 4:
        export(sys.argv[2], sys.argv[3])
    elif cmd == "build" and len(sys.argv) == 6:
        build(*sys.argv[2:6])
    else:
        print(__doc__)
        sys.exit(2)
