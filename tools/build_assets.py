"""Builds the app's bundled data (run from the project root).

1. assets/data/gcc-tariff.json.gz — the GCC tariff exactly as mid-trans.com publishes it.
2. assets/data/hs-context.json.gz — search helpers taken from the Syrian tariff file
   (tools/source/syria-tariff.json.gz, kept only for this): chapter -> section name, and
   the 6-digit HS (the same worldwide) -> its Arabic/English wording. Used only to find
   lines when the GCC wording is short ("- Of Arab breed males"), never shown as figures.
"""
import gzip, json, sys, urllib.request

URL = 'https://www.mid-trans.com/reference/gcc-customs-tariff/gcc-customs-tariff.json'
raw = urllib.request.urlopen(urllib.request.Request(URL, headers={'User-Agent': 'midtrans-gcc-tariff-build'})).read()
gcc = json.loads(raw)
assert len(gcc['rows']) > 12000, len(gcc['rows'])
with gzip.open('assets/data/gcc-tariff.json.gz', 'wb', 9) as f:
    f.write(raw)

sy = json.load(gzip.open('tools/source/syria-tariff.json.gz'))['rows']
chapters, hs6 = {}, {}
for r in sy:
    c = r['hs_code']
    chapters.setdefault(c[:2], {'ar': r.get('category_ar', ''), 'en': r.get('category_en', '')})
    h = hs6.setdefault(c[:6], {'ar': set(), 'en': set()})
    for lang in ('ar', 'en'):
        t = (r.get(f'description_{lang}') or '').strip()
        if t:
            h[lang].add(t)
ctx = {
    'chapters': chapters,
    'hs6': {k: {'ar': ' '.join(sorted(v['ar'])), 'en': ' '.join(sorted(v['en']))} for k, v in sorted(hs6.items())},
}
with gzip.open('assets/data/hs-context.json.gz', 'wt', 9, encoding='utf-8') as f:
    json.dump(ctx, f, ensure_ascii=False, separators=(',', ':'))
print('gcc rows', len(gcc['rows']), 'chapters', len(chapters), 'hs6', len(hs6))
