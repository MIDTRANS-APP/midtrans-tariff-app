import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase project of the app, for push notifications only (owner 2026-10-24:
/// «الإشعارات لتطبيق التعرفة الجمركية السورية، عبر Firebase، مع موافقة المستخدم»).
///
/// Firebase project midtrans-syrian-tariff (created 2026-10-24). Keys: Google Cloud ›
/// Credentials, "Android key" / "iOS key (auto created by Firebase)". These are
/// public app identifiers, not secrets: they ship inside every app build. With an
/// empty value [firebaseOptions] is null and the app shows no notification option.
const _android = FirebaseOptions(
  apiKey: 'AIzaSyADsbMa8TIZ5Zsl0U5u7q1rQrMiotAexzo',
  appId: '1:681262761995:android:9eac5155533c287e8f9f0e',
  messagingSenderId: '681262761995',
  projectId: 'midtrans-syrian-tariff',
);

const _ios = FirebaseOptions(
  apiKey: 'AIzaSyD9xRKcx7UJZjOl-k3lTAxUdw5ckiZx9iA',
  appId: '1:681262761995:ios:07d1a9929f0b94658f9f0e',
  messagingSenderId: '681262761995',
  projectId: 'midtrans-syrian-tariff',
  iosBundleId: 'com.midtrans.syriantariff',
);

FirebaseOptions? get firebaseOptions {
  final o = switch (defaultTargetPlatform) {
    TargetPlatform.android => _android,
    TargetPlatform.iOS => _ios,
    _ => null,
  };
  return (o == null || o.appId.isEmpty || o.apiKey.isEmpty) ? null : o;
}
