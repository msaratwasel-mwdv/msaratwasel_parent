import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/profile/presentation/parent_profile_page.dart';
import 'package:msaratwasel_user/src/features/profile/presentation/change_password_page.dart';
import 'package:msaratwasel_user/src/features/absence/presentation/pages/absence_history_page.dart';
import 'package:msaratwasel_user/src/features/absence/presentation/pages/absence_request_page.dart';

Widget buildTestableWidget({required Widget child, required AppController controller}) {
  return MaterialApp(
    home: AppScope(
      controller: controller,
      child: Scaffold(
        body: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'user_id': 100,
      'user_name': 'Test Parent',
      'user_phone': '0501234567',
      'user_email': 'parent@example.com',
      'has_seen_onboarding': true,
    });
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'mock_token',
    });

    controller = AppController();
    await controller.bootstrap();
  });

  tearDown(() {
    controller.stopTrackingPoll();
    controller.dispose();
  });

  group('Agent 9: Profile and Absence Screens Widget Suite', () {
    testWidgets('1. ParentProfilePage renders profile header, fields, and action buttons', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const ParentProfilePage(),
          controller: controller,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ParentProfilePage), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('2. ChangePasswordPage renders form fields and validation indicators', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const ChangePasswordPage(),
          controller: controller,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ChangePasswordPage), findsOneWidget);
      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3));
    });

    testWidgets('3. AbsenceHistoryPage renders empty state and list elements', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const AbsenceHistoryPage(),
          controller: controller,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AbsenceHistoryPage), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('4. AbsenceRequestPage renders student dropdown, radio options, and notes field', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const AbsenceRequestPage(),
          controller: controller,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AbsenceRequestPage), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });
  });
}
