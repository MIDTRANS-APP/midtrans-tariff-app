# GCC Customs Tariff · MIDTRANS (com.midtrans.gcctariff)

Started 2026-11-07 as a copy of the Syrian tariff app (owner: «نفس تطبيق السوري … لدول الخليج»).
Same screens; data = https://www.mid-trans.com/reference/gcc-customs-tariff/gcc-customs-tariff.json
(13,431 lines, 12-digit codes, duty as % of CIF). Bundled data: `python3 tools/build_assets.py`.
Item page has a USD duty calculator (owner: «نسبة فقط + حاسبة بالدولار»). No government emblem.

Still on the Syrian app's accounts until the owner registers this app: Firebase
(lib/firebase_options.dart, iOS URL scheme in Info.plist), Facebook app id, Apple Sign-in Services ID.

---

# التعرفة الجمركية السورية — ميدترانس

تطبيق Flutter واحد لـ Google Play وApp Store وHuawei AppGallery، للبحث في التعرفة الجمركية السورية بالعربية والإنكليزية، ويعمل بدون إنترنت. تطبيق غير رسمي من MIDTRANS، وليس تابعاً لأي جهة حكومية.

## مصدر البيانات

- المصدر الوحيد هو الملف الذي ينشره موقع ميدترانس: `https://www.mid-trans.com/reference/syrian-hs-code-tariff/syrian-hs-code-tariff.json` (قرار المالك 15-09-2026). هو نفس الملف الذي تقرأه ميرا.
- `assets/data/syria-tariff.json.gz` نسخة من ذلك الملف المنشور، مأخوذة من `midtranss/midtrans-mira` (`src/syria-tariff.json.gz`، معتمدة 20-10-2026). يعمل التطبيق بها من أول تشغيل، ثم يتحقق من الموقع كل 12 ساعة بـ ETag ويحفظ آخر نسخة.
- الأرقام تُعرض كما وردت في الملف، بنفس قواعد ميرا (`lib/data/fee_text.dart` يطابق `feeText` في `hs-tariff-service.mjs`). لا يعدّل التطبيق الملف ولا يضيف أرقاماً.
- لا تغيير على الموقع أو على ميرا (قرار المالك 22-10-2026).

## ميرا

تبويب «اسأل ميرا» يرسمه التطبيق بتصميمه، ويرسل الأسئلة إلى `https://api.midtrans.org/api/v1/chat/ask` (`lib/data/mira_client.dart`)، بنفس طلب صفحة `https://chat.midtrans.org/`. لا يوجد WebView. تُفتح روابط `https` فقط من إجابات ميرا. بدون إنترنت تظهر رسالة، ويبقى البحث في التعرفة يعمل.

## الإعلانات

`lib/ads/ad_slot.dart` يحدد أماكن الإعلان: شريط أسفل النتائج وفي صفحة البند فقط، ولا إعلانات أثناء الكتابة أو داخل ميرا. حالياً `NoAds` لا يعرض شيئاً. عند فتح الحسابات:

- Google Play وApp Store: مزوّد AdMob (`google_mobile_ads`).
- Huawei AppGallery: مزوّد Petal Ads (`huawei_ads`) في نسخة بناء منفصلة، لأن AdMob يحتاج خدمات Google غير الموجودة على هواوي.

## التشغيل والفحص

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## البنية

- `lib/data/` قراءة الملف، البحث (أرقام عربية وهندية، توحيد الهمزات والتاء المربوطة)، نصوص الرسوم، المفضلة.
- `lib/ui/` الشاشات: البحث والأقسام، صفحة البند، المفضلة، ميرا، عن التطبيق.
- `lib/l10n.dart` نصوص الواجهة بالعربية والإنكليزية.
- الألوان بطابع موقع الهيئة العامة للمنافذ والجمارك (أخضر داكن وذهبي)، مع أزرق ميدترانس لأزرار ميدترانس. لا يُستخدم أي شعار حكومي.
- الخط: Cairo (رخصة OFL في `assets/fonts/OFL.txt`).
