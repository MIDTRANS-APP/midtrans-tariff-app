import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midtrans_gcc_tariff/app_state.dart';
import 'package:midtrans_gcc_tariff/ui/mira_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// GCC app (owner 2026-11-10): MIRA takes every detail before the chat — name, phone and
/// WhatsApp (both on the UAE code, changeable) and email — then «التحدث مع خبير جمركي»
/// files the request. The test has no network, so the server's number is absent and the
/// closing message says so honestly.
void main() {
  Future<void> open(WidgetTester t) async {
    final state = AppState();
    t.view.physicalSize = const Size(1206, 2622);
    t.view.devicePixelRatio = 3;
    await t.pumpWidget(AppScope(
      state: state,
      child: const MaterialApp(home: Directionality(textDirection: TextDirection.rtl, child: MiraScreen(standalone: true))),
    ));
    await t.pump();
    await t.pump();
  }

  void press(WidgetTester t, String label) =>
      t.widget<FilledButton>(find.ancestor(of: find.text(label), matching: find.byType(FilledButton))).onPressed!();

  testWidgets('details first, every field required, UAE code by default', (t) async {
    SharedPreferences.setMockInitialValues({});
    await open(t);
    expect(find.textContaining('البحث في البنود الجمركية متاح لك دون أي بيانات'), findsOneWidget);
    expect(find.text('أكمل بياناتك أولاً للتحدث مع ميرا'), findsOneWidget, reason: 'the chat box waits');
    expect(find.textContaining('+971'), findsNWidgets(2), reason: 'phone and WhatsApp start on the UAE code');

    press(t, 'متابعة');
    await t.pump();
    expect(find.text('اكتب اسمك لو سمحت.'), findsOneWidget);

    await t.enterText(find.widgetWithText(TextField, 'الاسم'), 'خالد');
    await t.enterText(find.widgetWithText(TextField, 'رقم الهاتف'), '050 123 4567');
    press(t, 'متابعة');
    await t.pump();
    expect(find.text('أدخل رقم واتساب صحيحاً.'), findsOneWidget);

    await t.enterText(find.widgetWithText(TextField, 'رقم واتساب'), '0559876543');
    press(t, 'متابعة');
    await t.pump();
    expect(find.text('اكتب بريدك الإلكتروني.'), findsOneWidget);

    await t.enterText(find.widgetWithText(TextField, 'البريد الإلكتروني'), 'k@example.com');
    press(t, 'متابعة');
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    final saved = (await SharedPreferences.getInstance()).getString('mira_lead')!;
    expect(saved, contains('"phone":"+971501234567"'));
    expect(saved, contains('"whatsapp":"+971559876543"'));
    expect(find.text('متابعة'), findsNothing, reason: 'the card is gone');
    expect(find.text('اكتب سؤالك…'), findsOneWidget, reason: 'the chat box opens');

    // «التحدث مع خبير جمركي» now files the request at once
    await t.tap(find.text('التحدث مع خبير جمركي'));
    await t.pump();
    await t.pump(const Duration(seconds: 3));
    expect(find.textContaining('سيرد عليك خبير جمركي من ميدترانس بأقرب وقت.'), findsOneWidget);
    expect(find.text('مراسلتنا على واتساب'), findsOneWidget);
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('a visitor whose details are kept goes straight to the chat', (t) async {
    SharedPreferences.setMockInitialValues({
      'mira_lead': '{"name":"A","phone":"+971500000000","country":"AE","whatsapp":"+971500000000","email":"a@b.co"}',
    });
    await open(t);
    expect(find.text('متابعة'), findsNothing);
    expect(find.text('التحدث مع خبير جمركي'), findsOneWidget);
  });
}
