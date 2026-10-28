import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/account.dart';
import 'motion.dart';
import 'theme.dart';
import 'widgets.dart';

/// «حسابي»: sign-in when signed out; profile, simple settings and the tariff newsletter
/// when signed in (owner 2026-10-28).
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ListenableBuilder(
      listenable: app.account,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(app.s.myAccount)),
        body: app.account.signedIn ? const _Profile() : const _SignIn(),
      ),
    );
  }
}

class _SignIn extends StatefulWidget {
  const _SignIn();

  @override
  State<_SignIn> createState() => _SignInState();
}

class _SignInState extends State<_SignIn> {
  SignInWay? _busy;

  Future<void> _go(SignInWay way) async {
    final app = AppScope.of(context);
    setState(() => _busy = way);
    try {
      await app.account.signIn(way);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(app.s.signInFailed)));
      debugPrint('sign-in: $e');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.s;
    final ways = Account.ways;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 28, 20, 24), children: [
      const Icon(Icons.account_circle_outlined, color: AppColors.gold, size: 64),
      const SizedBox(height: 14),
      Text(s.signInTitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text(s.signInWhy, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, height: 1.7, color: AppColors.muted)),
      const SizedBox(height: 24),
      if (!app.account.available || ways.isEmpty)
        Text(s.signInSoon, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.warn))
      else
        for (final w in ways)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Pressable(
              child: _WayButton(way: w, label: s.signInWith(w), busy: _busy == w, onPressed: _busy == null ? () => _go(w) : null),
            ),
          ),
      const SizedBox(height: 8),
      Text(s.signInPrivacy, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, height: 1.6, color: AppColors.muted)),
    ]);
  }
}

class _WayButton extends StatelessWidget {
  const _WayButton({required this.way, required this.label, required this.busy, required this.onPressed});
  final SignInWay way;
  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // Apple's button is black or white by its rules; the others follow the app.
    final (bg, fg, icon) = switch (way) {
      SignInWay.apple => (Colors.white, Colors.black, Icons.apple),
      SignInWay.google => (AppColors.surface, AppColors.text, Icons.g_mobiledata),
      SignInWay.facebook => (const Color(0xFF1877F2), Colors.white, Icons.facebook),
    };
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        minimumSize: const Size.fromHeight(52),
        side: way == SignInWay.google ? const BorderSide(color: AppColors.line) : null,
      ),
      onPressed: onPressed,
      icon: busy ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: fg)) : Icon(icon, size: 26),
      label: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
    );
  }
}

class _Profile extends StatefulWidget {
  const _Profile();

  @override
  State<_Profile> createState() => _ProfileState();
}

class _ProfileState extends State<_Profile> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final Account _account;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // read once without subscribing: initState may not depend on inherited widgets
    _account = context.getInheritedWidgetOfExactType<AppScope>()!.notifier!.account;
    final p = _account.profile;
    _name = TextEditingController(text: p.name);
    _email = TextEditingController(text: p.email);
    _phone = TextEditingController(text: p.phone);
    _account.addListener(_fill);
  }

  /// The profile may arrive or change after the screen opens: fill empty fields and redraw
  /// (the switches read the profile, and this page is built once by its parent).
  void _fill() {
    final p = _account.profile;
    if (_name.text.isEmpty && p.name.isNotEmpty) _name.text = p.name;
    if (_email.text.isEmpty && p.email.isNotEmpty) _email.text = p.email;
    if (_phone.text.isEmpty && p.phone.isNotEmpty) _phone.text = p.phone;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _account.removeListener(_fill);
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final app = AppScope.of(context);
    setState(() => _saving = true);
    await app.account.updateProfile(app.account.profile.copyWith(name: _name.text.trim(), email: _email.text.trim(), phone: _phone.text.trim()));
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(app.s.saved)));
  }

  Future<void> _delete() async {
    final app = AppScope.of(context);
    final s = app.s;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(s.deleteAccount),
        content: Text(s.deleteAccountWarn),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(s.cancel)),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(s.delete, style: const TextStyle(color: AppColors.warn))),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await app.account.deleteAccount();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.code == 'requires-recent-login' ? s.signInAgainToDelete : s.signInFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.s;
    final acc = app.account;
    final photo = acc.user?.photoURL;
    InputDecoration field(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AppColors.gold));
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Row(children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.surface,
            backgroundImage: photo != null ? NetworkImage(photo) : null,
            child: photo == null ? const Icon(Icons.person, color: AppColors.gold, size: 30) : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(acc.profile.name.isEmpty ? s.myAccount : acc.profile.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              if (acc.profile.email.isNotEmpty)
                Text(acc.profile.email, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
              const SizedBox(height: 4),
              Wrap(spacing: 6, children: [
                for (final p in acc.linked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6)),
                    child: Text(s.providerName(p), style: const TextStyle(fontSize: 11, color: AppColors.goldText)),
                  ),
              ]),
            ]),
          ),
        ]),
      ),
      GoldHeading(s.profile),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(children: [
          TextField(controller: _name, decoration: field(s.nameLabel, Icons.badge_outlined)),
          const SizedBox(height: 12),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: field(s.emailLabel, Icons.alternate_email)),
          const SizedBox(height: 12),
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: field(s.phoneLabel, Icons.phone_outlined)),
          const SizedBox(height: 12),
          Pressable(
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.ground, minimumSize: const Size.fromHeight(46)),
              onPressed: _saving ? null : _save,
              child: Text(s.save2),
            ),
          ),
        ]),
      ),
      GoldHeading(s.settings),
      SwitchListTile(
        title: Text(s.newsletterTitle),
        subtitle: Text(s.newsletterHint, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        value: acc.profile.newsletter,
        onChanged: (on) async {
          final now = await acc.setNewsletter(on);
          if (on && !now && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.pushDenied)));
          }
        },
      ),
      ListenableBuilder(
        listenable: app.push,
        builder: (context, _) => !app.push.available
            ? const SizedBox.shrink()
            : SwitchListTile(
                title: Text(s.pushTitle),
                subtitle: Text(s.pushSwitchHint, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                value: app.push.enabled,
                onChanged: (on) => app.push.setEnabled(on),
              ),
      ),
      SwitchListTile(
        title: Text(s.ratesSwitch),
        subtitle: Text(s.ratesSwitchHint, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        value: app.showRates,
        onChanged: app.setShowRates,
      ),
      ListTile(title: Text(s.language), trailing: const Icon(Icons.translate), onTap: app.toggleLang),
      const Divider(color: AppColors.line),
      ListTile(leading: const Icon(Icons.logout, color: AppColors.gold), title: Text(s.signOut), onTap: acc.signOut),
      ListTile(leading: const Icon(Icons.delete_outline, color: AppColors.warn), title: Text(s.deleteAccount, style: const TextStyle(color: AppColors.warn)), onTap: _delete),
    ]);
  }
}
