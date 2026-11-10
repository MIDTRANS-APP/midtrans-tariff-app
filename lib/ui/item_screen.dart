import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ads/ad_slot.dart';
import '../app_state.dart';
import '../shot.dart';
import '../data/fee_text.dart';
import '../data/search.dart' show asciiDigits;
import '../data/tariff_models.dart';
import 'mira_screen.dart';
import 'news_prompt.dart';
import 'share_card.dart';
import 'motion.dart';
import 'theme.dart';
import 'widgets.dart';

class ItemScreen extends StatelessWidget {
  const ItemScreen({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.s;
    final lang = app.lang;
    final row = app.byCode(code);
    if (row == null) return Scaffold(appBar: AppBar(), body: Center(child: Text(s.noResults)));
    final fees = feeSummary(row, lang);
    final notes = statusNotes(row, lang);
    final other = lang == 'ar' ? row.text('description', 'en') : row.text('description', 'ar');
    final saved = app.favorites.contains(row.code);

    // MIRA opens asking about this code, with its tariff card so it answers from the GCC tariff.
    void openMira() => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => MiraScreen(standalone: true, code: row.code, displayCode: row.displayCode)));

    // from the third code page: the suggestion to register for periodic customs news
    return NewsPromptHook(child: Scaffold(
      appBar: AppBar(
        title: Text(s.itemTitle),
        actions: [
          IconButton(
            tooltip: saved ? s.unsave : s.save,
            icon: PopSwitcher(child: Icon(saved ? Icons.star : Icons.star_border, key: ValueKey(saved), color: AppColors.gold)),
            onPressed: () => app.favorites.toggle(row.code),
          ),
          IconButton(
            tooltip: s.share,
            icon: Icon(Icons.adaptive.share),
            onPressed: () => shareCodeCard(context, row),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('${row.category(lang)} · ${s.chapter(row.chapter)} · ${s.heading(row.heading)}', style: const TextStyle(fontSize: 12, color: AppColors.gold)),
            const SizedBox(height: 6),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: GestureDetector(
                onLongPress: () async {
                  await Clipboard.setData(ClipboardData(text: row.code));
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.copied(row.code))));
                },
                child: CodeText(row.displayCode, size: 28),
              ),
            ),
            const SizedBox(height: 8),
            Text(row.description(lang), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, height: 1.5)),
            if (other.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(other,
                  textDirection: lang == 'ar' ? TextDirection.ltr : TextDirection.rtl,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.5)),
            ],
          ]),
        ),
        GoldHeading(s.figures),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Card(
            child: Column(children: [
              for (final l in fees.lines)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(children: [
                    Expanded(child: Text(l.label, style: const TextStyle(fontSize: 13, color: AppColors.muted))),
                    Text(l.value, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ]),
                ),
              if (fees.note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                  child: Text(fees.note, style: const TextStyle(fontSize: 12.5, height: 1.6, color: AppColors.text)),
                ),
            ]),
          ),
        ),
        if (dutyOn(row, 1) != null) _DutyCalculator(row: row),
        if (notes.isNotEmpty) ...[
          GoldHeading(s.notes),
          for (final n in notes)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(n, style: const TextStyle(fontSize: 13, height: 1.7, color: AppColors.warn)),
            ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Text('${s.source}: ${row.source}\n${s.reviewed}: ${row.lastReviewed}\n${s.guidance}',
              style: const TextStyle(fontSize: 11.5, height: 1.7, color: AppColors.muted)),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Pressable(
            child: Shine(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.ground,
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: openMira,
                icon: const Icon(Icons.auto_awesome, size: 20),
                label: Text(s.askMira, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const AdSlot(AdPlacement.itemBanner),
      ]),
    ));
  }
}

/// Customs value in USD -> duty in USD at the line's percentage (owner 2026-11-07:
/// «نسبة فقط + حاسبة بالدولار»). Nothing leaves the phone.
class _DutyCalculator extends StatefulWidget {
  const _DutyCalculator({required this.row});
  final TariffRow row;

  @override
  State<_DutyCalculator> createState() => _DutyCalculatorState();
}

class _DutyCalculatorState extends State<_DutyCalculator> {
  final _value = TextEditingController(text: Shot.calc);

  @override
  void initState() {
    super.initState();
    if (Shot.demo) Shot.calcFeed.addListener(_demoCalc);
  }

  void _demoCalc() {
    final v = Shot.calcFeed.value;
    if (v != null && mounted) setState(() => _value.text = v);
  }

  @override
  void dispose() {
    Shot.calcFeed.removeListener(_demoCalc);
    _value.dispose();
    super.dispose();
  }

  static String money(double v) {
    final fixed = v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);
    final parts = fixed.split('.');
    final whole = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    return parts.length > 1 ? '$whole.${parts[1]}' : whole;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).s;
    final typed = double.tryParse(asciiDigits(_value.text).replaceAll(RegExp(r'[,\s٬]'), ''));
    final duty = typed == null ? null : dutyOn(widget.row, typed);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GoldHeading(s.calcTitle),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextField(
                controller: _value,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(labelText: s.calcLabel, hintText: s.calcHint, prefixText: r'$ '),
                onChanged: (_) => setState(() {}),
              ),
              if (duty != null) ...[
                const SizedBox(height: 12),
                Text(s.calcResult(money(duty), percentOfInvoice(widget.row)),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.goldText)),
              ],
              const SizedBox(height: 8),
              Text(s.calcNote, style: const TextStyle(fontSize: 12, height: 1.6, color: AppColors.muted)),
            ]),
          ),
        ),
      ),
    ]);
  }
}
