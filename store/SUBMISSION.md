# ملف تقديم تطبيق التعرفة الجمركية الخليجية للمتاجر

جاهز للنسخ عند إنشاء التطبيق في المتاجر الثلاثة. لم يُنشر شيء بعد.

## البيانات الأساسية

| | |
|---|---|
| المعرّف (iOS وAndroid) | `com.midtrans.gcctariff` |
| الإصدار | 1.0.0 (1) |
| الاسم العربي | التعرفة الجمركية الخليجية |
| الاسم الإنكليزي | GCC Customs Tariff |
| اسم المطوّر | MIDTRANS |
| الفئة | Business (أعمال) |
| السعر | مجاني |
| التقييم العمري | 4+ / Everyone |
| صفحة التحميل | https://www.mid-trans.com/gcc-tariff-app/ |
| سياسة الخصوصية | https://www.mid-trans.com/gcc-tariff-app/privacy.html |
| حذف الحساب | https://www.mid-trans.com/gcc-tariff-app/delete-account.html |
| الدعم | info@midtrans.org · https://www.mid-trans.com/contact-us/ |

النص الكامل للوصف (عربي وإنكليزي) في `store/listing.md`.

**كلمات البحث (App Store، 100 حرف):**
`تعرفة,جمارك,خليج,بند,HS,رسوم,السعودية,الإمارات,الكويت,قطر,البحرين,عمان,customs,tariff,GCC`

## الملفات

| المتجر | الملف |
|---|---|
| Google Play | `~/Documents/Claude/builds/gcc-tariff-1.0.0-1/gcc-tariff-1.0.0-1.aab` (موقّع بمفتاح الرفع نفسه للتطبيق السوري، SHA-1 BF:A3…5A:6D) |
| Huawei AppGallery | `~/Documents/Claude/builds/gcc-tariff-1.0.0-1/gcc-tariff-1.0.0-1-huawei.apk` |
| App Store | `~/Documents/Claude/builds/gcc-tariff-1.0.0-1/Runner.xcarchive` (يُرفع من Xcode › Organizer › Distribute بعد إنشاء التطبيق في App Store Connect) |
| الأيقونة | `store/icons/icon-1024.png` (و512 لجوجل وهواوي) |
| لقطات الشاشة (آيفون 6.9″ 1206×2622) | `store/screenshots/gcc-iphone/` |
| صورة المعاينة | `og-image.jpg` على صفحة التحميل |

## إجابات النماذج

**Google Play · Data safety / App Store · App Privacy:**
- يجمع (اختياري، عند إنشاء حساب فقط): الاسم، البريد، رقم الجوال، لإدارة الحساب والنشرة. غير مشارَك مع طرف ثالث. مشفّر أثناء النقل. يمكن حذفه.
- رمز الإشعارات (Firebase) فقط إن وافق المستخدم.
- لا تتبّع، لا إعلانات مخصّصة، لا موقع، لا جهات اتصال.
- أسئلة ميرا تُرسل إلى خادم ميدترانس للإجابة عنها.

**Ads:** لا إعلانات في هذه النسخة.
**Government app?:** لا. تطبيق غير رسمي، والوصف يقول ذلك صراحة؛ لا يستخدم شعار مجلس التعاون أو أي جهة حكومية (الأيقونة أعلام الدول الست).
**Target audience:** 18+ (مستوردون وتجار ومخلّصون).

## ملاحظات لمراجع Apple (App Review notes)

> The app is an unofficial reference to the GCC unified customs tariff by MIDTRANS, a freight forwarder. It is not affiliated with any government; this is stated in the app (About) and in the description. The tariff data is the public reference file published on mid-trans.com and works offline. Sign-in is optional: the reviewer can use search, item pages, the USD duty calculator, the Customs links tab and MIRA without an account, or create an email account from the account icon (top left) and delete it from Account › Delete account.

## App Store Connect (2026-11-08)

أُنشئ التطبيق (Apple ID 6832080600، SKU gcctariff، لغة عربية) ورُفع البناء 1.0.0 (1) ورُبط بالإصدار 1.0.
عُبّئ: النص الترويجي، الوصف، الكلمات (`تعريفة,جمرك,بند جمركي,HS,استيراد,تخليص,شحن,السعودية,الإمارات,الكويت,قطر,البحرين,عمان,GCC,customs`)، العنوان الفرعي «رسوم الجمارك لدول الخليج الست»، الفئة Business + Reference، روابط الدعم والتسويق، حقوق النشر، بيانات التواصل، ملاحظات المراجع، إصدار يدوي، 10 لقطات آيفون وفيديو معاينة 27 ثانية (`store/video/gcc-preview.mp4`، يُعاد تسجيله بـ `--dart-define=SHOT=demo`).

## ما بقي عليك

1. **App Store Connect:** حساب تجريبي للمراجع (Sign-in required)، Content Rights، Age Rating، App Privacy، Pricing (مجاني)، ثم Add for Review.
2. **Google Play Console:** إنشاء تطبيق جديد، رفع الـAAB، ثم إضافة بصمة SHA-1 لمفتاح توقيع Play إلى Firebase (لتسجيل الدخول بجوجل).
3. **Huawei AppGallery:** إنشاء تطبيق جديد ورفع الـAPK.
4. **فيسبوك (اختياري):** إضافة `com.midtrans.gcctariff` إلى تطبيق Meta، ثم أشغّل زر فيسبوك.
5. بعد صدور روابط المتاجر: أضعها في صفحة التحميل وأزيل «قريباً».
