import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:midtrans_tariff/data/fee_text.dart';
import 'package:midtrans_tariff/data/search.dart';
import 'package:midtrans_tariff/data/tariff_models.dart';

TariffData loadBundle() {
  final text = utf8.decode(gzip.decode(File('assets/data/syria-tariff.json.gz').readAsBytesSync()));
  return TariffData.fromJson(jsonDecode(text) as Map<String, dynamic>, 'bundle');
}

void main() {
  final data = loadBundle();
  final search = TariffSearch(data.rows);
  TariffRow row(String code) => data.rows.firstWhere((r) => r.code == code);

  test('bundled snapshot loads every published line', () {
    expect(data.rows.length, data.source.recordCount);
    expect(data.reviewedOn, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
  });

  test('code search accepts dots, spaces and Arabic-Indic digits', () {
    final a = search.search('0901');
    expect(a, isNotEmpty);
    expect(a.every((r) => r.code.startsWith('0901')), isTrue);
    expect(search.search('٠٩٠١').map((r) => r.code), a.map((r) => r.code));
    expect(search.search('0901.21').every((r) => r.code.startsWith('090121')), isTrue);
  });

  test('Arabic search folds hamza and taa marbuta spellings', () {
    final a = search.search('اسمنت').map((r) => r.code).toSet();
    final b = search.search('إسمنت').map((r) => r.code).toSet();
    expect(a, isNotEmpty);
    expect(a, b);
  });

  test('English search matches every word', () {
    final r = search.search('coffee roasted');
    expect(r, isNotEmpty);
    expect(r.first.code.startsWith('0901'), isTrue);
  });

  test('figures are shown verbatim from the file', () {
    final r = row('52094200');
    final fees = feeSummary(r, 'ar');
    expect(fees.lines.map((l) => l.value), containsAll(['375', '125', '500']));
    expect(fees.note, contains('حسب الوزن'));
    expect(fees.headline, 'الإجمالي 500 دولار حسب الوزن');
  });

  test('negative-list and not-in-amendment lines say so', () {
    final r = row('02101100');
    expect(feeSummary(r, 'ar').lines, isEmpty);
    expect(feeSummary(r, 'ar').note, contains('القائمة السلبية'));
    expect(statusNotes(r, 'ar').join(), contains('غير وارد في جدول الرسوم الجمركية المعدّلة'));
  });

  test('every line yields a summary without throwing', () {
    for (final r in data.rows) {
      feeSummary(r, 'ar');
      feeSummary(r, 'en');
      statusNotes(r, 'en');
    }
  });
}
