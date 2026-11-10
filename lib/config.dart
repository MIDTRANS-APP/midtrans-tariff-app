/// Addresses the app reads. Nothing here is a copy of the tariff: the website's
/// published file is the single source of truth (owner ruling 2026-09-15), and the
/// app only bundles a snapshot of it so it works offline from the first launch.
class AppConfig {
  /// The thank-you email to a new account, sent by the MIDTRANS platform (V2).
  static const welcomeApi = 'https://app.midtrans.net/api/v2/public/tariff-app/welcome';

  /// The unified GCC customs tariff as mid-trans.com publishes it (same file MIRA reads).
  static const tariffUrl =
      'https://www.mid-trans.com/reference/gcc-customs-tariff/gcc-customs-tariff.json';

  /// Public pages of the GCC tariff on mid-trans.com (one page per code under these).
  static const tariffPageAr = 'https://www.mid-trans.com/ar/gcc-customs-tariff/';
  static const tariffPageEn = 'https://www.mid-trans.com/gcc-customs-tariff/';

  /// MIRA's existing standalone chat page. Its origin is already allowed by MIRA,
  /// so the app opens it as is (owner 2026-10-22: no change to MIRA or the website).
  static const miraUrl = 'https://chat.midtrans.org/';

  /// MIRA's brain, called by the app's own chat screen (owner 2026-10-28: MIRA in the
  /// app's design). Requests carry [miraOrigin], the origin MIRA's server already allows.
  static const miraApi = 'https://api.midtrans.org/api/v1/chat/ask';
  static const miraOrigin = 'https://chat.midtrans.org';

  /// Where the Desk sees this app's conversations come from: MIRA keeps one brain,
  /// one store and one set of visitor details for every app (owner 2026-11-10:
  /// «العقل و التخزين و تجميع المعلومات واحدة»); only the screen is the app's own.
  static const miraSourcePage = 'https://www.mid-trans.com/gcc-tariff-app/';

  /// MIDTRANS's public sea-freight prices, the same list MIRA quotes from (owner 2026-10-28).
  static const ratesApi = 'https://api.midtrans.org/api/v1/public/rates';

  /// The Syrian tariff on mid-trans.com and MIDTRANS's Syrian tariff app: given when
  /// someone asks about Syria (this app is for the GCC tariff, owner 2026-11-07).
  static const syriaTariffAr = 'https://www.mid-trans.com/ar/customs-tariff/syria/';
  static const syriaTariffEn = 'https://www.mid-trans.com/customs-tariff/syria/';
  static const syriaAppPage = 'https://www.mid-trans.com/tariff-app/';

  /// MIDTRANS team on WhatsApp (the number MIRA's page uses), offered when MIRA hands over.
  static const whatsappUrl = 'https://wa.me/963930204408';

  /// Facebook sign-in shows once its Meta app (created from the owner's Meta account) is
  /// set in Firebase › Authentication › Facebook. Google and Apple need nothing here.
  /// GCC app: off until the Meta app also lists com.midtrans.gcctariff (iOS bundle and
  /// Android package + key hashes); the Meta app is still the Syrian one.
  static const facebookSignIn = false;

  /// Sign in with Apple on Android and Huawei (owner 2026-10-29: «عالج الكل»). Needs the
  /// Apple provider's OAuth code flow (team, key ID, private key) filled in Firebase.
  /// GCC app: off until an Apple Services ID for com.midtrans.gcctariff exists.
  static const appleSignInAndroid = false; // Meta app 1089754473832330 "Syrian Customs Tariff" (the GCC app needs its own)

  /// The body behind the unified tariff (linked, never imitated): the GCC Secretariat.
  static const authorityUrl = 'https://www.gcc-sg.org/';

  static const privacyUrl = 'https://www.mid-trans.com/privacy-policy/';

  /// Snapshot bundled in the app, refreshed from [tariffUrl] when online.
  static const bundledTariffAsset = 'assets/data/gcc-tariff.json.gz';

  /// Chapter sections and worldwide 6-digit HS wording, used only to help search.
  static const hsContextAsset = 'assets/data/hs-context.json.gz';

  /// How often the app checks the website for a newer file.
  static const refreshEvery = Duration(hours: 12);

  /// A download with fewer lines than this is treated as damaged (the tariff has about 13,400).
  static const minTariffRows = 12000;
}
