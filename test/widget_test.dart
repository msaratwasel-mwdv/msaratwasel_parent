import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:msaratwasel_user/src/app/app.dart';

void main() {
  testWidgets('App shows login screen first', (WidgetTester tester) async {
    await tester.pumpWidget(const MsaratWaselApp());

    // Allow bootstrap to complete and show the login screen.
    await tester.pump(const Duration(seconds: 4));

    expect(find.text('تسجيل الدخول'), findsWidgets);
    expect(find.text('سجل دخولك للمتابعة'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('User can log in and reach home screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MsaratWaselApp());

    // Wait for splash -> login transition.
    await tester.pump(const Duration(seconds: 4));

    // Fill in login form.
    await tester.enterText(
      find.byType(TextFormField).at(0),
      '1234567890',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      '555123456',
    );

    await tester.tap(
      find.widgetWithText(ElevatedButton, 'تسجيل الدخول'),
    );

    // Let the simulated login Future complete and UI rebuild.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    // Dashboard content should now be visible.
    expect(find.text('إجراءات سريعة'), findsWidgets);
  });
}
