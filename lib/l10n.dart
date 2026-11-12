import 'data/account.dart' show SignInWay;

/// Interface text in Arabic and English. Arabic is the default.
class S {
  const S(this.lang);
  final String lang;

  bool get en => lang == 'en';
  String _t(String ar, String en) => this.en ? en : ar;

  String get appName => _t('التعرفة الجمركية الخليجية', 'GCC Customs Tariff');
  String get byMidtrans => _t('ميدترانس · MIDTRANS', 'MIDTRANS · ميدترانس');
  String get searchTitle => _t('البحث في التعرفة', 'Search the tariff');
  String get searchIntro => _t(
      'ابحث برقم البند أو باسم البضاعة بالعربية أو الإنكليزية. يعمل بدون إنترنت.',
      'Search by HS code or by goods name in Arabic or English. Works offline.');
  String get searchLabel => _t('رقم البند أو وصف البضاعة', 'HS code or goods description');
  String get searchHint => _t('مثال: 0901 أو قهوة أو سيارات', 'e.g. 0901, coffee or cars');
  String get browse => _t('تصفح الأقسام', 'Browse categories');
  String get recent => _t('عمليات البحث الأخيرة', 'Recent searches');
  String results(int n) => _t('$n نتيجة', '$n results');
  String get noResults => _t('لا نتائج. جرّب كلمة أخرى أو أول أرقام البند.', 'No results. Try another word or the first digits of the code.');
  String get tabSearch => _t('بحث', 'Search');
  String get tabFavorites => _t('المفضلة', 'Saved');
  String get tabMira => _t('اسأل ميرا', 'Ask MIRA');
  String get tabCustoms => _t('الجمارك', 'Customs');
  String get customsIntro => _t(
      'المواقع الرسمية لجمارك دول الخليج الست. تفتح في المتصفح؛ ميدترانس غير تابعة لأي منها.',
      'Official customs websites of the six GCC states. They open in your browser; MIDTRANS is not affiliated with any of them.');
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
      'تطبيق غير رسمي من ميدترانس، وليس تابعاً لأي جهة حكومية. مصدر الأرقام: التعرفة الجمركية الموحّدة لدول مجلس التعاون الخليجي (نسخة مرجعية).',
      'An unofficial MIDTRANS app, not affiliated with any government body. Figures come from the GCC unified customs tariff (reference copy).');
  String get authority => _t('الأمانة العامة لمجلس التعاون الخليجي', 'GCC Secretariat General');
  String get dataVersion => _t('نسخة البيانات', 'Data version');
  String get checkUpdate => _t('التحقق من تحديث التعرفة', 'Check for tariff update');
  String get updated => _t('تم تحديث التعرفة من موقع ميدترانس.', 'Tariff updated from mid-trans.com.');
  String get upToDate => _t('لا تحديث جديد الآن.', 'No new update right now.');
  String get fromBundle => _t('نسخة مضمّنة في التطبيق', 'Copy bundled in the app');
  String get fromCache => _t('آخر نسخة من موقع ميدترانس', 'Latest copy from mid-trans.com');
  String get miraOffline => _t('ميرا تحتاج اتصالاً بالإنترنت. البحث في التعرفة يعمل بدونه.', 'MIRA needs an internet connection. Tariff search works without it.');
  String get miraSubtitle => _t('مساعدة ميدترانس · ذكاء اصطناعي', 'MIDTRANS assistant · AI');
  String get miraHello => _t(
      'أهلاً، أنا ميرا من ميدترانس. اسألني عن أي بند في التعرفة الجمركية الخليجية، أو عن شحن بضاعتك إلى دول الخليج.',
      'Hi, I am MIRA from MIDTRANS. Ask me about any code in the GCC customs tariff, or about shipping your goods to the Gulf.');
  String get miraHint => _t('اكتب سؤالك…', 'Type your question…');
  String get miraThinking => _t('ميرا تكتب…', 'MIRA is typing…');
  String get miraNew => _t('محادثة جديدة', 'New chat');
  String get miraSignIn => _t('سجّل الدخول لإرسال طلبك إلى الفريق', 'Sign in to send your request to the team');
  String get miraTeam => _t('التحدث مع خبير جمركي', 'Talk to a customs expert');
  String get miraWhatsApp => _t('مراسلتنا على واتساب', 'Message us on WhatsApp');

  // The contact step and the request, in the words of MIRA's web chat (chat.midtrans.org):
  // one MIRA, one set of visitor details for every app (owner 2026-11-10).
  String get contactIntro => _t('قبل أن أرسل طلبك إلى خبير جمركي من ميدترانس، أحتاج بعض بياناتك:',
      'Before I send your request to a MIDTRANS customs expert, I need a few details:');

  // The news popup (owner 2026-11-10): the same details MIRA asks, for periodic customs news.
  String get newsTitle => _t('أخبار جمركية خليجية', 'GCC customs news');
  String get newsText => _t('سجّل بياناتك لتصلك أخبار التعرفة الجمركية الخليجية وتعديلاتها دورياً عبر واتساب أو البريد الإلكتروني. هي البيانات نفسها التي تطلبها ميرا، فتتحدث بعدها مع ميرا وخبير جمركي مباشرة. البحث في البنود يبقى متاحاً دون تسجيل.',
      'Register to receive GCC customs tariff news and changes periodically by WhatsApp or email. These are the same details MIRA asks for, so you can then talk to MIRA and a customs expert right away. Searching codes stays open without registering.');
  String get newsRegister => _t('سجّل بياناتي', 'Register my details');
  String get newsLater => _t('لاحقاً', 'Later');
  String get newsDone => _t('تم التسجيل. ستصلك أخبار التعرفة الجمركية الخليجية عبر واتساب أو البريد الإلكتروني.', 'Registered. The GCC customs tariff news will reach you by WhatsApp or email.');
  String get contactName => _t('الاسم', 'Name');
  String get contactCountry => _t('البلد', 'Country');
  String get contactPhone => _t('رقم الهاتف', 'Phone number');
  String get contactWhatsApp => _t('رقم واتساب', 'WhatsApp number');
  String get contactWhatsAppCountry => _t('بلد رقم الواتساب', 'WhatsApp country');
  String get contactSame => _t('رقم الواتساب هو نفسه رقم الهاتف', 'My WhatsApp is the same number');
  String get contactEmail => _t('البريد الإلكتروني', 'Email');
  String get contactSend => _t('متابعة', 'Continue');
  String get contactBadWhatsApp => _t('أدخل رقم واتساب صحيحاً.', 'Please enter a valid WhatsApp number.');
  String get contactNoEmail => _t('اكتب بريدك الإلكتروني.', 'Please type your email.');
  String get contactNoName => _t('اكتب اسمك لو سمحت.', 'Please type your name.');
  String get contactNoCountry => _t('اختر البلد أولاً.', 'Please select a country.');
  String get contactBadPhone => _t('أدخل رقم هاتف صحيح.', 'Please enter a valid phone number.');
  String get contactBadEmail => _t('البريد الإلكتروني غير صحيح.', 'That email does not look right.');
  String get contactSaved => _t('تُحفظ بياناتك على هاتفك فلا نسألك عنها مرة أخرى، وتصل إلى ميدترانس فقط.',
      'Your details stay on this phone so we do not ask again, and go to MIDTRANS only.');
  String get sending => _t('جارٍ الإرسال…', 'Sending…');

  /// The one closing message of a request (MIRA's closingText and promiseLine).
  String requestSent({String? number, required bool online, String? replyBy, required bool emailed}) {
    final parts = <String>[];
    if (number != null) parts.add(_t('رقم طلبك \u2068$number\u2069.', 'Your request number is $number.'));
    if (online || replyBy == 'online') {
      parts.add(_t('سيتواصل معك خبير جمركي من ميدترانس بأسرع وقت.', 'A MIDTRANS customs expert will contact you as soon as possible.'));
      parts.add(_t('يوجد خبير متصل الآن.', 'An expert is online now.'));
    } else {
      parts.add(_t('سيرد عليك خبير جمركي من ميدترانس بأقرب وقت.', 'A MIDTRANS customs expert will reply as soon as possible.'));
    }
    parts.add(number != null
        ? _t('يمكنك أيضاً مراسلتنا على واتساب بذكر هذا الرقم.', 'You can also message us on WhatsApp with this number.')
        : _t('يمكنك أيضاً مراسلتنا على واتساب.', 'You can also message us on WhatsApp.'));
    if (number != null && emailed) {
      parts.add(_t('وأرسلنا إلى بريدك رسالة فيها رقم طلبك؛ إن لم تصلك خلال دقائق فيُرجى التحقق من مجلد الرسائل غير المرغوب فيها.',
          "We've also emailed you your request number; if it isn't in your inbox within a few minutes, please check your spam folder."));
    }
    return parts.join(' ');
  }
  String get miraNote => _t('إجابات ميرا للاسترشاد، والرسوم النهائية تؤكدها الجمارك.', 'MIRA\'s answers are guidance; final fees are confirmed by customs.');
  List<String> get miraSuggestions => en
      ? const ['Customs duty on cars into Saudi Arabia?', 'Which goods are prohibited in the GCC tariff?', 'I want a quote to ship my goods to the Gulf']
      : const ['ما الرسم الجمركي على السيارات في السعودية؟', 'ما البضائع الممنوع استيرادها في التعرفة الخليجية؟', 'أريد عرض سعر لشحن بضاعتي إلى الخليج'];
  String codeNotFound(String code) => _t('البند $code غير موجود في التعرفة الخليجية', 'Code $code is not in the GCC tariff');
  String get trimDigits => _t(
      'احذف آخر خانتين أو أكثر من الرقم لترى البنود المتاحة تحته، ثم اختر البند الأقرب لبضاعتك.',
      'Delete the last two digits or more to see the codes available under it, then pick the one closest to your goods.');
  String tryCode(String code) => _t('جرّب $code', 'Try $code');
  String get hsWorldwide => _t(
      'تذكير: أول 6 أرقام من البند (النظام المنسّق HS) عالمية وموحّدة بين الدول، أما الخانات التفصيلية بعدها فتختلف من دولة إلى أخرى. لذلك قد لا يطابق رقمٌ من بلد آخر التعرفة الخليجية كاملاً.',
      'Reminder: the first 6 digits of a code (the Harmonized System, HS) are the same worldwide; the detailed digits after them differ from country to country, so a full code from another country may not match the GCC tariff.');
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
  String get newsletterHint => _t('إشعار عند تعديل رسوم البنود في التعرفة الخليجية.', 'A notification when duties in the GCC tariff change.');
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
  List<String> get miraCountries => en
      ? const ['Saudi Arabia', 'UAE', 'Kuwait', 'Qatar', 'Bahrain', 'Oman']
      : const ['السعودية', 'الإمارات', 'الكويت', 'قطر', 'البحرين', 'عُمان'];
  String get gccStates => _t('دول مجلس التعاون الخليجي الست', 'The six GCC states');
  String syriaAnswer(String app, String page) => _t(
      'هذا التطبيق مخصص للتعرفة الجمركية الخليجية الموحّدة. للتعرفة السورية حمّل تطبيق ميدترانس للتعرفة الجمركية السورية: $app\nأو افتح صفحتها: $page',
      'This app covers the unified GCC customs tariff. For the Syrian tariff, get the MIDTRANS Syrian Customs Tariff app: $app\nor open its page: $page');
  String askAboutCode(String code) => _t('ما الرسم الجمركي للبند $code في التعرفة الخليجية؟', 'What is the GCC customs duty for code $code?');
  String get calcTitle => _t('احسب الرسم بالدولار', 'Work out the duty in USD');
  String get calcLabel => _t('القيمة الجمركية (CIF) بالدولار', 'Customs value (CIF) in USD');
  String get calcHint => _t('مثال: 10000', 'e.g. 10000');
  // \u2066…\u2069 keeps «5%» left-to-right inside the Arabic sentence
  String calcResult(String duty, String pct) =>
      _t('الرسم الجمركي التقريبي: $duty دولار (\u2066$pct\u2069)', 'Approximate customs duty: $duty USD ($pct)');
  String get calcNote => _t(
      'تقدير للاسترشاد: لا يشمل ضريبة القيمة المضافة أو الضريبة الانتقائية أو رسوم الخدمات في دولة الوصول.',
      'An estimate for guidance: it leaves out VAT, excise tax and service charges in the destination state.');
  String heading(String h) => _t('البند $h', 'Heading $h');
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
