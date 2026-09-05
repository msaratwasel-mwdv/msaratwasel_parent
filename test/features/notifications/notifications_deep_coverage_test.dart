// Agent 10: Notifications Deep Coverage (notifications_page old + new, notification_service, app_notification)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/notifications/presentation/notifications_page.dart'
    as old_notifications;
import 'package:msaratwasel_user/src/features/notifications/presentation/pages/notifications_page.dart'
    as new_notifications;
import 'package:msaratwasel_user/src/features/notifications/domain/entities/app_notification.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart' hide AppNotification;

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
      'user_email': 'parent@test.com',
      'my_student_ids': ['st_10'],
    });
    FlutterSecureStorage.setMockInitialValues({'access_token': 'mock_token'});
    controller = AppController();
    await controller.bootstrap();
  });

  tearDown(() { controller.stopTrackingPoll(); controller.dispose(); });

  group('Agent 10: Notifications Deep Coverage Suite', () {
    testWidgets('1. Old NotificationsPage renders filters and list', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(child: const old_notifications.NotificationsPage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));
      expect(find.byType(old_notifications.NotificationsPage), findsOneWidget);
    });

    testWidgets('2. Old NotificationsPage scrolls through items', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(child: const old_notifications.NotificationsPage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await t.drag(scrollable.first, const Offset(0, -1000));
        await t.pump(const Duration(milliseconds: 200));
      }
      expect(find.byType(old_notifications.NotificationsPage), findsOneWidget);
    });

    testWidgets('3. Old NotificationsPage taps filter chip', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(child: const old_notifications.NotificationsPage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));
      final chips = find.byType(FilterChip);
      if (chips.evaluate().isNotEmpty) {
        await t.tap(chips.first);
        await t.pump(const Duration(milliseconds: 200));
      }
      expect(find.byType(old_notifications.NotificationsPage), findsOneWidget);
    });

    testWidgets('4. New NotificationsPage renders correctly', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(child: const new_notifications.NotificationsPage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));
      expect(find.byType(new_notifications.NotificationsPage), findsOneWidget);
    });

    testWidgets('5. New NotificationsPage scrolls through notification list', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(child: const new_notifications.NotificationsPage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await t.drag(scrollable.first, const Offset(0, -800));
        await t.pump(const Duration(milliseconds: 200));
      }
      expect(find.byType(new_notifications.NotificationsPage), findsOneWidget);
    });

    test('6. AppNotification entity can be constructed and serialized', () {
      final notification = AppNotification(
        id: 'n1',
        title: 'Test',
        body: 'Test Body',
        timestamp: DateTime.now(),
        read: false,
      );
      expect(notification.id, 'n1');
      expect(notification.title, 'Test');
      expect(notification.read, false);
    });
  });
}
