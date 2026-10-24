import sys, os
R, OUT = sys.argv[1], sys.argv[2]
font = f"file://{R}/assets/fonts/Cairo-Variable.ttf"
icon = f"file://{R}/assets/branding/icon-1024.png"
emb = f"file://{R}/assets/branding/ports-emblem.png"
shots = {
 "ar": [f"file://{R}/store/screenshots/iphone/{n}.png" for n in ("1_home_ar","2_search_ar","3_item_ar")],
 "en": [f"file://{R}/store/screenshots/iphone/{n}.png" for n in ("4_search_en","1_home_ar","5_item_en")],
}
T = {
 "ar": dict(dir="rtl", title="التعرفة الجمركية السورية", sub="أكثر من 6,000 بند ورسومها · بحث بالعربية والإنكليزية · يعمل بدون إنترنت", tag="ابحث برقم البند أو باسم البضاعة، واعرف الرسوم المرجعية فوراً."),
 "en": dict(dir="ltr", title="Syrian Customs Tariff", sub="6,000+ HS codes with fees · Arabic & English · Works offline", tag="Search by HS code or goods name and see the reference fees at once."),
}
CSS = """
@font-face{font-family:Cairo;src:url('%s')}
*{margin:0;box-sizing:border-box}
html,body{width:%dpx;height:%dpx;overflow:hidden}
body{font-family:Cairo,sans-serif;color:#E8ECEB;background:
 radial-gradient(ellipse 70%% 60%% at 50%% -10%%, #2a5550 0%%, rgba(42,85,80,0) 70%%),
 linear-gradient(160deg,#123733 0%%,#0B2523 55%%,#071a18 100%%);position:relative}
.gold{color:#D9C9A0}
.phone{position:absolute;border-radius:120px;background:#05100f;padding:26px;box-shadow:0 60px 120px rgba(0,0,0,.55),0 0 0 6px #B9A67D}
.phone img{display:block;width:100%%;height:100%%;border-radius:96px;object-fit:cover;object-position:top}
.icon{border-radius:22%%;box-shadow:0 30px 80px rgba(0,0,0,.5)}
.line{height:4px;background:#8F8361;display:inline-block;vertical-align:middle}
"""
def phone(src, x, y, w, rot):
    h = int(w * 2796 / 1290)
    return f'<div class="phone" style="left:{x}px;top:{y}px;width:{w}px;height:{h}px;transform:rotate({rot}deg)"><img src="{src}"></div>'

def header(l):
    W, H = 3840, 1646; t = T[l]; s = shots[l]; rtl = l == "ar"
    # phones on the reading-start side; text on the other side
    px = [120, 760, 1400] if rtl else [1980, 2620, 3260]
    if not rtl: px = [3840 - 120 - 560 - p + 1980 - 1980 for p in px]; px = [2020, 2660, 3300] [::-1]
    ph = "".join(phone(src, x, y, 560, r) for src, x, y, r in zip(s, px, (230, 130, 230), (-6, 0, 6)))
    tx = "right:150px;text-align:right" if rtl else "left:150px;text-align:left"
    return f"""<!doctype html><html dir="{t['dir']}"><head><meta charset="utf-8"><style>{CSS % (font, W, H)}</style></head><body>
{ph}
<div style="position:absolute;top:300px;{tx};width:1700px">
 <img class="icon" src="{icon}" style="width:300px;height:300px">
 <div style="margin-top:40px"><span class="line" style="width:140px"></span> <img src="{emb}" style="height:90px;vertical-align:middle;margin:0 24px"> <span class="line" style="width:140px"></span></div>
 <div style="font-size:150px;font-weight:800;line-height:1.25;margin-top:30px;background:linear-gradient(#F2F4F4,#A7B0B0);-webkit-background-clip:text;color:transparent">{t['title']}</div>
 <div class="gold" style="font-size:62px;font-weight:600;margin-top:24px;line-height:1.5">{t['tag']}</div>
</div></body></html>"""

def search(l):
    W, H = 3840, 2560; t = T[l]; s = shots[l]
    ph = phone(s[0], 760, 900, 640, -6) + phone(s[1], 1600, 820, 640, 0) + phone(s[2], 2440, 900, 640, 6)
    return f"""<!doctype html><html dir="{t['dir']}"><head><meta charset="utf-8"><style>{CSS % (font, W, H)}</style></head><body>
<div style="position:absolute;top:150px;left:0;right:0;text-align:center">
 <div style="display:inline-flex;align-items:center;gap:60px"><img class="icon" src="{icon}" style="width:300px;height:300px">
 <div style="font-size:170px;font-weight:800;background:linear-gradient(#F2F4F4,#A7B0B0);-webkit-background-clip:text;color:transparent">{t['title']}</div></div>
 <div class="gold" style="font-size:72px;font-weight:600;margin-top:30px">{t['sub']}</div>
</div>
{ph}</body></html>"""

os.makedirs(OUT, exist_ok=True)
for l in ("ar", "en"):
    open(f"{OUT}/header-{l}.html", "w").write(header(l))
    open(f"{OUT}/search-{l}.html", "w").write(search(l))
print("ok")
