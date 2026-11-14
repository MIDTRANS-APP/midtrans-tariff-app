# GCC tariff ⇄ Excel

Change tariff lines without a new app release. The app re-downloads
`https://www.mid-trans.com/reference/gcc-customs-tariff/gcc-customs-tariff.json`
every 12 hours (ETag) and ignores a file with fewer than 12,000 lines or whose `count`
differs from its rows (`AppConfig.minTariffRows`, `TariffRepository.looksComplete`).
Replacing that file on the website is enough.

## Steps

```bash
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
curl -o live.json https://www.mid-trans.com/reference/gcc-customs-tariff/gcc-customs-tariff.json

# 1. sheet for the team (all current lines, dropdowns, Arabic instructions sheet)
.venv/bin/python tariff_excel.py export live.json GCC-tariff-template.xlsx

# 2. after the team edits it: check it, write the new JSON and a change report
.venv/bin/python tariff_excel.py build edited.xlsx live.json gcc-customs-tariff.json report.xlsx
```

`build` refuses the file (exit 1, one Arabic line per error) for: a code that is not
12 digits, a duplicate, an unknown import status, a duty that is not a number between
0 and 1000, or fewer than 12,000 lines.

Review `report.xlsx` (added / removed / changed, before and after) with the owner, then
publish the JSON on the website under the server's deploy rules.

## What the sheet means

| Column | Field(s) |
|---|---|
| رقم البند | `hs_code` (12 digits; a lost leading zero is restored), `hs_code_spaced`, `heading`, `category_*` |
| الوصف بالعربية / Description | `description_ar` / `description_en` |
| حالة الاستيراد | `import_status` + `unit_*` (value / special / prohibited / unspecified) |
| الرسم الجمركي % | `duty_rate`, `total_fee` and their `_ar/_en/_status` (blank → unspecified) |
| ملاحظة | `notes` (blank → the standard reference-only note) |

«الإعدادات» B1 sets `last_reviewed` on every line and the date in the file's `source`;
B2 (optional) is appended to `source`. Exporting the live file and building it back gives
the same rows.
