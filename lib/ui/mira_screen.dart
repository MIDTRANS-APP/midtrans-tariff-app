import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../config.dart';
import '../data/mira_client.dart';
import 'motion.dart';
import 'theme.dart';

/// MIRA drawn by the app in its own design, talking to MIRA's brain directly
/// (owner 2026-10-28: «خذ API لميرا و اعمل انتغريت بتصميم التطبيق»).
class MiraScreen extends StatefulWidget {
  const MiraScreen({super.key, this.standalone = false, this.code, this.displayCode, this.question});

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
  _Line(this.mine, this.text, {this.handoff = false, this.failed = false})
      : asksCountry = !mine && !failed && _countryQuestion.hasMatch(text);
  final bool mine;
  final String text;
  final bool handoff;
  final bool failed;

  /// MIRA asks which destination country: the app offers Syria or the Gulf tariff as
  /// buttons instead (owner 2026-10-28).
  final bool asksCountry;

  static final _countryQuestion = RegExp(
      r'(بلد الوصول|أي بلد|لأي بلد|اي بلد|لاي بلد|أي دولة|لأي دولة|دولة الوصول|which country|what country|destination country)',
      caseSensitive: false);
}

class _MiraScreenState extends State<MiraScreen> with AutomaticKeepAliveClientMixin {
  final _client = MiraClient();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _lines = <_Line>[];
  final _history = <MiraTurn>[];
  bool _busy = false;
  String? _lastQuestion;
  String? _lastCode;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.code != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final s = AppScope.of(context).s;
        _send(s.askAboutCode(widget.displayCode ?? widget.code!), code: widget.code);
      });
    } else if (widget.question != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(widget.question!));
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text, {String? code}) async {
    final q = text.trim();
    if (q.isEmpty || _busy) return;
    final app = AppScope.of(context);
    setState(() {
      _lines.add(_Line(true, q));
      _busy = true;
      _lastQuestion = q;
      _lastCode = code;
    });
    _input.clear();
    _toEnd();
    try {
      final reply = await _client.ask(q, lang: app.lang, history: List.of(_history), tariffCode: code);
      _history
        ..add(MiraTurn('user', q))
        ..add(MiraTurn('assistant', reply.answer));
      if (!mounted) return;
      setState(() => _lines.add(_Line(false, reply.answer, handoff: reply.handoffSuggested)));
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

  void _newChat() => setState(() {
        _lines.clear();
        _history.clear();
        _lastQuestion = null;
      });

  void _toEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent + 80, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        }
      });

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
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.tabMira, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(s.miraSubtitle, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ]),
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
                if (l.handoff)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Pressable(
                      child: TextButton.icon(
                        icon: const Icon(Icons.chat, color: AppColors.gold, size: 18),
                        label: Text(s.miraTeam, style: const TextStyle(color: AppColors.goldText)),
                        onPressed: () => launchUrl(Uri.parse(AppConfig.whatsappUrl), mode: LaunchMode.externalApplication),
                      ),
                    ),
                  ),
              ],
              if (_busy) _Thinking(label: s.miraThinking),
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
  static final _url = RegExp(r'https?://[^\s)]+');
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
