import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/app/app.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/home/presentation/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding': true,
      'user_id': 101,
      'user_name': 'أحمد الوالد',
      'app_locale': 'ar',
      'my_student_ids': ['st_10'],
    });
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'valid_test_token',
    });
  });

  group('HomeScreen Critical UI & Widget Flow Suite', () {
    testWidgets('1. HomeScreen renders within RootShell with custom scroll view and app sliver header', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = AppController();
      await tester.pumpWidget(MsaratWaselApp(controller: controller));

      // Pump frames for bootstrap completion
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Verify HomeScreen is rendered
      expect(find.byType(HomeScreen), findsOneWidget);

      // Verify CustomScrollView and RefreshIndicator are present
      expect(find.byType(CustomScrollView), findsAtLeastNWidgets(1));
      expect(find.byType(RefreshIndicator), findsAtLeastNWidgets(1));

      controller.stopTrackingPoll();
    });

    testWidgets('2. HomeScreen menu button opens navigation drawer', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = AppController();
      await tester.pumpWidget(MsaratWaselApp(controller: controller));

      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      final menuButton = find.byIcon(Icons.menu_rounded);
      expect(menuButton, findsOneWidget);

      await tester.tap(menuButton);
      await tester.pump(const Duration(milliseconds: 300));

      // Verify drawer is opened
      expect(find.byType(Drawer), findsOneWidget);

      controller.stopTrackingPoll();
    });
  });
}
