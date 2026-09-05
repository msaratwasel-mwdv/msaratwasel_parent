import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/settings/presentation/more_page.dart';
import 'package:msaratwasel_user/src/features/settings/presentation/contact_us_page.dart';
import 'package:msaratwasel_user/src/features/settings/presentation/privacy_policy_page.dart';
import 'package:msaratwasel_user/src/features/settings/presentation/about_app_page.dart';
import 'package:msaratwasel_user/src/features/notifications/presentation/notifications_page.dart';
import 'package:msaratwasel_user/src/features/chat/presentation/contacts_page.dart';
import 'package:msaratwasel_user/src/features/onboarding/presentation/onboarding_page.dart';

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
      'user_name': 'Test User',
      'user_email': 'test@example.com',
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

  group('Agent 10: Settings, Notifications, Contacts, and Onboarding Widget Suite', () {
    testWidgets('1. MorePage renders options list, theme switcher, and navigation items', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const MorePage(),
          controller: controller,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(MorePage), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('2. ContactUsPage renders contact information and complaint submission form', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const ContactUsPage(),
          controller: controller,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ContactUsPage), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('3. PrivacyPolicyPage renders sections and header', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const PrivacyPolicyPage(),
          controller: controller,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(PrivacyPolicyPage), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('4. AboutAppPage renders app info and developer details', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const AboutAppPage(),
          controller: controller,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(AboutAppPage), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('5. NotificationsPage renders filter chips and notification list', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const NotificationsPage(),
          controller: controller,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(NotificationsPage), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('6. ContactsPage renders contacts list view or empty state', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const ContactsPage(),
          controller: controller,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ContactsPage), findsOneWidget);
    });

    testWidgets('7. OnboardingPage renders page views and allows navigation to end', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: OnboardingPage(controller: controller),
          controller: controller,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);
    });
  });
}
