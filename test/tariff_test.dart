import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:midtrans_gcc_tariff/data/fee_text.dart';
import 'package:midtrans_gcc_tariff/data/search.dart';
import 'package:midtrans_gcc_tariff/data/tariff_models.dart';

Map<String, dynamic> gz(String path) =>
    jsonDecode(utf8.decode(gzip.decode(File(path).readAsBytesSync()))) as Map<String, dynamic>;

void main() {
  HsContext.current = HsContext.fromJson(gz('assets/data/hs-context.json.gz'));
  final json = gz('assets/data/gcc-tariff.json.gz');
  final data = TariffData.fromJson(json, 'bundle');
  final search = TariffSearch(data.rows);
  TariffRow row(String code) => data.rows.firstWhere((r) => r.code == code);

  test('bundled snapshot loads every published line', () {
    expect(data.rows.length, json['count']);
    expect(data.rows.every((r) => r.code.length == 12), isTrue);
    expect(data.reviewedOn, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
  });

  test('12-digit codes display as 0000.00.00.0000', () {
    expect(row('010121100001').displayCode, '0101.21.10.0001');
    expect(row('010121100001').heading, '01.01');
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

  test('short GCC wording is still found by the HS6 wording (horses)', () {
    final r = search.search('horses');
    expect(r.any((x) => x.code.startsWith('010121')), isTrue);
    expect(search.search('خيول').any((x) => x.code.startsWith('0101')), isTrue);
  });

  test('everyday words find the tariff term (قهوة → بن)', () {
    expect(search.search('قهوة').any((x) => x.code.startsWith('0901')), isTrue);
  });

  test('chapters show their section name', () {
    expect(row('010121100001').category('en'), 'Animals and Animal Products');
  });

  test('percent duty and the USD calculator', () {
    final r = data.rows.firstWhere((x) => x.dutyPercent == 5 && x.importStatus == 'value');
    final f = feeSummary(r, 'ar');
    expect(f.lines.first.value, '5%');
    expect(f.headline, 'رسم 5% من القيمة');
    expect(dutyOn(r, 10000), 500);
    expect(percentOfInvoice(r), '5%');
  });

  test('prohibited and special goods say so', () {
    final p = row('010310000000');
    expect(feeSummary(p, 'ar').lines, isEmpty);
    expect(feeSummary(p, 'ar').note, contains('ممنوع'));
    expect(dutyOn(p, 1000), isNull);
    final s = row('020311000000');
    expect(feeSummary(s, 'ar').headline, startsWith('سلع خاصة'));
  });

  test('descriptions drop the outline dashes', () {
    expect(row('010310000000').description('ar'), 'خنازير أصيلة للأنسال');
  });

  test('every line yields a summary without throwing', () {
    for (final r in data.rows) {
      feeSummary(r, 'ar');
      feeSummary(r, 'en');
      statusNotes(r, 'en');
    }
  });
}
