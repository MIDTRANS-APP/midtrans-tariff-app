/// Interface text in Arabic and English. Arabic is the default.
class S {
  const S(this.lang);
  final String lang;

  bool get en => lang == 'en';
  String _t(String ar, String en) => this.en ? en : ar;

  String get appName => _t('التعرفة الجمركية السورية', 'Syrian Customs Tariff');
  String get byMidtrans => _t('ميدترانس · MIDTRANS', 'MIDTRANS · ميدترانس');
  String get searchTitle => _t('البحث في التعرفة', 'Search the tariff');
  String get searchIntro => _t(
      'ابحث برقم البند أو باسم البضاعة بالعربية أو الإنكليزية. يعمل بدون إنترنت.',
      'Search by HS code or by goods name in Arabic or English. Works offline.');
  String get searchLabel => _t('رقم البند أو وصف البضاعة', 'HS code or goods description');
  String get searchHint => _t('مثال: 0901 أو قهوة', 'e.g. 0901 or coffee');
  String get browse => _t('تصفح الأقسام', 'Browse categories');
  String get recent => _t('عمليات البحث الأخيرة', 'Recent searches');
  String results(int n) => _t('$n نتيجة', '$n results');
  String get noResults => _t('لا نتائج. جرّب كلمة أخرى أو أول أرقام البند.', 'No results. Try another word or the first digits of the code.');
  String get tabSearch => _t('بحث', 'Search');
  String get tabFavorites => _t('المفضلة', 'Saved');
  String get tabMira => _t('اسأل ميرا', 'Ask MIRA');
  String get tabAbout => _t('عن التطبيق', 'About');
  String get itemTitle => _t('تفاصيل البند', 'Code details');
  String get figures => _t('الرسوم', 'Fees');
  String get notes => _t('ملاحظات', 'Notes');
  String get category => _t('الفئة', 'Category');
  String get reviewed => _t('آخر مراجعة', 'Last reviewed');
  String get source => _t('المصدر', 'Source');
  String get save => _t('حفظ في المفضلة', 'Save');
  String get unsave => _t('إزالة من المفضلة', 'Remove from saved');
  String get share => _t('مشاركة', 'Share');
  String get askMira => _t('اسأل ميرا عن هذا البند', 'Ask MIRA about this code');
  String get requestQuote => _t('اطلب عرض سعر شحن من ميدترانس', 'Request a shipping quote from MIDTRANS');
  String get noFavorites => _t('لم تحفظ أي بند بعد. اضغط النجمة في صفحة البند.', 'Nothing saved yet. Tap the star on a code page.');
  String get guidance => _t('للاسترشاد فقط. التصنيف والرسوم النهائية تؤكّدها الجمارك.', 'For guidance only. Final classification and fees are confirmed by customs.');
  String get unofficial => _t(
      'تطبيق غير رسمي من ميدترانس، وليس تابعاً لأي جهة حكومية. مصدر الأرقام: جداول الجمارك السورية المنشورة.',
      'An unofficial MIDTRANS app, not affiliated with any government body. Figures come from the published Syrian customs tables.');
  String get authority => _t('الهيئة العامة للمنافذ والجمارك', 'General Authority for Borders and Customs');
  String get dataVersion => _t('نسخة البيانات', 'Data version');
  String get checkUpdate => _t('التحقق من تحديث التعرفة', 'Check for tariff update');
  String get updated => _t('تم تحديث التعرفة من موقع ميدترانس.', 'Tariff updated from mid-trans.com.');
  String get upToDate => _t('لا تحديث جديد الآن.', 'No new update right now.');
  String get fromBundle => _t('نسخة مضمّنة في التطبيق', 'Copy bundled in the app');
  String get fromCache => _t('آخر نسخة من موقع ميدترانس', 'Latest copy from mid-trans.com');
  String get miraOffline => _t('ميرا تحتاج اتصالاً بالإنترنت. البحث في التعرفة يعمل بدونه.', 'MIRA needs an internet connection. Tariff search works without it.');
  String get retry => _t('إعادة المحاولة', 'Retry');
  String get language => _t('English', 'العربية');
  String get privacy => _t('سياسة الخصوصية', 'Privacy policy');
  String get webPage => _t('صفحة التعرفة على موقع ميدترانس', 'Tariff page on mid-trans.com');
  String get loading => _t('جارٍ تحميل التعرفة…', 'Loading the tariff…');
  String get ad => _t('إعلان', 'Ad');
  String get pushTitle => _t('إشعارات التحديثات والعروض', 'Updates and offers');
  String get pushAsk => _t(
      'هل تريد إشعاراً عند تحديث التعرفة، وعروض ميدترانس للشحن؟ يمكنك إيقافها في أي وقت من «عن التطبيق».',
      'Get a notification when the tariff is updated, and MIDTRANS shipping offers? You can turn it off any time in About.');
  String get pushYes => _t('نعم', 'Yes');
  String get pushNo => _t('لا شكراً', 'No thanks');
  String get pushSwitchHint => _t('تحديثات التعرفة وعروض ميدترانس', 'Tariff updates and MIDTRANS offers');
  String get pushDenied => _t('الإشعارات متوقفة في إعدادات الهاتف. فعّلها من الإعدادات ثم أعد المحاولة.',
      'Notifications are off in the phone settings. Turn them on there and try again.');
  String chapter(String c) => _t('الفصل $c', 'Chapter $c');
  String copied(String c) => _t('تم نسخ $c', '$c copied');
}
