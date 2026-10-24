import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/fee_text.dart';
import '../data/push.dart';
import '../data/tariff_models.dart';
import 'item_screen.dart';
import 'motion.dart';
import 'theme.dart';

class GoldHeading extends StatelessWidget {
  const GoldHeading(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Row(children: [
          Container(width: 4, height: 22, decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
        ]),
      );
}

/// Code shown left to right whatever the interface direction.
class CodeText extends StatelessWidget {
  const CodeText(this.code, {super.key, this.size = 16});
  final String code;
  final double size;

  @override
  Widget build(BuildContext context) =>
      Text(code, textDirection: TextDirection.ltr, style: codeStyle.copyWith(fontSize: size));
}

class RowTile extends StatelessWidget {
  const RowTile(this.row, {super.key});
  final TariffRow row;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final lang = app.lang;
    final fee = feeSummary(row, lang).headline;
    final other = lang == 'ar' ? row.text('description', 'en') : row.text('description', 'ar');
    return Pressable(
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ItemScreen(code: row.code))),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                CodeText(row.displayCode),
                const Spacer(),
                if (fee.isNotEmpty)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF1E3D3A), borderRadius: BorderRadius.circular(6)),
                      child: Text(fee, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFFC9D3D1))),
                    ),
                  ),
              ]),
              const SizedBox(height: 6),
              Text(row.description(lang), style: const TextStyle(fontSize: 14, height: 1.6)),
              if (other.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(other,
                    textDirection: lang == 'ar' ? TextDirection.ltr : TextDirection.rtl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

/// The fixed notice that this is not a government app.
class UnofficialNotice extends StatelessWidget {
  const UnofficialNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.s;
    final d = app.data;
    final version = d == null ? '' : '${s.dataVersion}: ${d.reviewedOn}';
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF102B29), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.line)),
      child: Text('${s.unofficial}${version.isEmpty ? '' : '\n$version'}', style: const TextStyle(fontSize: 11.5, height: 1.7, color: AppColors.muted)),
    );
  }
}

/// Asks once whether the person wants notifications (tariff updates, MIDTRANS
/// offers). Nothing is enabled without a yes; the answer can be changed in About.
class PushAskCard extends StatelessWidget {
  const PushAskCard({super.key, required this.push});
  final Push push;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: push,
        builder: (context, _) {
          if (!push.available || push.asked) return const SizedBox.shrink();
          final s = AppScope.of(context).s;
          return Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gold)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                const Icon(Icons.notifications_active_outlined, color: AppColors.gold, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(s.pushTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
              ]),
              const SizedBox(height: 6),
              Text(s.pushAsk, style: const TextStyle(fontSize: 13, height: 1.6, color: AppColors.muted)),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => push.setEnabled(false), child: Text(s.pushNo, style: const TextStyle(color: AppColors.muted))),
                const SizedBox(width: 4),
                Pressable(child: FilledButton(onPressed: () => push.setEnabled(true), child: Text(s.pushYes))),
              ]),
            ]),
          );
        },
      );
}
