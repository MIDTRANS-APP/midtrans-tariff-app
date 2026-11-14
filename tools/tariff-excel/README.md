# Syrian tariff ⇄ Excel

Change tariff lines without a new app release. The app re-downloads
`https://www.mid-trans.com/reference/syrian-hs-code-tariff/syrian-hs-code-tariff.json`
every 12 hours (ETag) and ignores a file with fewer than 5,000 lines
(`AppConfig.minTariffRows`). Replacing that file on the website is enough.

## Steps

```bash
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
curl -o live.json https://www.mid-trans.com/reference/syrian-hs-code-tariff/syrian-hs-code-tariff.json

# 1. sheet for the team (all current lines, dropdowns, Arabic instructions sheet)
.venv/bin/python tariff_excel.py export live.json Syrian-tariff-template.xlsx

# 2. after the team edits it: check it, write the new JSON and a change report
.venv/bin/python tariff_excel.py build edited.xlsx live.json syrian-hs-code-tariff.json report.xlsx
```

`build` refuses the file (exit 1, one Arabic line per error) for: a code that is not
8 digits, a duplicate, an unknown category or unit, a fee cell it cannot read, a change
without a source in «الإعدادات» B2, or fewer than 5,000 lines.

Review `report.xlsx` (added / removed / changed, before and after) with the owner, then
publish the JSON on the website under the server's deploy rules.

## What the sheet means

| Column | Field(s) |
|---|---|
| رقم البند | `hs_code` (8 digits; a lost leading zero is restored) |
| الوصف بالعربية / Description | `description_ar` / `description_en` |
| الفئة | `category_ar` + `category_en` (fixed list of 11) |
| الوحدة | `unit_ar`, `unit_en`, `unit` |
| رسم الاستيراد | `duty_rate` + `_ar/_en` + `duty_status` |
| الرسوم الإضافية | `additional_fees` + `_ar/_en` + `service_fee_status` |
| الرسم الكلي | `total_fee` + `_ar/_en` + `total_fee_status` |
| رسم التصدير | `export_tax` + `_ar/_en` + `export_tax_status` |
| بدل خدمات التصدير للطن | `export_service_fee_per_ton_ar/_en` |
| ملاحظة التعديل | `decree_amendment_ar` |
| استُبدل بـ | `replaced_by` |

Fee cells: a number → `numeric`; «القائمة السلبية» → `negative_list`; «معفى من الرسم»
→ `exempt` (import duty only); «20%» → `percent_of_invoice` (total only); blank →
`not_listed`. Numbers are shown with 2 decimals (4 below 1), as in the live file.

Lines the sheet leaves unchanged are copied from the live file untouched. Changed and new
lines get `source` = «الإعدادات» B2, `source_status` = `midtrans_excel_update`,
`approved_by` = `MIDTRANS (owner), <date>`, `last_reviewed` = B1, and a note; the
`source` block gets updated counts and a new `later_amendments` entry listing the codes.
Exporting the live file and building it back gives the same file.
