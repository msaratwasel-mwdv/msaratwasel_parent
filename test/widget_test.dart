import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:msaratwasel_user/src/app/app.dart';

void main() {
  setUp(() {
    // Provide mock SharedPreferences with onboarding already seen
    // so bootstrap completes instantly and shows LoginScreen.
    SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});
  });

  testWidgets('App shows login screen first', (WidgetTester tester) async {
    await tester.pumpWidget(const MsaratWaselApp());

    // Bootstrap has multiple async steps (SharedPrefs, SecureStorage with 3s timeout,
    // FlutterNativeSplash removal via postFrameCallback + Future.delayed).
    // Pump multiple times to process all intermediate frames.
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(find.text('تسجيل الدخول'), findsWidgets);
    expect(find.text('سجل دخولك للمتابعة'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('User can log in and reach home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MsaratWaselApp());

    // Wait for bootstrap to complete (multiple pumps for async steps).
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    // Fill in login form.
    await tester.enterText(find.byType(TextFormField).at(0), '1234567890');
    await tester.enterText(find.byType(TextFormField).at(1), '555123456');

    await tester.tap(find.widgetWithText(ElevatedButton, 'تسجيل الدخول'));

    // Let the simulated login Future complete and UI rebuild.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    // Dashboard content should now be visible.
    expect(find.text('إجراءات سريعة'), findsWidgets);
  });
}
