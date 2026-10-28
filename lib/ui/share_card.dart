import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app_state.dart';
import '../config.dart';
import '../data/fee_text.dart';
import '../data/tariff_models.dart';
import 'theme.dart';

/// Shares a code as a compact image card in the app's design, with the page link
/// as text beside it (owner 2026-10-28: «كبطاقة بشكل مضغوط و ليس نص»).
Future<void> shareCodeCard(BuildContext context, TariffRow row) async {
  final app = AppScope.of(context);
  final lang = app.lang;
  final link = lang == 'ar' ? AppConfig.tariffPageAr : AppConfig.tariffPageEn;
  final box = context.findRenderObject() as RenderBox?;
  final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;

  final key = GlobalKey();
  final overlay = Overlay.of(context);
  final icon = precacheImage(const AssetImage('assets/branding/app-icon-96.png'), context);
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      // drawn off screen, only to be captured
      left: -10000,
      top: 0,
      child: Directionality(
        textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: Material(
          type: MaterialType.transparency,
          child: RepaintBoundary(key: key, child: CodeCard(row: row, lang: lang)),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  try {
    // two frames: one to lay out, one for the icon image to paint
    await WidgetsBinding.instance.endOfFrame;
    await icon;
    await WidgetsBinding.instance.endOfFrame;
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/tariff-${row.code}.png');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'image/png')],
      text: '${row.displayCode} — ${row.description(lang)}\n$link',
      sharePositionOrigin: origin,
    ));
  } finally {
    entry.remove();
  }
}

/// The card itself: 340 points wide, as tall as its text.
class CodeCard extends StatelessWidget {
  const CodeCard({super.key, required this.row, required this.lang});
  final TariffRow row;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final fees = feeSummary(row, lang);
    final en = lang == 'en';
    return Container(
      width: 340,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.ground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold, width: 1.2),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.asset('assets/branding/app-icon-96.png', width: 26, height: 26),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(en ? 'Syrian Customs Tariff' : 'التعرفة الجمركية السورية',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.goldText)),
          ),
        ]),
        const SizedBox(height: 12),
        Text(row.displayCode,
            textDirection: TextDirection.ltr,
            textAlign: en ? TextAlign.left : TextAlign.right,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.gold, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(row.description(lang), maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.text)),
        const SizedBox(height: 10),
        if (fees.lines.isEmpty)
          _pill(fees.headline)
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
            child: Column(children: [
              for (final l in fees.lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    Expanded(child: Text(l.label, style: const TextStyle(fontSize: 12.5, color: AppColors.muted))),
                    Text(l.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                  ]),
                ),
            ]),
          ),
        if (fees.note.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(fees.note, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, height: 1.5, color: AppColors.muted)),
        ],
        const SizedBox(height: 10),
        Container(height: 1, color: AppColors.line),
        const SizedBox(height: 8),
        Text(
          en
              ? 'Unofficial · for guidance only · mid-trans.com'
              : 'غير رسمي · للاسترشاد فقط · mid-trans.com',
          style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
        ),
      ]),
    );
  }

  Widget _pill(String t) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
          child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.warn)),
        ),
      );
}
