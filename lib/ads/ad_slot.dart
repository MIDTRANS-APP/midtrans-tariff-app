import 'package:flutter/material.dart';

/// Where ads may appear. Placement is fixed by the plan: a small banner under
/// results and on the code page, never during typing, never inside MIRA.
enum AdPlacement { resultsBanner, itemBanner }

/// One ad network per store build: AdMob for Google Play and the App Store,
/// Petal Ads (Huawei Ads) for AppGallery. Until the MIDTRANS accounts exist the
/// app ships with [NoAds], which draws nothing.
abstract class AdProvider {
  const AdProvider();
  Widget banner(BuildContext context, AdPlacement placement);
}

class NoAds extends AdProvider {
  const NoAds();
  @override
  Widget banner(BuildContext context, AdPlacement placement) => const SizedBox.shrink();
}

class Ads {
  /// Set once in main() for the store build being made.
  static AdProvider provider = const NoAds();
}

class AdSlot extends StatelessWidget {
  const AdSlot(this.placement, {super.key});
  final AdPlacement placement;

  @override
  Widget build(BuildContext context) => Ads.provider.banner(context, placement);
}
