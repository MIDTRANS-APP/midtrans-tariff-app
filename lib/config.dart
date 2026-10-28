/// Addresses the app reads. Nothing here is a copy of the tariff: the website's
/// published file is the single source of truth (owner ruling 2026-09-15), and the
/// app only bundles a snapshot of it so it works offline from the first launch.
class AppConfig {
  /// The Syrian tariff as mid-trans.com publishes it (same file MIRA reads).
  static const tariffUrl =
      'https://www.mid-trans.com/reference/syrian-hs-code-tariff/syrian-hs-code-tariff.json';

  /// Public pages of the Syrian tariff on mid-trans.com.
  static const tariffPageAr = 'https://www.mid-trans.com/ar/customs-tariff/syria/';
  static const tariffPageEn = 'https://www.mid-trans.com/customs-tariff/syria/';

  /// MIRA's existing standalone chat page. Its origin is already allowed by MIRA,
  /// so the app opens it as is (owner 2026-10-22: no change to MIRA or the website).
  static const miraUrl = 'https://chat.midtrans.org/';

  /// MIRA's brain, called by the app's own chat screen (owner 2026-10-28: MIRA in the
  /// app's design). Requests carry [miraOrigin], the origin MIRA's server already allows.
  static const miraApi = 'https://api.midtrans.org/api/v1/chat/ask';
  static const miraOrigin = 'https://chat.midtrans.org';

  /// MIDTRANS's public sea-freight prices, the same list MIRA quotes from (owner 2026-10-28).
  static const ratesApi = 'https://api.midtrans.org/api/v1/public/rates';

  /// The unified GCC tariff on mid-trans.com: given when someone asks about it explicitly;
  /// the app itself is for the Syrian tariff only (owner 2026-10-28).
  static const gccTariffAr = 'https://www.mid-trans.com/ar/gcc-customs-tariff/';
  static const gccTariffEn = 'https://www.mid-trans.com/gcc-customs-tariff/';

  /// MIDTRANS team on WhatsApp (the number MIRA's page uses), offered when MIRA hands over.
  static const whatsappUrl = 'https://wa.me/963930204408';

  /// Facebook sign-in shows once its Meta app (created from the owner's Meta account) is
  /// set in Firebase › Authentication › Facebook. Google and Apple need nothing here.
  static const facebookSignIn = true; // Meta app 1089754473832330 "Syrian Customs Tariff"

  /// The authority the figures come from (linked, never imitated).
  static const authorityUrl = 'https://website.syrianborders.gov.sy/';

  static const privacyUrl = 'https://www.mid-trans.com/privacy-policy/';

  /// Snapshot bundled in the app, refreshed from [tariffUrl] when online.
  static const bundledTariffAsset = 'assets/data/syria-tariff.json.gz';

  /// How often the app checks the website for a newer file.
  static const refreshEvery = Duration(hours: 12);
}
