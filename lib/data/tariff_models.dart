/// Search and browsing helpers bundled with the app (assets/data/hs-context.json.gz):
/// chapter -> section name, 6-digit HS (the same worldwide) -> its wording. Never figures.
class HsContext {
  HsContext._(this._chapters, this._hs6);
  static HsContext empty = HsContext._(const {}, const {});
  static HsContext current = empty;

  final Map<String, dynamic> _chapters;
  final Map<String, dynamic> _hs6;

  static HsContext fromJson(Map<String, dynamic> j) => HsContext._(
      Map<String, dynamic>.from(j['chapters'] as Map? ?? const {}), Map<String, dynamic>.from(j['hs6'] as Map? ?? const {}));

  String section(String chapter, String lang) => ((_chapters[chapter] as Map?)?[lang] ?? '').toString();
  String hs6(String code6, String lang) => ((_hs6[code6] as Map?)?[lang] ?? '').toString();
}

/// One line of the published GCC unified tariff, kept exactly as the file gives it.
class TariffRow {
  TariffRow(this.raw);

  final Map<String, dynamic> raw;

  String get code => (raw['hs_code'] ?? '').toString().replaceAll(RegExp(r'\D'), '');

  String text(String field, String lang) {
    final own = raw['${field}_$lang'];
    if (own != null && own.toString().trim().isNotEmpty) return own.toString().trim();
    return '';
  }

  /// Description in [lang], falling back to the other language when missing. The
  /// file's outline dashes («- - ») are dropped for display.
  String description(String lang) {
    var first = text('description', lang);
    if (first.isEmpty) first = text('description', lang == 'ar' ? 'en' : 'ar');
    return stripDashes(first);
  }

  static String stripDashes(String t) => t.replaceFirst(RegExp(r'^[\s\-–—]+'), '').trim();

  /// Section the chapter belongs to (from [HsContext]); the file's own label otherwise.
  String category(String lang) {
    final sec = HsContext.current.section(chapter, lang);
    return sec.isNotEmpty ? sec : text('category', lang);
  }

  /// 4-digit heading shown as 01.01.
  String get heading => code.length >= 4 ? '${code.substring(0, 2)}.${code.substring(2, 4)}' : code;
  String get importStatus => (raw['import_status'] ?? '').toString();
  String get notesText => (raw['notes'] ?? '').toString();

  /// Duty as a number (5 for 5%), when the line has a percentage.
  double? get dutyPercent {
    if (dutyStatus != 'percent') return null;
    final v = raw['duty_rate'];
    if (v is num) return v.toDouble();
    return double.tryParse(text('duty_rate', 'en').replaceAll('%', '').trim());
  }
  String get dutyStatus => (raw['duty_status'] ?? '').toString();
  String get totalFeeStatus => (raw['total_fee_status'] ?? '').toString();
  String get sourceStatus => (raw['source_status'] ?? '').toString();
  String get source => (raw['source'] ?? '').toString();
  String get lastReviewed => (raw['last_reviewed'] ?? '').toString();
  bool get inLatestAmendment => raw['in_latest_amendment'] != false;
  String get decreeAmendmentAr => (raw['decree_amendment_ar'] ?? '').toString().trim();

  /// New code(s) a later decree split or renumbered this line into.
  List<String> get replacedBy {
    final v = raw['replaced_by'];
    if (v == null) return const [];
    final list = v is List ? v.map((e) => e.toString()) : v.toString().split(RegExp(r'[,،\s]+'));
    return list.map((e) => e.replaceAll(RegExp(r'\D'), '')).where((e) => e.isNotEmpty).toList();
  }

  /// 12-digit code shown as 0000.00.00.0000 (HS 6 · GCC 8 · national 12).
  String get displayCode {
    final c = code;
    if (c.length <= 4) return c;
    if (c.length <= 6) return '${c.substring(0, 4)}.${c.substring(4)}';
    if (c.length <= 8) return '${c.substring(0, 4)}.${c.substring(4, 6)}.${c.substring(6)}';
    return '${c.substring(0, 4)}.${c.substring(4, 6)}.${c.substring(6, 8)}.${c.substring(8)}';
  }

  String get chapter => code.length >= 2 ? code.substring(0, 2) : code;
}

/// The file's own source block: name, review date, warning. Shown, never hard-coded.
class TariffSource {
  TariffSource(this.raw);

  final Map<String, dynamic> raw;

  String get name => (raw['name'] ?? '').toString();
  String get lastReviewed => (raw['last_reviewed'] ?? '').toString();
  String get warning => (raw['warning'] ?? '').toString();
  int? get recordCount => raw['record_count'] is int ? raw['record_count'] as int : null;
}

class TariffData {
  TariffData({required this.source, required this.rows, required this.origin, this.declaredCount});

  /// Number of lines the file says it has (GCC file: top-level «count»).
  final int? declaredCount;

  final TariffSource source;
  final List<TariffRow> rows;

  /// 'bundle', 'cache' or 'network': where this copy was loaded from.
  final String origin;

  static TariffData fromJson(Map<String, dynamic> json, String origin) {
    final rows = (json['rows'] as List? ?? const [])
        .whereType<Map>()
        .map((r) => TariffRow(Map<String, dynamic>.from(r)))
        .where((r) => r.code.isNotEmpty)
        .toList()
      ..sort((a, b) => a.code.compareTo(b.code));
    // the GCC file gives its source as a sentence; the Syrian one as a block
    final src = json['source'];
    final source = src is Map ? Map<String, dynamic>.from(src) : <String, dynamic>{'name': src?.toString() ?? ''};
    final count = json['count'] is int ? json['count'] as int : TariffSource(source).recordCount;
    return TariffData(source: TariffSource(source), rows: rows, origin: origin, declaredCount: count);
  }

  /// Latest review date across the source block and the rows.
  String get reviewedOn {
    final dates = <String>[source.lastReviewed, ...rows.map((r) => r.lastReviewed)]
        .where((d) => RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(d))
        .toList()
      ..sort();
    return dates.isEmpty ? '' : dates.last;
  }
}
