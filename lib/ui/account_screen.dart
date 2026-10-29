import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/account.dart';
import 'email_auth_screen.dart';
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
      if (!app.account.available)
        Text(s.signInSoon, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.warn))
      else ...[
        for (final w in ways)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Pressable(
              child: _WayButton(way: w, label: s.signInWith(w), busy: _busy == w, onPressed: _busy == null ? () => _go(w) : null),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            const Expanded(child: Divider(color: AppColors.line)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(s.orEmail, style: const TextStyle(fontSize: 12, color: AppColors.muted))),
            const Expanded(child: Divider(color: AppColors.line)),
          ]),
        ),
        const SizedBox(height: 6),
        Pressable(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.ground, minimumSize: const Size.fromHeight(52)),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmailAuthScreen(signUp: true))),
            icon: const Icon(Icons.person_add_alt_1),
            label: Text(s.createAccount, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 10),
        Pressable(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.goldText, side: const BorderSide(color: AppColors.gold), minimumSize: const Size.fromHeight(50)),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmailAuthScreen(signUp: false))),
            icon: const Icon(Icons.mail_outline),
            label: Text(s.signInEmail, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
      const SizedBox(height: 16),
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
    // Each button in its brand's own look: Apple white/black, Google white with the
    // four-colour G and a grey border (owner 2026-10-28), Facebook blue.
    final (bg, fg) = switch (way) {
      SignInWay.apple => (Colors.white, Colors.black),
      SignInWay.google => (Colors.white, const Color(0xFF1F1F1F)),
      SignInWay.facebook => (const Color(0xFF1877F2), Colors.white),
    };
    final Widget icon = busy
        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
        : switch (way) {
            SignInWay.apple => const Icon(Icons.apple, size: 26),
            SignInWay.google => const GoogleLogo(size: 22),
            SignInWay.facebook => const Icon(Icons.facebook, size: 26),
          };
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        minimumSize: const Size.fromHeight(52),
        side: way == SignInWay.google ? const BorderSide(color: Color(0xFF747775)) : null,
      ),
      onPressed: onPressed,
      icon: icon,
      label: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
    );
  }
}

/// Google's "G" in its four colours, drawn so the app needs no image file.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 22});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size, child: CustomPaint(painter: _GPainter()));
}

class _GPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.2;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, s - stroke, s - stroke);
    Paint p(int c) => Paint()
      ..color = Color(c)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    const d = 3.14159265 / 180;
    canvas.drawArc(rect, -40 * d, -60 * d, false, p(0xFFEA4335)); // red, top
    canvas.drawArc(rect, -100 * d, -95 * d, false, p(0xFFFBBC05)); // yellow, left top
    canvas.drawArc(rect, 165 * d, -95 * d, false, p(0xFF34A853)); // green, bottom
    canvas.drawArc(rect, 70 * d, -70 * d, false, p(0xFF4285F4)); // blue, right
    canvas.drawRect(Rect.fromLTWH(s * 0.5, s * 0.5 - stroke / 2, s * 0.5 - stroke / 2, stroke), Paint()..color = const Color(0xFF4285F4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// «طرق الدخول المرتبطة»: link Apple, Google or Facebook to the same account, or unlink one
/// while another remains (owner 2026-10-28).
class _LinkedWays extends StatefulWidget {
  const _LinkedWays();

  @override
  State<_LinkedWays> createState() => _LinkedWaysState();
}

class _LinkedWaysState extends State<_LinkedWays> {
  SignInWay? _busy;

  Future<void> _toggle(SignInWay w) async {
    final app = AppScope.of(context);
    final acc = app.account;
    final s = app.s;
    setState(() => _busy = w);
    try {
      if (acc.isLinked(w)) {
        await acc.unlink(w);
      } else if (await acc.link(w) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.linkedOk(s.signInName(w)))));
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.code == 'credential-already-in-use' || e.code == 'email-already-in-use' ? s.linkTaken : s.authError(e.code))));
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final acc = app.account;
    final s = app.s;
    return Column(children: [
      for (final w in Account.ways)
        ListTile(
          leading: switch (w) {
            SignInWay.apple => const Icon(Icons.apple, color: AppColors.text, size: 26),
            SignInWay.google => const GoogleLogo(size: 22),
            SignInWay.facebook => const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 26),
          },
          title: Text(s.signInName(w)),
          subtitle: Text(acc.isLinked(w) ? s.linkedState : s.notLinked, style: TextStyle(fontSize: 12, color: acc.isLinked(w) ? AppColors.goldText : AppColors.muted)),
          trailing: _busy == w
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : acc.isLinked(w)
                  ? (acc.linked.length > 1
                      ? TextButton(onPressed: _busy == null ? () => _toggle(w) : null, child: Text(s.unlink, style: const TextStyle(color: AppColors.muted)))
                      : const Icon(Icons.check_circle, color: AppColors.gold))
                  : OutlinedButton(onPressed: _busy == null ? () => _toggle(w) : null, child: Text(s.link)),
        ),
    ]);
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

  final _form = GlobalKey<FormState>();

  Future<void> _save() async {
    final app = AppScope.of(context);
    if (!_form.currentState!.validate()) return;
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
      if (!acc.profileComplete)
        Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.warn)),
          child: Row(children: [
            const Icon(Icons.error_outline, color: AppColors.warn, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(s.completeProfile, style: const TextStyle(fontSize: 13, height: 1.5))),
          ]),
        ),
      GoldHeading(s.profile),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: _form,
          autovalidateMode: acc.profileComplete ? AutovalidateMode.disabled : AutovalidateMode.always,
          child: Column(children: [
          TextFormField(controller: _name, decoration: field(s.nameLabel, Icons.badge_outlined), validator: (v) => EmailAuthFields.name(s, v)),
          const SizedBox(height: 12),
          TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: field(s.emailLabel, Icons.alternate_email), validator: (v) => EmailAuthFields.email(s, v)),
          const SizedBox(height: 12),
          TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: field(s.phoneLabel, Icons.phone_outlined), validator: (v) => EmailAuthFields.phone(s, v)),
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
      ),
      GoldHeading(s.linkedWays),
      const _LinkedWays(),
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
