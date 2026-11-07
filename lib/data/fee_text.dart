import 'tariff_models.dart';

/// How a line of the GCC unified tariff is read out. Figures are shown as published:
/// the duty is a percentage of the customs value (CIF), the same in the six GCC states.

bool isProhibited(TariffRow r) => r.importStatus == 'prohibited';
bool isSpecial(TariffRow r) => r.importStatus == 'special';
bool notSpecified(TariffRow r) => r.dutyPercent == null;

/// Kept for share card and lists that ask for a short percent: '5%' or ''.
String percentOfInvoice(TariffRow r) {
  final p = r.dutyPercent;
  return p == null ? '' : '${formatPercent(p)}%';
}

String formatPercent(double p) => p == p.roundToDouble() ? p.toInt().toString() : p.toString();

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

  /// Explanation or status sentence under the table.
  final String note;

  /// Short form for result lists.
  final String headline;
}

FeeSummary feeSummary(TariffRow r, String lang) {
  final en = lang == 'en';
  if (isProhibited(r)) {
    final t = en ? 'Import prohibited in the GCC tariff' : 'ممنوع استيراده في التعرفة الخليجية';
    return FeeSummary(lines: const [], note: t, headline: en ? 'Prohibited' : 'ممنوع استيراده');
  }
  final pct = percentOfInvoice(r);
  final lines = <FeeLine>[];
  if (pct.isNotEmpty) {
    lines.add(FeeLine(en ? 'Customs duty' : 'الرسم الجمركي', pct));
  } else {
    lines.add(FeeLine(en ? 'Customs duty' : 'الرسم الجمركي', en ? 'Not specified' : 'غير محدّد'));
  }
  final special = isSpecial(r);
  if (special) lines.add(FeeLine(en ? 'Import status' : 'حالة الاستيراد', en ? 'Special goods' : 'سلع خاصة'));

  String note;
  if (special) {
    note = en
        ? 'Special goods: import needs conditions or approvals that differ between GCC states — check with the customs of the destination state.'
        : 'سلع خاصة: استيرادها يحتاج شروطاً أو موافقات تختلف بين دول الخليج — يُتحقَّق منها مع جمارك دولة الوصول.';
  } else if (pct.isEmpty) {
    note = en ? 'No duty figure in the published table — confirm with customs.' : 'لا رقم للرسم في الجدول المنشور — يُؤكَّد مع الجمارك.';
  } else {
    note = en
        ? 'Percentage of the customs value (CIF: goods + freight + insurance). VAT and excise tax are separate and set by each state.'
        : 'نسبة من القيمة الجمركية (CIF: البضاعة + الشحن + التأمين). ضريبة القيمة المضافة والضريبة الانتقائية منفصلة وتحددها كل دولة.';
  }

  var headline = pct.isNotEmpty
      ? (pct == '0%' ? (en ? 'Duty 0% (exempt)' : 'رسم 0% (معفى)') : (en ? 'Duty $pct of the value' : 'رسم $pct من القيمة'))
      : (en ? 'Duty not specified' : 'رسم غير محدّد');
  if (special) headline = en ? 'Special goods · $headline' : 'سلع خاصة · $headline';
  return FeeSummary(lines: lines, note: note, headline: headline);
}

/// Duty in USD on a customs value in USD, or null when the line has no percentage.
double? dutyOn(TariffRow r, double valueUsd) {
  final p = r.dutyPercent;
  if (p == null || isProhibited(r)) return null;
  return valueUsd * p / 100;
}

/// Status notes on a line, from the file's own flags.
List<String> statusNotes(TariffRow r, String lang) {
  final en = lang == 'en';
  final notes = <String>[];
  if (r.sourceStatus == 'reference_import_pending_official_confirmation') {
    notes.add(en
        ? 'Reference copy of the unified tariff: classification, duty, exemptions and import status are confirmed by the customs of the destination GCC state.'
        : 'نسخة مرجعية من التعرفة الموحّدة: التصنيف والرسم والإعفاءات وحالة الاستيراد تؤكّدها جمارك دولة الخليج المستوردة.');
  }
  if (r.dutyPercent == 100) {
    notes.add(en
        ? 'A 100% duty usually applies to tobacco and similar goods; some states add excise tax on top.'
        : 'رسم 100% يطبَّق عادة على التبغ ومنتجاته وما يشابهها، وتضيف بعض الدول ضريبة انتقائية فوقه.');
  }
  return notes;
}
