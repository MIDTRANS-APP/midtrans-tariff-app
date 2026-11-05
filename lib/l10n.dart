import 'data/account.dart' show SignInWay;

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
  String get myAccount => _t('حسابي', 'My account');
  String get signInTitle => _t('سجّل دخولك', 'Sign in');
  String get signInWhy => _t(
      'سجّل لتحصل على نشرة البنود الجمركية: تحديثات التعرفة والبنود المعدّلة أولاً بأول، وتحفظ ملفك وإعداداتك. تُفعَّل النشرة عند التسجيل، ويمكنك إيقافها من الإعدادات.',
      'Sign in to get the tariff newsletter: tariff updates and amended codes as they come, with your profile and settings kept. The newsletter starts on when you sign up; you can turn it off in settings.');
  String get signInSoon => _t('تسجيل الدخول غير متاح في هذه النسخة بعد.', 'Sign-in is not available in this version yet.');
  String signInWith(SignInWay w) => switch (w) {
        SignInWay.apple => _t('المتابعة مع Apple', 'Continue with Apple'),
        SignInWay.google => _t('المتابعة مع Google', 'Continue with Google'),
        SignInWay.facebook => _t('المتابعة مع Facebook', 'Continue with Facebook'),
      };
  String get signInPrivacy => _t(
      'نحفظ اسمك وبريدك ورقم جوالك واشتراكك في النشرة فقط. يمكنك حذف حسابك في أي وقت.',
      'We keep only your name, email, mobile number and newsletter choice. You can delete your account any time.');
  String get signInFailed => _t('تعذّر تسجيل الدخول. حاول مرة أخرى.', 'Sign-in failed. Please try again.');
  String providerName(String id) => switch (id) {
        'google.com' => 'Google',
        'apple.com' => 'Apple',
        'facebook.com' => 'Facebook',
        _ => id,
      };
  String get profile => _t('الملف الشخصي', 'Profile');
  String get nameLabel => _t('الاسم', 'Name');
  String signInName(SignInWay w) => switch (w) {
        SignInWay.apple => 'Apple',
        SignInWay.google => 'Google',
        SignInWay.facebook => 'Facebook',
      };
  String get linkedWays => _t('طرق الدخول المرتبطة', 'Linked sign-in methods');
  String get linkedState => _t('مرتبط بحسابك', 'Linked to your account');
  String get notLinked => _t('غير مرتبط', 'Not linked');
  String get link => _t('ربط', 'Link');
  String get unlink => _t('إلغاء الربط', 'Unlink');
  String linkedOk(String w) => _t('تم ربط $w بحسابك.', '$w is now linked to your account.');
  String get linkTaken => _t('هذا الحساب مرتبط بحساب آخر في التطبيق.', 'That account is already used by another account in the app.');
  String get emailLabel => _t('البريد الإلكتروني', 'Email');
  String get phoneLabel => _t('رقم الجوال', 'Mobile number');
  String get passwordLabel => _t('كلمة المرور', 'Password');
  String get createAccount => _t('إنشاء حساب جديد', 'Create a new account');
  String get signInEmail => _t('الدخول بالبريد الإلكتروني', 'Sign in with email');
  String get orEmail => _t('أو بالبريد الإلكتروني', 'or with email');
  String get forgotPassword => _t('نسيت كلمة المرور؟', 'Forgot password?');
  String get allRequired => _t('كل الحقول مطلوبة.', 'All fields are required.');
  String get nameRequired => _t('اكتب اسمك الكامل.', 'Enter your full name.');
  String get emailInvalid => _t('اكتب بريداً إلكترونياً صحيحاً.', 'Enter a valid email.');
  String get phoneRequired => _t('اكتب رقم الجوال مع رمز الدولة.', 'Enter your mobile number with the country code.');
  String get passwordShort => _t('كلمة المرور 8 أحرف على الأقل.', 'The password needs at least 8 characters.');
  String get emailFirst => _t('اكتب بريدك أولاً لنرسل رابط إعادة التعيين.', 'Enter your email first to get the reset link.');
  String get resetSent => _t('أرسلنا رابط إعادة تعيين كلمة المرور إلى بريدك.', 'We sent a password reset link to your email.');
  String get verifySent => _t('أُنشئ حسابك. أرسلنا رسالة لتأكيد بريدك.', 'Your account is ready. We sent an email to confirm your address.');
  String get completeProfile => _t('أكمل ملفك: الاسم والبريد ورقم الجوال مطلوبة.', 'Complete your profile: name, email and mobile number are required.');
  String authError(String code) => switch (code) {
        'email-already-in-use' => _t('هذا البريد مسجّل. سجّل الدخول به أو استعد كلمة المرور.', 'This email is already registered. Sign in or reset the password.'),
        'invalid-email' => emailInvalid,
        'weak-password' => passwordShort,
        'wrong-password' || 'invalid-credential' || 'user-not-found' => _t('البريد أو كلمة المرور غير صحيحة.', 'Wrong email or password.'),
        'too-many-requests' => _t('محاولات كثيرة. انتظر قليلاً ثم حاول.', 'Too many attempts. Wait a moment and try again.'),
        'network-request-failed' => _t('لا يوجد اتصال بالإنترنت.', 'No internet connection.'),
        _ => signInFailed,
      };
  String get save2 => _t('حفظ', 'Save');
  String get saved => _t('تم الحفظ.', 'Saved.');
  String get settings => _t('الإعدادات', 'Settings');
  String get newsletterTitle => _t('نشرة البنود الجمركية', 'Tariff newsletter');
  String get newsletterHint => _t('إشعار عند تعديل رسوم البنود أو صدور مرسوم جديد.', 'A notification when code fees change or a new decree is issued.');
  String get signOut => _t('تسجيل الخروج', 'Sign out');
  String get deleteAccount => _t('حذف الحساب', 'Delete account');
  String get deleteAccountWarn => _t('سيُحذف حسابك وملفك واشتراكك في النشرة نهائياً.', 'Your account, profile and newsletter subscription will be deleted for good.');
  String get signInAgainToDelete => _t('لأمانك، سجّل الخروج ثم الدخول مجدداً، ثم احذف الحساب.', 'For your security, sign out and in again, then delete the account.');
  String get cancel => _t('إلغاء', 'Cancel');
  String get delete => _t('حذف', 'Delete');
  String get ratesAskTitle => _t('أسعار شحن استرشادية', 'Guide freight prices');
  String get ratesAsk => _t(
      'هل تريد أن يظهر لك شريط بأسعار شحن الحاويات الاسترشادية من ميدترانس؟ يمكنك تغيير ذلك من الإعدادات.',
      'Would you like a strip of MIDTRANS guide container freight prices? You can change this in settings.');
  String get ratesYes => _t('نعم، أظهرها', 'Yes, show them');
  String get ratesSwitch => _t('شريط أسعار الشحن', 'Freight prices strip');
  String get ratesSwitchHint => _t('أسعار استرشادية لشحن الحاويات من ميدترانس', 'MIDTRANS guide container freight prices');
  String get ratesLabel => _t('أسعار الشحن', 'Freight');
  String rateQuestion(String container, String from, String to) => _t(
      'أريد عرض سعر شحن حاوية $container من $from إلى $to',
      'I would like a quote to ship a $container container from $from to $to');
  List<String> get miraCountries => en ? const ['Syria'] : const ['سوريا'];
  String gulfAnswer(String url) => _t(
      'هذا التطبيق مخصص للتعرفة الجمركية السورية. التعرفة الجمركية الخليجية الموحّدة موجودة على موقع ميدترانس: $url',
      'This app covers the Syrian customs tariff. The unified GCC customs tariff is on the MIDTRANS website: $url');
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
