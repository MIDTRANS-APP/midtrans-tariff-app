import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/dial_codes.dart';
import '../data/mira_client.dart';
import 'motion.dart';
import 'theme.dart';

/// The visitor's details before the chat, every field required (owner 2026-11-10): name,
/// phone and WhatsApp (each with its country, the UAE first, changeable), and email.
class ContactCard extends StatefulWidget {
  const ContactCard({super.key, required this.initial, required this.busy, required this.onDone, this.extra});
  final MiraLead? initial;

  /// Shown above the button (the news popup puts its choices here).
  final Widget? extra;
  final bool busy;
  final ValueChanged<MiraLead> onDone;

  @override
  State<ContactCard> createState() => _ContactCardState();
}

/// The country both numbers start on in the GCC app (owner 2026-11-10).
const _defaultCountry = 'AE';

class _Number {
  _Number(String international, String? knownCountry) {
    final raw = international.replaceAll(RegExp(r'[^\d+]'), '');
    if (raw.startsWith('+') || raw.startsWith('00')) {
      final digits = raw.replaceFirst(RegExp(r'^(\+|00)'), '');
      final match = (dialCodes.toList()..sort((a, b) => b.dial.length.compareTo(a.dial.length)))
          .where((c) => digits.startsWith(c.dial))
          .firstOrNull;
      if (match != null) {
        country = knownCountry?.isNotEmpty == true ? knownCountry! : match.code;
        text.text = digits.substring(match.dial.length);
        return;
      }
      text.text = digits;
    } else {
      text.text = raw;
    }
  }
  String country = _defaultCountry;
  final text = TextEditingController();

  /// The number as +dial digits, or null when too short.
  String? international() {
    final meta = dialCodes.where((c) => c.code == country).firstOrNull;
    final digits = _ContactCardState.asciiDigitsOnly(text.text);
    if (meta == null || digits.length < 6) return null;
    final local = digits.replaceFirst(RegExp('^${meta.dial}'), '').replaceFirst(RegExp(r'^0+'), '');
    return local.length < 6 ? null : '+${meta.dial}$local';
  }
}

class _ContactCardState extends State<ContactCard> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _email = TextEditingController(text: widget.initial?.email ?? '');
  late final _phone = _Number(widget.initial?.phone ?? '', widget.initial?.country);
  late final _whatsapp = _Number(widget.initial?.whatsapp ?? '', null);
  bool _same = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.text.dispose();
    _whatsapp.text.dispose();
    super.dispose();
  }

  void _submit() {
    final s = AppScope.of(context).s;
    final name = _name.text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final phone = _phone.international();
    final whatsapp = _same ? phone : _whatsapp.international();
    final email = _email.text.trim();
    String? err;
    if (name.length < 2) {
      err = s.contactNoName;
    } else if (phone == null) {
      err = s.contactBadPhone;
    } else if (whatsapp == null) {
      err = s.contactBadWhatsApp;
    } else if (email.isEmpty) {
      err = s.contactNoEmail;
    } else if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email)) {
      err = s.contactBadEmail;
    }
    setState(() => _error = err);
    if (err != null) return;
    FocusScope.of(context).unfocus();
    widget.onDone(MiraLead(name: name, phone: phone!, country: _phone.country, whatsapp: whatsapp!, email: email));
  }

  /// Arabic-Indic and Persian digits typed on an Arabic keyboard count as digits.
  static String asciiDigitsOnly(String v) {
    final b = StringBuffer();
    for (final r in v.runes) {
      if (r >= 0x30 && r <= 0x39) {
        b.writeCharCode(r);
      } else if (r >= 0x660 && r <= 0x669) {
        b.writeCharCode(r - 0x660 + 0x30);
      } else if (r >= 0x6F0 && r <= 0x6F9) {
        b.writeCharCode(r - 0x6F0 + 0x30);
      }
    }
    return b.toString();
  }

  Widget _numberRow(_Number n, String countryLabel, String numberLabel, InputDecoration Function(String) deco, bool ar) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: n.country,
            isExpanded: true,
            decoration: deco(countryLabel),
            items: [
              for (final c in dialCodes)
                DropdownMenuItem(
                  value: c.code,
                  child: Text(ar ? '${c.ar}  \u2066+${c.dial}\u2069' : '${c.en} (+${c.dial})', overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: widget.busy ? null : (v) => setState(() => n.country = v ?? _defaultCountry),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: n.text,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            textInputAction: TextInputAction.next,
            decoration: deco(numberLabel),
            enabled: !widget.busy,
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.s;
    final ar = app.lang != 'en';
    InputDecoration deco(String label) => InputDecoration(labelText: label, isDense: true, filled: true, fillColor: AppColors.ground);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: _name, textInputAction: TextInputAction.next, decoration: deco(s.contactName), enabled: !widget.busy),
        const SizedBox(height: 10),
        _numberRow(_phone, s.contactCountry, s.contactPhone, deco, ar),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.busy ? null : () => setState(() => _same = !_same),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Checkbox(
                value: _same,
                activeColor: AppColors.gold,
                onChanged: widget.busy ? null : (v) => setState(() => _same = v ?? false),
              ),
              Expanded(child: Text(s.contactSame, style: const TextStyle(fontSize: 13))),
            ]),
          ),
        ),
        if (!_same) ...[
          _numberRow(_whatsapp, s.contactWhatsAppCountry, s.contactWhatsApp, deco, ar),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: deco(s.contactEmail),
          enabled: !widget.busy,
        ),
        if (widget.extra != null) ...[const SizedBox(height: 10), widget.extra!],
        if (_error != null)
          Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: AppColors.warn, fontSize: 12.5))),
        const SizedBox(height: 10),
        Pressable(child: FilledButton(onPressed: widget.busy ? null : _submit, child: Text(s.contactSend))),
        const SizedBox(height: 6),
        Text(s.contactSaved, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ]),
    );
  }
}
