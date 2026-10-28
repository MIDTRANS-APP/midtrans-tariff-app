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
  String get miraSubtitle => _t('مساعدة ميدترانس · ذكاء اصطناعي', 'MIDTRANS assistant · AI');
  String get miraHello => _t(
      'أهلاً، أنا ميرا من ميدترانس. اسألني عن أي بند في التعرفة السورية، أو عن شحن بضاعتك.',
      'Hi, I am MIRA from MIDTRANS. Ask me about any code in the Syrian tariff, or about shipping your goods.');
  String get miraHint => _t('اكتب سؤالك…', 'Type your question…');
  String get miraThinking => _t('ميرا تكتب…', 'MIRA is typing…');
  String get miraNew => _t('محادثة جديدة', 'New chat');
  String get miraTeam => _t('تحدّث مع فريق ميدترانس على واتساب', 'Talk to the MIDTRANS team on WhatsApp');
  String get miraNote => _t('إجابات ميرا للاسترشاد، والرسوم النهائية تؤكدها الجمارك.', 'MIRA\'s answers are guidance; final fees are confirmed by customs.');
  List<String> get miraSuggestions => en
      ? const ['Import fees for coffee into Syria?', 'Is code 8703 on Syria\'s negative list?', 'How do I ship a container to Syria?']
      : const ['ما رسوم استيراد القهوة إلى سوريا؟', 'هل البند 8703 في القائمة السلبية السورية؟', 'كيف أشحن حاوية إلى سوريا؟'];
  String codeNotFound(String code) => _t('البند $code غير موجود في التعرفة السورية', 'Code $code is not in the Syrian tariff');
  String get trimDigits => _t(
      'احذف آخر خانتين أو أكثر من الرقم لترى البنود المتاحة تحته، ثم اختر البند الأقرب لبضاعتك.',
      'Delete the last two digits or more to see the codes available under it, then pick the one closest to your goods.');
  String tryCode(String code) => _t('جرّب $code', 'Try $code');
  String get hsWorldwide => _t(
      'تذكير: أول 6 أرقام من البند (النظام المنسّق HS) عالمية وموحّدة بين الدول، أما الخانات التفصيلية بعدها فتختلف من دولة إلى أخرى. لذلك قد لا يطابق رقمٌ من بلد آخر التعرفة السورية كاملاً.',
      'Reminder: the first 6 digits of a code (the Harmonized System, HS) are the same worldwide; the detailed digits after them differ from country to country, so a full code from another country may not match the Syrian tariff.');
  String get ratesLabel => _t('أسعار الشحن', 'Freight');
  String rateQuestion(String container, String from, String to) => _t(
      'أريد عرض سعر شحن حاوية $container من $from إلى $to',
      'I would like a quote to ship a $container container from $from to $to');
  List<String> get miraCountries => en
      ? const ['Syria', 'GCC tariff (Gulf countries)']
      : const ['سوريا', 'تعرفة دول الخليج'];
  String askAboutCode(String code) => _t('ما رسوم البند $code في سوريا؟', 'What are the fees for code $code in Syria?');
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
