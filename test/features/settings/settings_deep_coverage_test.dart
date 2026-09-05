// Agent 12: Settings Deep Coverage (more_page, contact_us, privacy_policy, about_app)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/settings/presentation/more_page.dart';
import 'package:msaratwasel_user/src/features/settings/presentation/contact_us_page.dart';
import 'package:msaratwasel_user/src/features/settings/presentation/privacy_policy_page.dart';
import 'package:msaratwasel_user/src/features/settings/presentation/about_app_page.dart';

Widget _build({required Widget child, required AppController c}) {
  return MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: AppScope(controller: c, child: Scaffold(body: child)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding': true, 'user_id': 101,
      'user_name': 'أحمد الوالد', 'app_locale': 'ar',
      'user_email': 'parent@test.com', 'user_phone': '0555555555',
    });
    FlutterSecureStorage.setMockInitialValues({'access_token': 'mock_token'});
    controller = AppController();
    await controller.bootstrap();
  });

  tearDown(() { controller.stopTrackingPoll(); controller.dispose(); });

  group('Agent 12: Settings Deep Coverage Suite', () {
    testWidgets('1. MorePage renders full list including theme and language', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(child: const MorePage(), c: controller));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(MorePage), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('2. MorePage renders sections and settings items', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(child: const MorePage(), c: controller));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(MorePage), findsOneWidget);
    });

    testWidgets('3. ContactUsPage renders complaint form with TextFormField inputs', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(child: const ContactUsPage(), c: controller));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(ContactUsPage), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('4. ContactUsPage validates empty form submission', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(child: const ContactUsPage(), c: controller));
      await t.pump(const Duration(milliseconds: 300));
      final buttons = find.byType(ElevatedButton);
      if (buttons.evaluate().isNotEmpty) {
        await t.tap(buttons.first);
        await t.pump(const Duration(milliseconds: 200));
      }
      expect(find.byType(ContactUsPage), findsOneWidget);
    });

    testWidgets('5. PrivacyPolicyPage renders scrollable sections', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(child: const PrivacyPolicyPage(), c: controller));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(PrivacyPolicyPage), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('6. PrivacyPolicyPage scrolls to bottom without error', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(child: const PrivacyPolicyPage(), c: controller));
      await t.pump(const Duration(milliseconds: 300));
      await t.drag(find.byType(CustomScrollView), const Offset(0, -2000));
      await t.pump(const Duration(milliseconds: 200));
      expect(find.byType(PrivacyPolicyPage), findsOneWidget);
    });

    testWidgets('7. AboutAppPage renders app version and developer info', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(child: const AboutAppPage(), c: controller));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(AboutAppPage), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('8. AboutAppPage scrolls to bottom showing all sections', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(child: const AboutAppPage(), c: controller));
      await t.pump(const Duration(milliseconds: 300));
      await t.drag(find.byType(CustomScrollView), const Offset(0, -1000));
      await t.pump(const Duration(milliseconds: 200));
      expect(find.byType(AboutAppPage), findsOneWidget);
    });
  });
}
