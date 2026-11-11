import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midtrans_tariff/app_state.dart';
import 'package:midtrans_tariff/ui/news_prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owner 2026-11-10: searching codes needs no details; from the third code page the
/// Syrian app suggests registering the details MIRA asks for, for Syrian customs news only.
void main() {
  NewsPrompt.delay = Duration.zero;

  Future<void> openPage(WidgetTester t, AppState state) async {
    await t.pumpWidget(AppScope(
      state: state,
      child: const MaterialApp(home: Directionality(textDirection: TextDirection.rtl, child: NewsPromptHook(child: Scaffold(body: SizedBox())))),
    ));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    await t.pump(const Duration(milliseconds: 300));
  }

  testWidgets('the third code page suggests the Syrian news; registering keeps the details', (t) async {
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = const Size(1206, 2622);
    t.view.devicePixelRatio = 3;
    final state = AppState();
    for (var i = 1; i <= 2; i++) {
      await openPage(t, state);
      expect(find.text('أخبار جمركية سورية'), findsNothing, reason: 'page $i: nothing');
      await t.pumpWidget(const SizedBox());
    }
    await openPage(t, state);
    expect(find.text('أخبار جمركية سورية'), findsOneWidget, reason: 'third page: the suggestion');
    expect(find.textContaining('خليجية'), findsNothing, reason: 'Syrian news only');

    await t.tap(find.text('سجّل بياناتي'));
    await t.pump();
    await t.enterText(find.widgetWithText(TextField, 'الاسم'), 'خالد');
    await t.enterText(find.widgetWithText(TextField, 'رقم الهاتف'), '0930123456');
    await t.tap(find.text('رقم الواتساب هو نفسه رقم الهاتف'));
    await t.enterText(find.widgetWithText(TextField, 'البريد الإلكتروني'), 'k@example.com');
    await t.pump();
    t.widget<FilledButton>(find.ancestor(of: find.text('سجّل بياناتي'), matching: find.byType(FilledButton))).onPressed!();
    await t.pump();
    await t.pump(const Duration(seconds: 2));
    final saved = jsonDecode((await SharedPreferences.getInstance()).getString('mira_lead')!) as Map<String, dynamic>;
    expect(saved['news'], 'sy');
    expect(saved['phone'], '+963930123456');
    expect(saved['whatsapp'], '+963930123456');
    expect(find.text('تم التسجيل. ستصلك أخبار التعرفة الجمركية السورية عبر واتساب أو البريد الإلكتروني.'), findsOneWidget);
    await t.pump(const Duration(seconds: 5));
  });
}
