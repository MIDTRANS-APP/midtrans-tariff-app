import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase project of the app, for push notifications only (owner 2026-10-24:
/// «الإشعارات لتطبيق التعرفة الجمركية السورية، عبر Firebase، مع موافقة المستخدم»).
///
/// The values come from the Firebase console (Project settings › Your apps) once the
/// project exists. Until they are filled in, [firebaseOptions] is null and the app
/// shows no notification option at all. These values are public app identifiers,
/// not secrets: they ship inside every app build.
const _android = FirebaseOptions(
  apiKey: '',
  appId: '',
  messagingSenderId: '',
  projectId: '',
);

const _ios = FirebaseOptions(
  apiKey: '',
  appId: '',
  messagingSenderId: '',
  projectId: '',
  iosBundleId: 'com.midtrans.syriantariff',
);

FirebaseOptions? get firebaseOptions {
  final o = switch (defaultTargetPlatform) {
    TargetPlatform.android => _android,
    TargetPlatform.iOS => _ios,
    _ => null,
  };
  return (o == null || o.appId.isEmpty) ? null : o;
}
