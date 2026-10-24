import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';

/// Tariff updates and MIDTRANS offers by push notification, only for people who
/// said yes. Nothing is sent to MIDTRANS: the device joins a Firebase topic
/// (news_ar or news_en, by the app's language) and broadcasts are sent to that
/// topic from the Firebase console. Saying no, or switching it off in About,
/// leaves the topic.
class Push extends ChangeNotifier {
  static const _enabledKey = 'push_enabled';
  static const _askedKey = 'push_asked';

  /// False until Firebase is set up for this build (see firebase_options.dart).
  bool available = false;
  bool enabled = false;
  bool asked = false;
  String _lang = 'ar';

  /// Message received while the app is open (Android does not show those itself).
  void Function(String title, String body)? onForeground;

  String _topic(String lang) => 'news_$lang';

  Future<void> start(String lang) async {
    _lang = lang;
    final p = await SharedPreferences.getInstance();
    enabled = p.getBool(_enabledKey) ?? false;
    asked = p.getBool(_askedKey) ?? false;
    final options = firebaseOptions;
    if (options == null) return;
    try {
      await Firebase.initializeApp(options: options);
      available = true;
    } catch (e) {
      debugPrint('push: Firebase not started: $e');
      return;
    }
    FirebaseMessaging.onMessage.listen((m) {
      final n = m.notification;
      if (n != null) onForeground?.call(n.title ?? '', n.body ?? '');
    });
    notifyListeners();
    // keep the topic in line with the stored choice (cheap, idempotent)
    if (enabled) await _subscribe();
  }

  /// The person's answer, from the home card or the switch in About.
  Future<void> setEnabled(bool on) async {
    final p = await SharedPreferences.getInstance();
    asked = true;
    await p.setBool(_askedKey, true);
    if (on && available) {
      final settings = await FirebaseMessaging.instance.requestPermission();
      on = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    }
    enabled = on;
    await p.setBool(_enabledKey, on);
    notifyListeners();
    if (!available) return;
    on ? await _subscribe() : await _unsubscribe();
  }

  /// The app's language changed: move to the topic in that language.
  Future<void> setLang(String lang) async {
    if (lang == _lang) return;
    final old = _lang;
    _lang = lang;
    if (!available || !enabled) return;
    await _safe(() => FirebaseMessaging.instance.unsubscribeFromTopic(_topic(old)));
    await _subscribe();
  }

  Future<void> _subscribe() => _safe(() => FirebaseMessaging.instance.subscribeToTopic(_topic(_lang)));

  Future<void> _unsubscribe() async {
    for (final l in const ['ar', 'en']) {
      await _safe(() => FirebaseMessaging.instance.unsubscribeFromTopic(_topic(l)));
    }
  }

  // Topic calls need the network; a failure is retried at the next start.
  Future<void> _safe(Future<void> Function() call) async {
    try {
      await call();
    } catch (e) {
      debugPrint('push: $e');
    }
  }
}
