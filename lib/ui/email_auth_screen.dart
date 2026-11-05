import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n.dart';
import 'motion.dart';
import 'theme.dart';

/// Checks for the required account fields, shared by sign-up and the profile page.
class EmailAuthFields {
  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static String? name(S s, String? v) => (v ?? '').trim().length < 2 ? s.nameRequired : null;
  static String? email(S s, String? v) => _emailRe.hasMatch((v ?? '').trim()) ? null : s.emailInvalid;
  static String? phone(S s, String? v) => RegExp(r'\d').allMatches(v ?? '').length < 8 ? s.phoneRequired : null;
}

/// New account (name, email, password, phone, all required — owner 2026-10-28) or sign-in
/// with email and password, with a "forgot password" link.
class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key, required this.signUp});
  final bool signUp;

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  bool _busy = false;
  bool _hide = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final app = AppScope.of(context);
    final s = app.s;
    setState(() => _busy = true);
    try {
      if (widget.signUp) {
        await app.account.signUpWithEmail(name: _name.text, email: _email.text, password: _password.text, phone: _phone.text);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.verifySent)));
      } else {
        await app.account.signInWithEmail(_email.text, _password.text);
      }
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.authError(e.code))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgot() async {
    final app = AppScope.of(context);
    final s = app.s;
    if (EmailAuthFields.email(s, _email.text) != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.emailFirst)));
      return;
    }
    try {
      await app.account.resetPassword(_email.text);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.resetSent)));
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.authError(e.code))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).s;
    final up = widget.signUp;
    InputDecoration field(String label, IconData icon, {Widget? suffix}) =>
        InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AppColors.gold), suffixIcon: suffix);
    return Scaffold(
      appBar: AppBar(title: Text(up ? s.createAccount : s.signInEmail)),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 24), children: [
          if (up) ...[
            TextFormField(
              controller: _name,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: field(s.nameLabel, Icons.badge_outlined),
              validator: (v) => EmailAuthFields.name(s, v),
            ),
            const SizedBox(height: 14),
          ],
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: field(s.emailLabel, Icons.alternate_email),
            validator: (v) => EmailAuthFields.email(s, v),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _password,
            obscureText: _hide,
            textInputAction: up ? TextInputAction.next : TextInputAction.done,
            autofillHints: [up ? AutofillHints.newPassword : AutofillHints.password],
            decoration: field(s.passwordLabel, Icons.lock_outline,
                suffix: IconButton(icon: Icon(_hide ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _hide = !_hide))),
            validator: (v) => (v ?? '').length < 8 ? s.passwordShort : null,
            onFieldSubmitted: up ? null : (_) => _submit(),
          ),
          if (up) ...[
            const SizedBox(height: 14),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: field(s.phoneLabel, Icons.phone_outlined),
              validator: (v) => EmailAuthFields.phone(s, v),
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
          const SizedBox(height: 22),
          Pressable(
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.ground, minimumSize: const Size.fromHeight(52)),
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ground))
                  : Text(up ? s.createAccount : s.signInEmail, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          if (!up)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(onPressed: _busy ? null : _forgot, child: Text(s.forgotPassword, style: const TextStyle(color: AppColors.goldText))),
            ),
          if (up)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(s.allRequired, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ),
        ]),
      ),
    );
  }
}
