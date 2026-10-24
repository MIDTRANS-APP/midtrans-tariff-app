# الإشعارات الدعائية — التعرفة الجمركية السورية

التطبيق لا يرسل شيئاً لأحد من دون موافقته: يسأل المستخدم مرة واحدة في الصفحة الرئيسية («نعم» / «لا شكراً»)، ويمكنه تغيير رأيه من «عن التطبيق». من يوافق ينضم إلى موضوع (topic) بلغة التطبيق:

| الموضوع | من فيه |
|---|---|
| `news_ar` | من يستعمل التطبيق بالعربية |
| `news_en` | من يستعمل التطبيق بالإنكليزية |

إذا غيّر المستخدم اللغة ينتقل تلقائياً إلى موضوع اللغة الجديدة.

## التجهيز (مرة واحدة)

1. Firebase console › مشروع جديد (مثلاً `midtrans-tariff`) بحساب MIDTRANS.
2. أضف تطبيق Android بالحزمة `com.midtrans.syriantariff`، وتطبيق iOS بالمعرّف نفسه.
3. انسخ من Project settings › Your apps القيم الأربع لكل تطبيق (apiKey, appId, messagingSenderId, projectId) إلى `lib/firebase_options.dart`. هذه معرّفات عامة وليست أسراراً. قبل ملئها لا يظهر خيار الإشعارات في التطبيق.
4. Apple: في Certificates, Identifiers & Profiles › Keys أنشئ مفتاح APNs (أو استعمل مفتاح الفريق الموجود)، ثم ارفعه في Firebase › Project settings › Cloud Messaging › Apple app configuration. ملف `.p8` يُحمَّل مرة واحدة: يحفظه المالك.
5. App ID `com.midtrans.syriantariff`: فعّل Push Notifications.

## إرسال إشعار

Firebase console › Messaging › New campaign › Notifications:
- العنوان والنص (قصيران، بلغة الموضوع).
- Target › Topic › `news_ar` أو `news_en`.
- Scheduling: الآن أو بموعد.
- Review › Publish.

أرسل نسختين منفصلتين: عربية إلى `news_ar` وإنكليزية إلى `news_en`.

## متطلبات المتاجر

- Apple (4.5.4): الإشعارات الدعائية بموافقة صريحة داخل التطبيق وزر إيقاف — موجودان.
- Google Data safety: أضف «Device or other IDs» (رمز الإشعارات)، الغرض App functionality ورسائل المطوّر، اختياري.
- سياسة الخصوصية: البند 5 «الإشعارات» في `privacy-policy-draft.md`.
