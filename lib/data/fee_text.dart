import 'tariff_models.dart';

/// How a line's figures are read out. Same rules and wording MIRA uses
/// (midtrans-mira src/hs-tariff-service.mjs feeText), so the app, the website
/// and MIRA say the same thing about the same code. Figures are shown verbatim.

bool isExempt(TariffRow r) =>
    r.dutyStatus == 'exempt' ||
    RegExp(r'^(exempt|معفى)', caseSensitive: false).hasMatch(r.text('duty_rate', 'en').isNotEmpty ? r.text('duty_rate', 'en') : r.text('duty_rate', 'ar'));

bool isNegative(TariffRow r) =>
    r.dutyStatus == 'negative_list' ||
    r.totalFeeStatus == 'negative_list' ||
    RegExp(r'negative list|القائمة السلبية', caseSensitive: false)
        .hasMatch(r.text('total_fee', 'en').isNotEmpty ? r.text('total_fee', 'en') : r.text('total_fee', 'ar'));

bool notListed(TariffRow r) => r.dutyStatus == 'not_listed' && r.totalFeeStatus == 'not_listed';

String percentOfInvoice(TariffRow r) {
  final v = r.text('total_fee', 'en').isNotEmpty ? r.text('total_fee', 'en') : r.text('total_fee', 'ar');
  return RegExp(r'^\d+(?:\.\d+)?\s*%$').hasMatch(v) ? v.replaceAll(RegExp(r'\s+'), '') : '';
}

bool byWeight(TariffRow r, String lang) => lang == 'en'
    ? RegExp(r'^weight$', caseSensitive: false).hasMatch(r.text('unit', 'en'))
    : r.text('unit', 'ar') == 'وزن';

/// One fee figure on the item page.
class FeeLine {
  const FeeLine(this.label, this.value);
  final String label;
  final String value;
}

class FeeSummary {
  const FeeSummary({required this.lines, required this.note, required this.headline});

  /// Rows of the figures table (label, value as published).
  final List<FeeLine> lines;

  /// Unit explanation or status sentence under the table.
  final String note;

  /// Short form for result lists.
  final String headline;
}

FeeSummary feeSummary(TariffRow r, String lang) {
  final en = lang == 'en';
  if (isNegative(r)) {
    final t = en
        ? 'On the negative list (import restricted — check before shipping)'
        : 'مدرج في القائمة السلبية (استيراده مقيّد — يُتحقَّق منه قبل الشحن)';
    return FeeSummary(lines: const [], note: t, headline: en ? 'Negative list' : 'القائمة السلبية');
  }
  final pct = percentOfInvoice(r);
  if (pct.isNotEmpty) {
    final t = en ? 'Duty $pct of the invoice value' : 'رسم $pct من قيمة الفاتورة';
    return FeeSummary(lines: [FeeLine(en ? 'Total' : 'الإجمالي', pct)], note: t, headline: t);
  }
  if (notListed(r)) {
    final t = en ? 'No figure in the published table — confirm with customs' : 'لا رقم في الجدول المنشور — يُؤكَّد مع الجمارك';
    return FeeSummary(lines: const [], note: t, headline: en ? 'Not listed' : 'غير مدرج');
  }
  String v(String f) => r.text(f, lang);
  final weight = byWeight(r, lang);
  final unit = v('unit');
  final exempt = isExempt(r);
  final lines = <FeeLine>[];
  if (exempt) {
    lines.add(FeeLine(en ? 'Import duty' : 'رسم الاستيراد', en ? 'Exempt' : 'معفى من الرسم'));
  } else if (v('duty_rate').isNotEmpty) {
    lines.add(FeeLine(en ? 'Import duty' : 'رسم الاستيراد', v('duty_rate')));
  }
  if (v('additional_fees').isNotEmpty) lines.add(FeeLine(en ? 'Additional fees' : 'رسوم إضافية', v('additional_fees')));
  if (v('total_fee').isNotEmpty) lines.add(FeeLine(en ? 'Total' : 'الإجمالي', v('total_fee')));
  // export tax shown when not 0, or when a later decree changed the export side
  final exportChanged = r.decreeAmendmentAr.contains('التصدير');
  if (v('export_tax').isNotEmpty && (v('export_tax') != '0' || exportChanged)) {
    lines.add(FeeLine(en ? 'Export tax' : 'ضريبة التصدير', v('export_tax')));
    if (v('export_service_fee_per_ton').isNotEmpty) {
      lines.add(FeeLine(en ? 'Export service fee per ton' : 'رسم خدمات التصدير للطن', v('export_service_fee_per_ton')));
    }
  }
  final note = weight
      ? (en
          ? 'Reference figures in USD — a fixed amount by weight, usually per ton (1,000 kg).'
          : 'قيم مرجعية بالدولار الأمريكي — مبلغ مقطوع حسب الوزن، غالباً لكل طن (1000 كغ).')
      : (en
          ? 'Reference figures in USD${unit.isNotEmpty ? '; unit: $unit' : ''}.'
          : 'قيم مرجعية بالدولار الأمريكي${unit.isNotEmpty ? '؛ الوحدة: $unit' : ''}.');
  final total = v('total_fee');
  var headline = total.isNotEmpty
      ? (en ? 'Total $total USD${weight ? ' by weight' : ''}' : 'الإجمالي $total دولار${weight ? ' حسب الوزن' : ''}')
      : '';
  if (exempt) headline = en ? 'Exempt from duty${headline.isNotEmpty ? ', $headline' : ''}' : 'معفى من الرسم${headline.isNotEmpty ? '، $headline' : ''}';
  return FeeSummary(lines: lines, note: lines.isEmpty ? '' : note, headline: headline);
}

/// Status notes on a line, from the file's own flags.
List<String> statusNotes(TariffRow r, String lang) {
  final en = lang == 'en';
  final notes = <String>[];
  final repl = r.replacedBy;
  if (repl.isNotEmpty || r.sourceStatus.startsWith('replaced_by')) {
    notes.add(en
        ? 'A later legislative decree split or renumbered this code${repl.isNotEmpty ? ' — see ${repl.join(', ')}' : ''}.'
        : 'قسّم مرسوم تشريعي لاحق هذا البند أو غيّر رقمه${repl.isNotEmpty ? ' — راجع ${repl.join('، ')}' : ''}.');
  }
  if (r.sourceStatus.contains('presidential_decree') || r.decreeAmendmentAr.isNotEmpty) {
    final words = r.decreeAmendmentAr;
    notes.add(en
        ? 'Amended by a later legislative decree${words.isNotEmpty ? ': «$words»' : ''}.'
        : 'معدّل بمرسوم تشريعي لاحق${words.isNotEmpty ? ': «$words»' : ''}.');
  }
  if (!r.inLatestAmendment && repl.isEmpty) {
    final neg = isNegative(r);
    notes.add(en
        ? 'Not in the Syrian Customs amended fees table; its ${neg ? 'negative-list status' : 'duty'} is the earlier one (${r.source}), to be confirmed with customs.'
        : 'هذا البند غير وارد في جدول الرسوم الجمركية المعدّلة؛ ${neg ? 'إدراجه في القائمة السلبية من الجدول السابق' : 'رسمه هو الرسم السابق'}، ويُؤكَّد مع الجمارك.');
  }
  return notes;
}
