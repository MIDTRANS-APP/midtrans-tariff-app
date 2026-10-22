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

  /// The authority the figures come from (linked, never imitated).
  static const authorityUrl = 'https://website.syrianborders.gov.sy/';

  static const privacyUrl = 'https://www.mid-trans.com/privacy-policy/';

  /// Snapshot bundled in the app, refreshed from [tariffUrl] when online.
  static const bundledTariffAsset = 'assets/data/syria-tariff.json.gz';

  /// How often the app checks the website for a newer file.
  static const refreshEvery = Duration(hours: 12);
}
