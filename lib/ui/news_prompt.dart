import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_state.dart';
import '../data/mira_client.dart';
import 'contact_card.dart';
import 'theme.dart';

/// The suggestion to register for periodic customs news (owner 2026-11-10): the same
/// details MIRA asks for, kept in one place, so a registered visitor is not asked again
/// when they ask for the MIDTRANS team. Searching the codes never needs it.
///
/// Shown from the third code page a visitor opens, at most once every 14 days and three
/// times in all; never again once they have chosen their news.
class NewsPrompt {
  static const _countKey = 'news_prompt_items';
  static const _lastKey = 'news_prompt_last';
  static const _timesKey = 'news_prompt_times';
  static const _gap = Duration(days: 14);
  static bool _showing = false;

  /// This app's news: the Syrian tariff (the GCC app offers the GCC news; owner 2026-11-10).
  static const newsTopic = 'sy';

  @visibleForTesting
  static Duration delay = const Duration(milliseconds: 1200);

  static Future<void> itemOpened(BuildContext context) async {
    if (_showing) return;
    // a signed-in visitor gives nothing more: their account already has the details
    // and its own tariff newsletter
    if (AppScope.of(context).account.signedIn) return;
    final p = await SharedPreferences.getInstance();
    final n = (p.getInt(_countKey) ?? 0) + 1;
    await p.setInt(_countKey, n);
    if (n < 3) return;
    final lead = await MiraClient().savedLead();
    if (lead != null && lead.news.isNotEmpty) return;
    final times = p.getInt(_timesKey) ?? 0;
    final last = p.getInt(_lastKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (times >= 3 || now - last < _gap.inMilliseconds) return;
    await p.setInt(_timesKey, times + 1);
    await p.setInt(_lastKey, now);
    await Future<void>.delayed(delay);
    if (!context.mounted || _showing) return;
    _showing = true;
    try {
      await show(context, lead);
    } finally {
      _showing = false;
    }
  }

  static Future<void> show(BuildContext context, MiraLead? lead) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.ground,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => _NewsSheet(lead: lead),
      );
}

/// Opens [NewsPrompt] when a code page is shown.
class NewsPromptHook extends StatefulWidget {
  const NewsPromptHook({super.key, required this.child});
  final Widget child;

  @override
  State<NewsPromptHook> createState() => _NewsPromptHookState();
}

class _NewsPromptHookState extends State<NewsPromptHook> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) NewsPrompt.itemOpened(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _NewsSheet extends StatefulWidget {
  const _NewsSheet({required this.lead});
  final MiraLead? lead;

  @override
  State<_NewsSheet> createState() => _NewsSheetState();
}

class _NewsSheetState extends State<_NewsSheet> {
  bool _form = false;
  bool _busy = false;

  MiraLead? _initial(AppState app) {
    if (widget.lead != null) return widget.lead;
    final p = app.account.profile;
    if (p.name.isEmpty && p.phone.isEmpty && p.email.isEmpty) return null;
    return MiraLead(name: p.name, phone: p.phone, email: p.email);
  }

  Future<void> _done(MiraLead lead) async {
    final app = AppScope.of(context);
    setState(() => _busy = true);
    final client = MiraClient();
    final id = widget.lead?.visitorId.isNotEmpty == true ? widget.lead!.visitorId : MiraClient.newRequestKey();
    final saved = lead.withVisitorId(id).withNews(NewsPrompt.newsTopic);
    await client.saveLead(saved);
    await client.upsertVisitor(saved, lang: app.lang);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(app.s.newsDone)));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.s;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const Icon(Icons.campaign_outlined, color: AppColors.gold),
              const SizedBox(width: 8),
              Expanded(child: Text(s.newsTitle, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 10),
            Text(s.newsText, style: const TextStyle(fontSize: 13.5, height: 1.6, color: AppColors.muted)),
            const SizedBox(height: 12),
            if (!_form) ...[
              FilledButton(onPressed: () => setState(() => _form = true), child: Text(s.newsRegister)),
              TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(s.newsLater)),
            ] else
              ContactCard(initial: _initial(app), busy: _busy, onDone: _done, submitLabel: s.newsRegister),
          ]),
        ),
      ),
    );
  }
}
