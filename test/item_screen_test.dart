import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midtrans_gcc_tariff/app_state.dart';
import 'package:midtrans_gcc_tariff/data/tariff_models.dart';
import 'package:midtrans_gcc_tariff/ui/customs_screen.dart';
import 'package:midtrans_gcc_tariff/ui/item_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> gz(String path) =>
    jsonDecode(utf8.decode(gzip.decode(File(path).readAsBytesSync()))) as Map<String, dynamic>;

void main() {
  HsContext.current = HsContext.fromJson(gz('assets/data/hs-context.json.gz'));
  final data = TariffData.fromJson(gz('assets/data/gcc-tariff.json.gz'), 'bundle');

  Future<void> open(WidgetTester t, String code) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState()..useForTest(data);
    t.view.physicalSize = const Size(1206, 2622);
    t.view.devicePixelRatio = 3;
    await t.pumpWidget(AppScope(
      state: state,
      child: MaterialApp(home: Directionality(textDirection: TextDirection.rtl, child: ItemScreen(code: code))),
    ));
    await t.pump();
  }

  testWidgets('item page shows the duty and the USD calculator works', (t) async {
    final r = data.rows.firstWhere((x) => x.dutyPercent == 5 && x.importStatus == 'value');
    await open(t, r.code);
    expect(find.text(r.displayCode), findsOneWidget);
    expect(find.text('5%'), findsWidgets);
    expect(find.text('احسب الرسم بالدولار'), findsOneWidget);
    await t.enterText(find.byType(TextField), '12,500');
    await t.pump();
    expect(find.text('الرسم الجمركي التقريبي: 625 دولار (\u20665%\u2069)'), findsOneWidget);
  });

  testWidgets('prohibited line has no calculator', (t) async {
    await open(t, '010310000000');
    expect(find.text('ممنوع استيراده في التعرفة الخليجية'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('customs tab lists the six states and their official sites', (t) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState()..useForTest(data);
    await t.pumpWidget(AppScope(state: state, child: const MaterialApp(home: CustomsScreen())));
    await t.pump();
    for (final host in ['zatca.gov.sa', 'www.dubaicustoms.gov.ae', 'www.customs.gov.kw']) {
      expect(find.text(host), findsOneWidget);
    }
    await t.scrollUntilVisible(find.text('www.customs.gov.om'), 300);
    expect(find.text('www.customs.gov.om'), findsOneWidget);
  });
}
