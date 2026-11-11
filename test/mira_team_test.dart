import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midtrans_tariff/app_state.dart';
import 'package:midtrans_tariff/ui/mira_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owner 2026-11-10: MIRA answers anyone without asking anything; a guest gives every
/// detail (name, phone and WhatsApp on the Syrian code, email) only when asking for an
/// expert, and nothing goes to the team before. The test has no network, so the
/// server's number is absent and the closing message says so honestly.
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

  testWidgets('the chat is open; the expert asks every detail first', (t) async {
    SharedPreferences.setMockInitialValues({});
    await open(t);
    expect(find.text('متابعة'), findsNothing, reason: 'nothing is asked to chat');
    expect(find.text('اكتب سؤالك…'), findsOneWidget);

    await t.tap(find.text('التحدث مع خبير جمركي'));
    await t.pump();
    expect(find.text('قبل أن أرسل طلبك إلى خبير جمركي من ميدترانس، أحتاج بعض بياناتك:'), findsOneWidget);
    expect(find.textContaining('+963'), findsNWidgets(2), reason: 'phone and WhatsApp start on the Syrian code');

    press(t, 'متابعة');
    await t.pump();
    expect(find.text('اكتب اسمك لو سمحت.'), findsOneWidget);
    await t.enterText(find.widgetWithText(TextField, 'الاسم'), 'خالد');
    await t.enterText(find.widgetWithText(TextField, 'رقم الهاتف'), '0930 123 456');
    press(t, 'متابعة');
    await t.pump();
    expect(find.text('أدخل رقم واتساب صحيحاً.'), findsOneWidget);
    await t.enterText(find.widgetWithText(TextField, 'رقم واتساب'), '0944987654');
    press(t, 'متابعة');
    await t.pump();
    expect(find.text('اكتب بريدك الإلكتروني.'), findsOneWidget);
    await t.enterText(find.widgetWithText(TextField, 'البريد الإلكتروني'), 'k@example.com');
    press(t, 'متابعة');
    await t.pump();
    await t.pump(const Duration(seconds: 3));
    final saved = (await SharedPreferences.getInstance()).getString('mira_lead')!;
    expect(saved, contains('"phone":"+963930123456"'));
    expect(saved, contains('"whatsapp":"+963944987654"'));
    expect(find.textContaining('سيرد عليك خبير جمركي من ميدترانس بأقرب وقت.'), findsOneWidget);
    expect(find.text('مراسلتنا على واتساب'), findsOneWidget);
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('a visitor whose details are kept is not asked again', (t) async {
    SharedPreferences.setMockInitialValues({
      'mira_lead': '{"name":"A","phone":"+971500000000","country":"AE","whatsapp":"+971500000000","email":"a@b.co"}',
    });
    await open(t);
    await t.tap(find.text('التحدث مع خبير جمركي'));
    await t.pump();
    await t.pump(const Duration(seconds: 3));
    expect(find.text('متابعة'), findsNothing);
    expect(find.textContaining('سيرد عليك خبير جمركي من ميدترانس بأقرب وقت.'), findsOneWidget);
    await t.pump(const Duration(seconds: 5));
  });
}
