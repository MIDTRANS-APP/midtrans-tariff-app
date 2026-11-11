import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../config.dart';
import '../data/mira_client.dart';
import 'account_screen.dart';
import 'contact_card.dart';
import 'motion.dart';
import 'theme.dart';

/// MIRA drawn by the app in its own design, talking to MIRA's brain directly
/// (owner 2026-10-28: «خذ API لميرا و اعمل انتغريت بتصميم التطبيق»).
class MiraScreen extends StatefulWidget {
  const MiraScreen({super.key, this.standalone = false, this.code, this.displayCode, this.question, this.askTeam = false});

  /// Opens on the contact step (the screenshot mode's «team»).
  final bool askTeam;

  /// Pushed from a code page (own app bar, own bottom inset) rather than shown as a tab.
  final bool standalone;

  /// A code page opens MIRA asking about this code (8 digits) and attaches its tariff card.
  final String? code;
  final String? displayCode;

  /// A question sent as soon as the screen opens (the freight prices strip asks for a quote).
  final String? question;

  @override
  State<MiraScreen> createState() => _MiraScreenState();
}

class _Line {
  _Line(this.mine, this.text, {this.handoff = false, this.failed = false, this.contact = false, this.filed = false, this.signIn = false})
      : asksCountry = !mine && !failed && !contact && !filed && _countryQuestion.hasMatch(text);

  /// A quote request waits for the visitor to sign in or give their details (owner 2026-11-10).
  final bool signIn;
  final bool mine;
  final String text;
  final bool handoff;
  final bool failed;

  /// MIRA asks for the visitor's details: the contact card follows this line.
  final bool contact;

  /// The request went to the team: WhatsApp is offered under it.
  final bool filed;

  /// MIRA asks which destination country: the app offers Syria or the Gulf tariff as
  /// buttons instead (owner 2026-10-28).
  final bool asksCountry;

  static final _countryQuestion = RegExp(
      r'(بلد الوصول|أي بلد|لأي بلد|اي بلد|لاي بلد|أي دولة|لأي دولة|دولة الوصول|which country|what country|destination country)',
      caseSensitive: false);
}

class _MiraScreenState extends State<MiraScreen> with AutomaticKeepAliveClientMixin {
  final _client = MiraClient();
  late final _mirror = MiraMirror(_client);
  MiraLead? _lead;

  /// A signed-in visitor (Apple, Google or an email account) is never asked: their
  /// account already holds name, email and phone (owner 2026-11-10). Only a guest is.
  MiraLead? get _accountLead {
    final account = AppScope.of(context).account;
    final p = account.profile;
    if (!account.signedIn) return null;
    return MiraLead(
      name: p.name.isNotEmpty ? p.name : (account.user?.displayName ?? ''),
      phone: p.phone,
      whatsapp: p.phone,
      email: p.email.isNotEmpty ? p.email : (account.user?.email ?? ''),
      visitorId: 'acct-${account.user!.uid}',
    );
  }

  bool _accountRecorded = false;

  /// Who is talking: the account first, else the details given in the chat.
  MiraLead? get _who => _accountLead ?? _lead;
  bool _filing = false;


  /// MIRA answers anyone without asking anything; the details are asked only when a
  /// request is to go to the team, and nothing reaches the team before (owner 2026-11-10:
  /// «لا يسأل العميل و لا يصل إلى موظفين الشركة طلب عروض اسعار من دون تسجيل»).
  bool get _registered => _accountLead != null || _lead?.complete == true;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _lines = <_Line>[];
  final _history = <MiraTurn>[];
  bool _busy = false;
  static final _teamAsk = RegExp(r'^\s*(موظف|التحدث مع|تحدث مع|كلم|أكلم|اكلم|بدي احكي|فريق ميدترانس|خبير|talk to (a |the )?(human|team|agent|staff|expert)|agent|human|expert)', caseSensitive: false);
  String? _lastQuestion;
  String? _lastCode;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _client.savedLead().then((l) {
      if (l != null && mounted) setState(() => _lead = _mirror.lead = l);
    });
    if (widget.code != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final s = AppScope.of(context).s;
        _send(s.askAboutCode(widget.displayCode ?? widget.code!), code: widget.code);
      });
    } else if (widget.question != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(widget.question!));
    } else if (widget.askTeam) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _askTeam());
    }
  }

  @override
  void dispose() {
    _mirror.flush();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text, {String? code}) async {
    final q = text.trim();
    if (q.isEmpty || _busy) return;
    final app = AppScope.of(context);
    _mirror.lang = app.lang;
    final account = _accountLead;
    if (account != null) {
      _mirror.lead = account;
      if (!_accountRecorded) {
        _accountRecorded = true;
        unawaited(_client.upsertVisitor(account, lang: app.lang));
      }
    }
    // «Talk to the team» typed: the request, as the button does.
    if (code == null && q.length <= 40 && _teamAsk.hasMatch(q)) {
      setState(() => _lines.add(_Line(true, q)));
      _input.clear();
      _mirror.note(visitor: true, text: q);
      _askTeam();
      return;
    }
    if (code != null) {
      // as the website: the Desk sees which code the visitor came from
      _mirror.note(visitor: false, text: app.lang == 'en' ? 'The visitor came from the Syrian tariff page, code $code.' : 'جاء الزائر من صفحة التعرفة السورية — البند $code.', meta: const {'source': 'flow'});
    }
    _mirror.note(visitor: true, text: q);
    setState(() {
      _lines.add(_Line(true, q));
      _busy = true;
      _lastQuestion = q;
      _lastCode = code;
    });
    _input.clear();
    _toEnd();
    try {
      final reply = await _client.ask(q, lang: app.lang, history: List.of(_history), tariffCode: code, visitor: _registered ? _who : null);
      _history
        ..add(MiraTurn('user', q))
        ..add(MiraTurn('assistant', reply.answer));
      _mirror.note(visitor: false, text: reply.answer, meta: {
        'source': 'brain',
        'handoff_suggested': reply.handoffSuggested,
        if (reply.tag != null) 'tag': reply.tag,
      });
      if (!mounted) return;
      setState(() => _lines.add(_Line(false, reply.answer, handoff: reply.handoffSuggested, signIn: reply.rfqPending && !_registered)));
      // a quote MIRA would have sent to the team: the visitor registers first, then it goes
      if (reply.rfqPending && !_registered) _askTeam();
    } catch (_) {
      if (!mounted) return;
      setState(() => _lines.add(_Line(false, app.s.miraOffline, failed: true)));
    } finally {
      if (mounted) setState(() => _busy = false);
      _toEnd();
    }
  }

  void _retry() {
    final q = _lastQuestion;
    if (q == null) return;
    setState(() {
      // drop the failed answer and its question; _send adds the question again
      if (_lines.isNotEmpty && _lines.last.failed) _lines.removeLast();
      if (_lines.isNotEmpty && _lines.last.mine) _lines.removeLast();
    });
    _send(q, code: _lastCode);
  }

  Future<void> _newChat() async {
    setState(() {
      _lines.clear();
      _history.clear();
      _lastQuestion = null;
    });
    // a new chat is a new conversation in the Desk too
    await _mirror.reset();
    await _client.newSession();
  }

  /// «التحدث مع خبير جمركي»: a registered visitor's request goes at once; a guest
  /// gives their details first, in the chat.
  void _askTeam() {
    if (_filing) return;
    if (_registered) {
      _fileRequest();
      return;
    }
    if (_lines.isNotEmpty && _lines.last.contact) return;
    final s = AppScope.of(context).s;
    setState(() => _lines.add(_Line(false, s.contactIntro, contact: true)));
    _toEnd();
  }

  Future<void> _contactGiven(MiraLead lead) async {
    final app = AppScope.of(context);
    final known = lead.withVisitorId(_lead?.visitorId.isNotEmpty == true ? _lead!.visitorId : MiraClient.newRequestKey());
    _mirror.lang = app.lang;
    _mirror.note(visitor: false, text: app.s.contactIntro, meta: const {'source': 'flow'});
    _mirror.note(visitor: true, text: known.summary);
    setState(() {
      _lead = _mirror.lead = known;
      _lines.add(_Line(true, known.summary));
    });
    await _client.saveLead(known);
    unawaited(_client.upsertVisitor(known, lang: app.lang));
    await _fileRequest();
  }

  /// The request: MIRA's server issues its number, the Desk gets the conversation
  /// marked as a request, and the visitor reads one closing message.
  Future<void> _fileRequest() async {
    final lead = _who;
    if (lead == null || _filing) return;
    final app = AppScope.of(context);
    setState(() => _filing = true);
    final key = MiraClient.newRequestKey();
    final h = await _client.handoff(lead, lang: app.lang, requestKey: key);
    final number = (h?.isTest ?? false) ? null : h?.number;
    final text = app.s.requestSent(number: h?.number, online: h?.anyOnline ?? false, replyBy: h?.replyBy, emailed: number != null && lead.email.isNotEmpty);
    _mirror.note(visitor: false, text: text, meta: {
      'source': 'flow',
      'staff_requested': !(h?.isTest ?? false),
      if (h?.number != null) 'request_number': h!.number,
      'request_key': key,
    });
    unawaited(_mirror.flush());
    if (!mounted) return;
    setState(() {
      _filing = false;
      _lines.add(_Line(false, text, filed: true));
    });
    _toEnd();
  }

  void _toEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent + 80, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        }
      });

  /// A signed-in visitor's account fills the card; the visitor still confirms it.
  MiraLead? _fromAccount() {
    final p = AppScope.of(context).account.profile;
    if (p.name.isEmpty && p.phone.isEmpty && p.email.isEmpty) return null;
    return MiraLead(name: p.name, phone: p.phone, email: p.email);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = AppScope.of(context).s;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: widget.standalone ? 0 : null,
        title: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.gold)),
            child: const Icon(Icons.auto_awesome, color: AppColors.gold, size: 18),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.tabMira, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
              Text(s.miraSubtitle, style: const TextStyle(fontSize: 11, color: AppColors.muted), overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
        actions: [
          if (_lines.isNotEmpty)
            IconButton(tooltip: s.miraNew, icon: const Icon(Icons.add_comment_outlined, color: AppColors.gold), onPressed: _busy ? null : _newChat),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: ListView(
            controller: _scroll,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            children: [
              _Bubble(line: _Line(false, s.miraHello)),
              if (_lines.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final q in s.miraSuggestions) Pressable(child: ActionChip(label: Text(q), onPressed: () => _send(q))),
                    Pressable(child: ActionChip(avatar: const Icon(Icons.support_agent, size: 18, color: AppColors.gold), label: Text(s.miraTeam), onPressed: _askTeam)),
                  ]),
                ),
              for (final l in _lines) ...[
                _Bubble(line: l, onRetry: l.failed ? _retry : null),
                if (l.asksCountry && identical(l, _lines.last) && !_busy)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final c in s.miraCountries) Pressable(child: ActionChip(label: Text(c), onPressed: () => _send(c))),
                    ]),
                  ),
                if (l.handoff && !_filing)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Pressable(
                      child: TextButton.icon(
                        icon: const Icon(Icons.support_agent, color: AppColors.gold, size: 18),
                        label: Text(s.miraTeam, style: const TextStyle(color: AppColors.goldText)),
                        onPressed: _askTeam,
                      ),
                    ),
                  ),
                if (l.signIn && !AppScope.of(context).account.signedIn)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Pressable(
                      child: TextButton.icon(
                        icon: const Icon(Icons.person, color: AppColors.gold, size: 18),
                        label: Text(s.miraSignIn, style: const TextStyle(color: AppColors.goldText)),
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountScreen())),
                      ),
                    ),
                  ),
                if (l.contact && identical(l, _lines.last))
                  ContactCard(initial: _lead ?? _fromAccount(), busy: _filing, onDone: _contactGiven),
                if (l.filed)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Pressable(
                      child: TextButton.icon(
                        icon: const Icon(Icons.chat, color: AppColors.gold, size: 18),
                        label: Text(s.miraWhatsApp, style: const TextStyle(color: AppColors.goldText)),
                        onPressed: () => launchUrl(Uri.parse(AppConfig.whatsappUrl), mode: LaunchMode.externalApplication),
                      ),
                    ),
                  ),
              ],
              if (_busy) _Thinking(label: s.miraThinking),
              if (_filing) _Thinking(label: s.sending),
            ],
          ),
        ),
        _Composer(
          controller: _input,
          hint: s.miraHint,
          note: s.miraNote,
          busy: _busy,
          onSend: () => _send(_input.text),
          // As a tab, the navigation bar below already sits on the bottom inset.
          bottomInset: widget.standalone,
        ),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.line, this.onRetry});
  final _Line line;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final mine = line.mine;
    return Align(
      alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: mine ? AppColors.gold : AppColors.surface,
            border: mine ? null : Border.all(color: line.failed ? AppColors.warn : AppColors.line),
            borderRadius: BorderRadiusDirectional.only(
              topStart: const Radius.circular(16),
              topEnd: const Radius.circular(16),
              bottomStart: Radius.circular(mine ? 16 : 4),
              bottomEnd: Radius.circular(mine ? 4 : 16),
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _LinkedText(line.text, color: mine ? AppColors.ground : AppColors.text),
            if (onRetry != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Pressable(child: OutlinedButton(onPressed: onRetry, child: Text(AppScope.of(context).s.retry))),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Answer text with its web links tappable (they open outside the app).
class _LinkedText extends StatefulWidget {
  const _LinkedText(this.text, {required this.color});
  final String text;
  final Color color;

  @override
  State<_LinkedText> createState() => _LinkedTextState();
}

class _LinkedTextState extends State<_LinkedText> {
  static final _url = RegExp(r'https://[^\s)]+');
  final _taps = <TapGestureRecognizer>[];

  void _clearTaps() {
    for (final t in _taps) {
      t.dispose();
    }
    _taps.clear();
  }

  @override
  void dispose() {
    _clearTaps();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _clearTaps();
    final text = widget.text;
    final spans = <InlineSpan>[];
    var i = 0;
    for (final m in _url.allMatches(text)) {
      if (m.start < i) continue;
      if (m.start > i) spans.add(TextSpan(text: text.substring(i, m.start)));
      final link = m.group(0)!.replaceAll(RegExp(r'[.,،]+$'), '');
      final tap = TapGestureRecognizer()..onTap = () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
      _taps.add(tap);
      spans.add(TextSpan(
        text: link,
        recognizer: tap,
        style: const TextStyle(color: AppColors.goldText, decoration: TextDecoration.underline, decorationColor: AppColors.goldText),
      ));
      i = m.start + link.length;
    }
    if (i < text.length) spans.add(TextSpan(text: text.substring(i)));
    return SelectableText.rich(TextSpan(style: TextStyle(fontSize: 14, height: 1.7, color: widget.color), children: spans));
  }
}

class _Thinking extends StatelessWidget {
  const _Thinking({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          ]),
        ),
      );
}

/// The writing box sits right on top of the navigation bar: no footer, no extra margin.
class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.hint, required this.note, required this.busy, required this.onSend, required this.bottomInset});
  final TextEditingController controller;
  final String hint;
  final String note;
  final bool busy;
  final VoidCallback onSend;
  final bool bottomInset;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder edge(Color c) => OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: c));
    return Container(
      decoration: const BoxDecoration(color: AppColors.bar, border: Border(top: BorderSide(color: AppColors.line))),
      child: SafeArea(
        top: false,
        bottom: bottomInset,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: hint,
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.ground,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: edge(AppColors.line),
                    enabledBorder: edge(AppColors.line),
                    focusedBorder: edge(AppColors.gold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Pressable(
                child: IconButton.filled(
                  onPressed: busy ? null : onSend,
                  style: IconButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.ground, disabledBackgroundColor: AppColors.line),
                  icon: const Icon(Icons.send),
                ),
              ),
            ]),
            const SizedBox(height: 4),
            Text(note, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
          ]),
        ),
      ),
    );
  }
}

