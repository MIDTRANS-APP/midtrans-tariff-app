import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:midtrans_tariff/data/tariff_models.dart';
import 'package:midtrans_tariff/data/tariff_repository.dart';

void main() {
  Map<String, dynamic> bundle() => jsonDecode(utf8.decode(gzip.decode(File('assets/data/syria-tariff.json.gz').readAsBytesSync())))
      as Map<String, dynamic>;
  bool ok(Map<String, dynamic> json) => TariffRepository.looksComplete(TariffData.fromJson(json, 'network'));

  test('the published file is accepted', () {
    expect(ok(bundle()), isTrue);
  });

  test('a cut-off file is refused', () {
    final json = bundle();
    json['rows'] = (json['rows'] as List).sublist(0, 100);
    (json['source'] as Map)['record_count'] = 100;
    expect(ok(json), isFalse);
  });

  test('a file with fewer lines than it declares is refused', () {
    final json = bundle();
    (json['rows'] as List).removeLast();
    expect(ok(json), isFalse);
  });

  test('a line without a code is refused', () {
    final json = bundle();
    ((json['rows'] as List).first as Map)['hs_code'] = '';
    expect(ok(json), isFalse);
  });
}
