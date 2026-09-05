import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/shared/widgets/primary_button.dart';

import 'package:msaratwasel_user/src/app/app.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/auth/presentation/login_screen.dart';

void main() {
  setUp(() {
    // Provide mock SharedPreferences with onboarding already seen
    // and mock FlutterSecureStorage so bootstrap completes immediately.
    SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('App shows login screen first', (WidgetTester tester) async {
    await tester.pumpWidget(const MsaratWaselApp());

    // Let multiple frames pump for bootstrap completion
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Authenticated user launches directly into RootShell', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding': true,
      'user_id': 99,
      'user_name': 'Test User',
    });
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'mock_token',
    });

    final controller = AppController();
    await tester.pumpWidget(MsaratWaselApp(controller: controller));

    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Should not show LoginScreen, should show root shell
    expect(find.byType(LoginScreen), findsNothing);

    controller.stopTrackingPoll();
  });
}
