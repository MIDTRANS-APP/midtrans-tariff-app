import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midtrans_gcc_tariff/app_state.dart';
import 'package:midtrans_gcc_tariff/data/tariff_models.dart';
import 'package:midtrans_gcc_tariff/ui/item_screen.dart';
import 'package:midtrans_gcc_tariff/ui/news_prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> gz(String path) =>
    jsonDecode(utf8.decode(gzip.decode(File(path).readAsBytesSync()))) as Map<String, dynamic>;

/// Owner 2026-11-10: searching codes needs no details; from the third code page the app
/// suggests registering the details MIRA asks for, to receive periodic customs news.
void main() {
  HsContext.current = HsContext.fromJson(gz('assets/data/hs-context.json.gz'));
  final data = TariffData.fromJson(gz('assets/data/gcc-tariff.json.gz'), 'bundle');
  NewsPrompt.delay = Duration.zero;

  Future<void> openItem(WidgetTester t, AppState state) async {
    await t.pumpWidget(AppScope(
      state: state,
      child: const MaterialApp(home: Directionality(textDirection: TextDirection.rtl, child: ItemScreen(code: '841510109999'))),
    ));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    await t.pump(const Duration(milliseconds: 300));
  }

  testWidgets('the third code page suggests the news; registering keeps the details', (t) async {
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = const Size(1206, 2622);
    t.view.devicePixelRatio = 3;
    final state = AppState()..useForTest(data);
    await openItem(t, state);
    expect(find.text('أخبار جمركية خليجية'), findsNothing, reason: 'first page: nothing');
    await t.pumpWidget(const SizedBox());
    await openItem(t, state);
    expect(find.text('أخبار جمركية خليجية'), findsNothing, reason: 'second page: nothing');
    await t.pumpWidget(const SizedBox());
    await openItem(t, state);
    expect(find.text('أخبار جمركية خليجية'), findsOneWidget, reason: 'third page: the suggestion');
    expect(find.byType(Checkbox), findsNothing, reason: 'GCC news only, no choice');

    // the same details card as MIRA
    await t.tap(find.text('سجّل بياناتي'));
    await t.pump();
    await t.enterText(find.widgetWithText(TextField, 'الاسم'), 'خالد');
    await t.enterText(find.widgetWithText(TextField, 'رقم الهاتف'), '0501234567');
    await t.tap(find.text('رقم الواتساب هو نفسه رقم الهاتف'));
    await t.enterText(find.widgetWithText(TextField, 'البريد الإلكتروني'), 'k@example.com');
    await t.pump();
    t.widget<FilledButton>(find.ancestor(of: find.text('سجّل بياناتي'), matching: find.byType(FilledButton))).onPressed!();
    await t.pump();
    await t.pump(const Duration(seconds: 2));
    final saved = jsonDecode((await SharedPreferences.getInstance()).getString('mira_lead')!) as Map<String, dynamic>;
    expect(saved['news'], 'gcc');
    expect(saved['whatsapp'], '+971501234567');
    expect(find.text('تم التسجيل. ستصلك أخبار التعرفة الجمركية الخليجية عبر واتساب أو البريد الإلكتروني.'), findsOneWidget);
    await t.pump(const Duration(seconds: 5));
  });
}
