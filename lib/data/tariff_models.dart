/// One line of the published Syrian tariff, kept exactly as the file gives it.
class TariffRow {
  TariffRow(this.raw);

  final Map<String, dynamic> raw;

  String get code => (raw['hs_code'] ?? '').toString().replaceAll(RegExp(r'\D'), '');

  String text(String field, String lang) {
    final own = raw['${field}_$lang'];
    if (own != null && own.toString().trim().isNotEmpty) return own.toString().trim();
    return '';
  }

  /// Description in [lang], falling back to the other language when missing.
  String description(String lang) {
    final first = text('description', lang);
    if (first.isNotEmpty) return first;
    return text('description', lang == 'ar' ? 'en' : 'ar');
  }

  String category(String lang) => text('category', lang);
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

  /// 8-digit code shown as 0000.00.00.
  String get displayCode {
    final c = code;
    if (c.length <= 4) return c;
    if (c.length <= 6) return '${c.substring(0, 4)}.${c.substring(4)}';
    return '${c.substring(0, 4)}.${c.substring(4, 6)}.${c.substring(6)}';
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
  TariffData({required this.source, required this.rows, required this.origin});

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
    final source = json['source'] is Map ? Map<String, dynamic>.from(json['source'] as Map) : <String, dynamic>{};
    return TariffData(source: TariffSource(source), rows: rows, origin: origin);
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
