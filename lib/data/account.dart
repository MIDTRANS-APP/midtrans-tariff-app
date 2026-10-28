import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../config.dart';
import '../firebase_options.dart';

enum SignInWay { google, apple, facebook }

/// What the person keeps in their account (Firestore users/{uid}). Only they can read
/// or write it (Firestore rules), and deleting the account deletes it.
class Profile {
  const Profile({this.name = '', this.email = '', this.phone = '', this.newsletter = false});
  final String name;
  final String email;
  final String phone;

  /// The tariff newsletter: tariff changes and new codes, for signed-in people only
  /// (owner 2026-10-28).
  final bool newsletter;

  Profile copyWith({String? name, String? email, String? phone, bool? newsletter}) => Profile(
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        newsletter: newsletter ?? this.newsletter,
      );

  static Profile fromMap(Map<String, dynamic>? m) => Profile(
        name: '${m?['name'] ?? ''}',
        email: '${m?['email'] ?? ''}',
        phone: '${m?['phone'] ?? ''}',
        newsletter: m?['newsletter'] == true,
      );
}

/// Sign-in with Google, Apple (iPhone) and Facebook through the app's own Firebase
/// project, as the Quran app does (owner 2026-10-28). Firebase Auth runs each provider
/// itself (Apple's native sheet; Google and Facebook in a secure in-app browser), so the
/// app carries no Google or Facebook SDK. The app works the same without an account;
/// the account adds the profile and the tariff newsletter.
class Account extends ChangeNotifier {
  bool available = false;
  User? user;
  Profile profile = const Profile();
  String _lang = 'ar';

  bool get signedIn => user != null;

  /// Apple on iPhone (Apple's rule when other sign-in is offered); Google always;
  /// Facebook once its Meta app is set up in Firebase ([AppConfig.facebookSignIn]).
  static List<SignInWay> get ways => [
        if (!kIsWeb && Platform.isIOS) SignInWay.apple,
        SignInWay.google,
        if (AppConfig.facebookSignIn) SignInWay.facebook,
      ];

  FirebaseAuth get _auth => FirebaseAuth.instance;
  DocumentReference<Map<String, dynamic>> get _doc => FirebaseFirestore.instance.collection('users').doc(user!.uid);
  String _topic(String lang) => 'newsletter_$lang';

  Future<void> start(String lang) async {
    _lang = lang;
    if (!await ensureFirebase()) return;
    available = true;
    _auth.authStateChanges().listen((u) async {
      user = u;
      profile = const Profile();
      if (u != null) await _loadProfile();
      notifyListeners();
    });
  }

  Future<void> _loadProfile() async {
    final fallback = Profile(name: user!.displayName ?? '', email: user!.email ?? '');
    try {
      final snap = await _doc.get();
      profile = snap.exists ? Profile.fromMap(snap.data()) : fallback;
      if (!snap.exists) await _save();
    } catch (e) {
      debugPrint('account: profile not loaded: $e');
      profile = fallback;
    }
  }

  Future<void> _save() => _doc.set({
        'name': profile.name,
        'email': profile.email,
        'phone': profile.phone,
        'newsletter': profile.newsletter,
        'newsletter_lang': _lang,
        'updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  // ---- sign-in ------------------------------------------------------------

  /// Returns false when the person closed the sign-in sheet; throws on other failures.
  Future<bool> signIn(SignInWay way) async {
    final provider = switch (way) {
      SignInWay.google => GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'}),
      SignInWay.apple => AppleAuthProvider()
        ..addScope('email')
        ..addScope('name'),
      SignInWay.facebook => FacebookAuthProvider()..addScope('email'),
    };
    try {
      await _auth.signInWithProvider(provider);
      return true;
    } on FirebaseAuthException catch (e) {
      if (const {'canceled', 'web-context-canceled', 'user-cancelled', 'cancelled'}.contains(e.code)) return false;
      rethrow;
    }
  }

  /// Sign-in ways linked to this account (google.com, apple.com, facebook.com).
  List<String> get linked => [for (final p in user?.providerData ?? const <UserInfo>[]) p.providerId];

  // ---- profile and settings -----------------------------------------------

  Future<void> updateProfile(Profile p) async {
    profile = p;
    notifyListeners();
    await _save();
  }

  /// Turns the tariff newsletter on or off. On asks for notification permission and
  /// joins the newsletter topic in the app's language. Returns the resulting state.
  Future<bool> setNewsletter(bool on) async {
    if (!signedIn) return false;
    final m = FirebaseMessaging.instance;
    if (on) {
      final settings = await m.requestPermission();
      on = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    }
    try {
      if (on) {
        await m.subscribeToTopic(_topic(_lang));
      } else {
        await m.unsubscribeFromTopic(_topic('ar'));
        await m.unsubscribeFromTopic(_topic('en'));
      }
    } catch (e) {
      debugPrint('account: newsletter topic: $e');
    }
    await updateProfile(profile.copyWith(newsletter: on));
    return on;
  }

  /// The app's language changed: the newsletter follows it.
  Future<void> setLang(String lang) async {
    if (lang == _lang) return;
    final old = _lang;
    _lang = lang;
    if (!signedIn || !profile.newsletter) return;
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(_topic(old));
      await FirebaseMessaging.instance.subscribeToTopic(_topic(lang));
      await _save();
    } catch (e) {
      debugPrint('account: newsletter language: $e');
    }
  }

  Future<void> signOut() async {
    if (profile.newsletter) {
      try {
        await FirebaseMessaging.instance.unsubscribeFromTopic(_topic(_lang));
      } catch (_) {}
    }
    await _auth.signOut();
  }

  /// Deletes the profile and the account (Apple and Google store rules). Firebase may ask
  /// for a fresh sign-in first: that throws `requires-recent-login`.
  Future<void> deleteAccount() async {
    if (!signedIn) return;
    await setNewsletter(false);
    await _doc.delete();
    await user!.delete();
  }
}
