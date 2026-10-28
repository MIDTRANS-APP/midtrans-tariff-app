import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;

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
  bool _signingUp = false;

  bool get signedIn => user != null;

  /// Name, email and phone are all required (owner 2026-10-28); a Google or Apple account
  /// without a phone is asked to complete its profile.
  bool get profileComplete => profile.name.isNotEmpty && profile.email.isNotEmpty && profile.phone.isNotEmpty;

  // ---- email and password -------------------------------------------------

  /// A new account with every field required. Throws [FirebaseAuthException]
  /// (email-already-in-use, weak-password, invalid-email…). Sends a verification email.
  Future<void> signUpWithEmail({required String name, required String email, required String password, required String phone}) async {
    // the sign-in listener must not load (and save) an empty profile meanwhile
    _signingUp = true;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      final u = cred.user!;
      await u.updateDisplayName(name.trim());
      user = u;
      profile = Profile(name: name.trim(), email: email.trim(), phone: phone.trim());
      await _save();
    } finally {
      _signingUp = false;
    }
    final u = user!;
    try {
      await u.sendEmailVerification();
    } catch (e) {
      debugPrint('account: verification email: $e');
    }
    await setNewsletter(true);
    unawaited(_sendWelcome());
    notifyListeners();
  }

  /// The thank-you email, Arabic and English, signed by the owner (owner 2026-10-28).
  /// The platform checks the token with Google and writes only to a new account's own
  /// address, once. Never blocks or fails the sign-up.
  Future<void> _sendWelcome() async {
    try {
      final token = await user?.getIdToken();
      if (token == null) return;
      await http
          .post(Uri.parse(AppConfig.welcomeApi),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'id_token': token, 'name': profile.name}))
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('account: welcome email: $e');
    }
  }

  Future<void> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> resetPassword(String email) => _auth.sendPasswordResetEmail(email: email.trim());

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
      if (_signingUp) return;
      profile = const Profile();
      if (u != null) await _loadProfile();
      notifyListeners();
    });
  }

  /// The name the sign-in way gave (Firebase does not always copy it to the user).
  String get _providerName {
    final names = [user!.displayName, for (final p in user!.providerData) p.displayName];
    return names.firstWhere((n) => n != null && n.trim().isNotEmpty, orElse: () => '')!.trim();
  }

  /// True when the last [_loadProfile] created the profile (first sign-in).
  bool _created = false;

  Future<void> _loadProfile() async {
    final fallback = Profile(name: _providerName, email: user!.email ?? '');
    _created = false;
    try {
      final snap = await _doc.get();
      _created = !snap.exists;
      profile = snap.exists ? Profile.fromMap(snap.data()) : fallback;
      // fill an empty name or email from the sign-in way
      final filled = profile.copyWith(
        name: profile.name.isEmpty ? fallback.name : null,
        email: profile.email.isEmpty ? fallback.email : null,
      );
      final changed = filled.name != profile.name || filled.email != profile.email;
      profile = filled;
      if (!snap.exists || changed) await _save();
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
  static AuthProvider _provider(SignInWay way) => switch (way) {
        SignInWay.google => GoogleAuthProvider()
          ..addScope('profile')
          ..addScope('email')
          ..setCustomParameters({'prompt': 'select_account'}),
        SignInWay.apple => AppleAuthProvider()
          ..addScope('email')
          ..addScope('name'),
        SignInWay.facebook => FacebookAuthProvider()
          ..addScope('email')
          ..addScope('public_profile'),
      };

  static String providerId(SignInWay way) => switch (way) {
        SignInWay.google => 'google.com',
        SignInWay.apple => 'apple.com',
        SignInWay.facebook => 'facebook.com',
      };

  /// Facebook's terms require its own SDK: Firebase refuses Facebook through the generic
  /// provider (it crashes the app on iPhone). On iPhone the SDK gives a Limited Login
  /// token checked with a nonce; on Android a classic access token. Null when closed.
  Future<AuthCredential?> _facebookCredential() async {
    final fb = FacebookAuth.instance;
    if (!kIsWeb && Platform.isIOS) {
      final r = Random.secure();
      final raw = base64Url.encode(List.generate(32, (_) => r.nextInt(256))).replaceAll('=', '');
      final res = await fb.login(
        permissions: const ['email', 'public_profile'],
        loginTracking: LoginTracking.limited,
        nonce: sha256.convert(utf8.encode(raw)).toString(),
      );
      if (res.status != LoginStatus.success || res.accessToken == null) return null;
      return OAuthProvider('facebook.com').credential(idToken: res.accessToken!.tokenString, rawNonce: raw);
    }
    final res = await fb.login(permissions: const ['email', 'public_profile']);
    if (res.status != LoginStatus.success || res.accessToken == null) return null;
    return FacebookAuthProvider.credential(res.accessToken!.tokenString);
  }

  Future<bool> signIn(SignInWay way) async {
    try {
      final UserCredential cred;
      if (way == SignInWay.facebook) {
        final c = await _facebookCredential();
        if (c == null) return false;
        cred = await _auth.signInWithCredential(c);
      } else {
        cred = await _auth.signInWithProvider(_provider(way));
      }
      // The provider's own details carry the name and email even when Firebase leaves
      // the user's displayName empty: copy them to the account and the profile.
      final info = cred.additionalUserInfo?.profile ?? const {};
      final name = [
        info['name'],
        [info['given_name'], info['family_name']].whereType<String>().join(' '),
        [info['first_name'], info['last_name']].whereType<String>().join(' '),
      ].whereType<String>().map((s) => s.trim()).firstWhere((s) => s.isNotEmpty, orElse: () => '');
      final email = '${info['email'] ?? cred.user?.email ?? ''}'.trim();
      final u = cred.user;
      if (u != null && name.isNotEmpty && (u.displayName ?? '').isEmpty) await u.updateDisplayName(name);
      if (u != null) {
        user = u;
        await _loadProfile();
        // Signing up is for the newsletter (owner 2026-10-28): a new account starts with it on.
        final isNew = _created || (cred.additionalUserInfo?.isNewUser ?? false);
        if (isNew && !profile.newsletter) await setNewsletter(true);
        if ((profile.name.isEmpty && name.isNotEmpty) || (profile.email.isEmpty && email.isNotEmpty)) {
          await updateProfile(profile.copyWith(
            name: profile.name.isEmpty ? name : null,
            email: profile.email.isEmpty ? email : null,
          ));
        }
        if (isNew) unawaited(_sendWelcome());
        notifyListeners();
      }
      return true;
    } on FirebaseAuthException catch (e) {
      if (const {'canceled', 'web-context-canceled', 'user-cancelled', 'cancelled'}.contains(e.code)) return false;
      rethrow;
    }
  }

  /// Sign-in ways linked to this account (google.com, apple.com, facebook.com).
  List<String> get linked => [for (final p in user?.providerData ?? const <UserInfo>[]) p.providerId];

  bool isLinked(SignInWay way) => linked.contains(providerId(way));

  /// Adds another sign-in way to this same account (owner 2026-10-28: link the other
  /// accounts from settings). False when the person closed the sheet. Throws
  /// `credential-already-in-use` when that Google/Apple/Facebook account belongs to
  /// another account here.
  Future<bool> link(SignInWay way) async {
    final u = user;
    if (u == null) return false;
    try {
      if (way == SignInWay.facebook) {
        final c = await _facebookCredential();
        if (c == null) return false;
        await u.linkWithCredential(c);
      } else {
        await u.linkWithProvider(_provider(way));
      }
      await u.reload();
      user = _auth.currentUser;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      if (const {'canceled', 'web-context-canceled', 'user-cancelled', 'cancelled'}.contains(e.code)) return false;
      rethrow;
    }
  }

  /// Removes a sign-in way; the last one is kept so the account can still be opened.
  Future<void> unlink(SignInWay way) async {
    final u = user;
    if (u == null || linked.length < 2) return;
    await u.unlink(providerId(way));
    await u.reload();
    user = _auth.currentUser;
    notifyListeners();
  }

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
      final settings = await m.requestPermission().timeout(const Duration(seconds: 30));
      on = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    }
    // The choice is saved first; joining the topic waits for the phone's push token,
    // which can take a while (and never comes on a simulator), so it runs on its own.
    await updateProfile(profile.copyWith(newsletter: on));
    unawaited(_topics(on));
    return on;
  }

  Future<void> _topics(bool on) async {
    final m = FirebaseMessaging.instance;
    try {
      if (on) {
        await m.subscribeToTopic(_topic(_lang)).timeout(const Duration(minutes: 2));
      } else {
        await m.unsubscribeFromTopic(_topic('ar')).timeout(const Duration(minutes: 2));
        await m.unsubscribeFromTopic(_topic('en')).timeout(const Duration(minutes: 2));
      }
    } catch (e) {
      debugPrint('account: newsletter topic: $e');
    }
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
    if (profile.newsletter) unawaited(_topics(false));
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
