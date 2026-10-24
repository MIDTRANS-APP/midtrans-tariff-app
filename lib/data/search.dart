import 'tariff_models.dart';

/// Arabic-Indic (٠-٩), Persian (۰-۹) and full-width (０-９) digits to ASCII.
String asciiDigits(String s) {
  final b = StringBuffer();
  for (final c in s.runes) {
    if (c >= 0x660 && c <= 0x669) {
      b.writeCharCode(c - 0x660 + 48);
    } else if (c >= 0x6F0 && c <= 0x6F9) {
      b.writeCharCode(c - 0x6F0 + 48);
    } else if (c >= 0xFF10 && c <= 0xFF19) {
      b.writeCharCode(c - 0xFF10 + 48);
    } else {
      b.writeCharCode(c);
    }
  }
  return b.toString();
}

final _diacritics = RegExp('[ً-ْٰـ]');
final _nonWord = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

/// Folds the spellings people type interchangeably: hamza forms, taa marbuta,
/// alif maqsura, tashkeel and tatweel; lowercases Latin.
String normalizeText(String s) {
  var t = asciiDigits(s).toLowerCase().replaceAll(_diacritics, '');
  t = t
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي');
  return t.replaceAll(_nonWord, ' ').trim();
}

/// Everyday words mapped to the word the tariff uses. Same lists as MIRA
/// (hs-tariff-service.mjs AR_SYNONYMS / LATIN_SYNONYMS), plus coffee (tariff: «بن»).
const _synonyms = <String, String>{
  'رز': 'ارز',
  'موبايل': 'هواتف',
  'موبايلات': 'هواتف',
  'جوال': 'هواتف',
  'جوالات': 'هواتف',
  'قهوه': 'بن',
  'phone': 'telephone',
  'phones': 'telephones',
  'chicken': 'poultry',
  'chickens': 'poultry',
};

List<String> _words(String s) => normalizeText(s).split(' ').where((w) => w.isNotEmpty).toList();

/// A line prepared once for searching.
class _Indexed {
  _Indexed(this.row)
      : ar = normalizeText(row.text('description', 'ar')),
        en = normalizeText(row.text('description', 'en'));
  final TariffRow row;
  final String ar;
  final String en;
}

class TariffSearch {
  TariffSearch(List<TariffRow> rows) : _index = rows.map(_Indexed.new).toList(growable: false);

  final List<_Indexed> _index;

  /// Digits only (dots and spaces allowed) → code-prefix search; otherwise every
  /// word must appear in the Arabic or English description (prefix match per word).
  List<TariffRow> search(String query, {int limit = 200}) {
    final q = asciiDigits(query).trim();
    if (q.isEmpty) return const [];
    final digits = q.replaceAll(RegExp(r'[\s.\-/]'), '');
    if (RegExp(r'^\d+$').hasMatch(digits)) {
      return _index.where((i) => i.row.code.startsWith(digits)).take(limit).map((i) => i.row).toList();
    }
    final terms = _words(q);
    if (terms.isEmpty) return const [];
    final scored = <(int, _Indexed)>[];
    for (final i in _index) {
      var score = 0;
      var all = true;
      for (final t in terms) {
        var s = _termScore(i, t);
        final alt = _synonyms[t];
        if (alt != null) {
          final a = _termScore(i, alt);
          if (a > s) s = a;
        }
        if (s == 0) {
          all = false;
          break;
        }
        score += s;
      }
      if (all) scored.add((score, i));
    }
    scored.sort((a, b) {
      final c = b.$1.compareTo(a.$1);
      return c != 0 ? c : a.$2.row.code.compareTo(b.$2.row.code);
    });
    return scored.take(limit).map((e) => e.$2.row).toList();
  }

  // whole word 3, word prefix 2, inside a word 1 (Arabic attached prefixes: ال، و، ب…)
  static int _termScore(_Indexed i, String t) {
    var best = 0;
    for (final text in [i.ar, i.en]) {
      if (text.isEmpty) continue;
      for (final w in text.split(' ')) {
        if (w == t) return 3;
        if (w.startsWith(t)) {
          best = best < 2 ? 2 : best;
        } else if (t.length >= 3 && w.contains(t)) {
          best = best < 1 ? 1 : best;
        }
      }
    }
    return best;
  }

  /// Distinct categories in file order of first appearance.
  static List<String> categories(List<TariffRow> rows, String lang) {
    final seen = <String>{};
    final out = <String>[];
    for (final r in rows) {
      final c = r.category(lang);
      if (c.isNotEmpty && seen.add(c)) out.add(c);
    }
    return out;
  }
}
