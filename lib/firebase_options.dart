import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase project of the app, for push notifications only (owner 2026-10-24:
/// «الإشعارات لتطبيق التعرفة الجمركية السورية، عبر Firebase، مع موافقة المستخدم»).
///
/// Firebase project midtrans-syrian-tariff (created 2026-10-24), shared with the Syrian app;
/// the GCC apps (com.midtrans.gcctariff) were added on 2026-11-07. Keys: Google Cloud ›
/// Credentials, "Android key" / "iOS key (auto created by Firebase)". These are
/// public app identifiers, not secrets: they ship inside every app build. With an
/// empty value [firebaseOptions] is null and the app shows no notification option.
const _android = FirebaseOptions(
  apiKey: 'AIzaSyADsbMa8TIZ5Zsl0U5u7q1rQrMiotAexzo',
  appId: '1:681262761995:android:5e915e1e54c32fc78f9f0e',
  messagingSenderId: '681262761995',
  projectId: 'midtrans-syrian-tariff',
);

const _ios = FirebaseOptions(
  apiKey: 'AIzaSyD9xRKcx7UJZjOl-k3lTAxUdw5ckiZx9iA',
  appId: '1:681262761995:ios:35ed2b82946b8e788f9f0e',
  messagingSenderId: '681262761995',
  projectId: 'midtrans-syrian-tariff',
  iosBundleId: 'com.midtrans.gcctariff',
);

FirebaseOptions? get firebaseOptions {
  final o = switch (defaultTargetPlatform) {
    TargetPlatform.android => _android,
    TargetPlatform.iOS => _ios,
    _ => null,
  };
  return (o == null || o.appId.isEmpty || o.apiKey.isEmpty) ? null : o;
}

Future<bool>? _started;

/// Starts Firebase once for push and accounts. False when this build has no Firebase
/// app or it could not start (the app then works without notifications and sign-in).
Future<bool> ensureFirebase() => _started ??= () async {
      final options = firebaseOptions;
      if (options == null) return false;
      try {
        await Firebase.initializeApp(options: options);
        return true;
      } catch (e) {
        debugPrint('Firebase not started: $e');
        return false;
      }
    }();
