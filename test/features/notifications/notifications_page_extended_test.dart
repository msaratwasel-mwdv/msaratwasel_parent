import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/features/notifications/presentation/notifications_page.dart'
    as old_notifications;
import 'package:msaratwasel_user/src/features/notifications/presentation/pages/notifications_page.dart'
    as new_notifications;

Widget _wrapWithAppScope({required Widget child, required AppController controller}) {
  return MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, materialChild) => AppScope(
      controller: controller,
      child: materialChild!,
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding': true,
      'user_id': 101,
      'user_name': 'أحمد الوالد',
      'app_locale': 'ar',
      'my_student_ids': ['std_1'],
    });
    FlutterSecureStorage.setMockInitialValues({'access_token': 'mock_token'});
    controller = AppController();
    await controller.bootstrap();
  });

  tearDown(() {
    controller.stopTrackingPoll();
    controller.dispose();
  });

  group('NotificationsPage Comprehensive Coverage Suite', () {
    testWidgets('1. Old NotificationsPage renders all filter chips and filters notifications correctly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      controller.addNotification(
        AppNotification(
          id: 'n_bus',
          title: 'اقتراب الحافلة',
          titleEn: 'Bus Approaching',
          body: 'الحافلة على بعد 5 دقائق',
          bodyEn: 'Bus is 5 mins away',
          type: NotificationType.approach,
          time: DateTime.now(),
          read: false,
        ),
      );

      controller.addNotification(
        AppNotification(
          id: 'n_student',
          title: 'صعود الطالب',
          titleEn: 'Student Boarded',
          body: 'صعد عمر الحافلة',
          bodyEn: 'Omar boarded the bus',
          type: NotificationType.checkIn,
          time: DateTime.now().subtract(const Duration(minutes: 10)),
          read: true,
        ),
      );

      controller.addNotification(
        AppNotification(
          id: 'n_school',
          title: 'إعلان المدرسة',
          titleEn: 'School Alert',
          body: 'غداً عطلة رسمية',
          bodyEn: 'Tomorrow is holiday',
          type: NotificationType.schoolAlert,
          time: DateTime.now().subtract(const Duration(hours: 1)),
          read: false,
        ),
      );

      controller.addNotification(
        AppNotification(
          id: 'n_supervisor',
          title: 'رسالة المشرف',
          titleEn: 'Supervisor Message',
          body: 'يرجى تجهيز الطالب',
          bodyEn: 'Please prepare the student',
          type: NotificationType.supervisorMessage,
          time: DateTime.now().subtract(const Duration(hours: 2)),
          read: true,
          data: {'conversation_id': '10', 'sender_name': 'المشرف علي'},
        ),
      );

      await tester.pumpWidget(_wrapWithAppScope(child: const old_notifications.NotificationsPage(), controller: controller));
      for (int i = 0; i < 3; i++) await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(old_notifications.NotificationsPage), findsOneWidget);

      // Verify all filter chips exist and tap them
      final chips = find.byType(FilterChip);
      expect(chips, findsNWidgets(5));

      // Tap Bus filter
      await tester.tap(chips.at(1));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('اقتراب الحافلة'), findsOneWidget);

      // Tap Student filter
      await tester.tap(chips.at(2));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('صعود الطالب'), findsOneWidget);

      // Tap School filter
      await tester.tap(chips.at(3));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('إعلان المدرسة'), findsOneWidget);

      // Tap Supervisor filter
      await tester.tap(chips.at(4));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('رسالة المشرف'), findsOneWidget);

      // Tap All filter
      await tester.tap(chips.at(0));
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Mark All Read button if available
      final markAllBtn = find.text('تحديد الكل كمقروء');
      if (markAllBtn.evaluate().isNotEmpty) {
        await tester.tap(markAllBtn);
        await tester.pump(const Duration(milliseconds: 200));
      }
    });

    testWidgets('2. Old NotificationsPage item tap opens detail dialog and chat page', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      controller.addNotification(
        AppNotification(
          id: 'n_dialog',
          title: 'تنبيه هام',
          titleEn: 'Important Alert',
          body: 'يرجى الحضور للاجتماع',
          bodyEn: 'Please attend the meeting',
          type: NotificationType.schoolAlert,
          time: DateTime.now(),
          read: false,
        ),
      );

      await tester.pumpWidget(_wrapWithAppScope(child: const old_notifications.NotificationsPage(), controller: controller));
      for (int i = 0; i < 3; i++) await tester.pump(const Duration(milliseconds: 200));

      final item = find.text('تنبيه هام');
      expect(item, findsOneWidget);
      await tester.tap(item);
      await tester.pumpAndSettle();

      // Dialog should be displayed
      expect(find.byType(AlertDialog), findsOneWidget);
      final closeButton = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextButton));
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton.first);
        await tester.pumpAndSettle();
      }
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('3. Old NotificationsPage pendingNotificationId triggers automatic handler', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      controller.addNotification(
        AppNotification(
          id: 'p_notif_1',
          title: 'إشعار معلق',
          titleEn: 'Pending Alert',
          body: 'محتوى الإشعار المعلق',
          bodyEn: 'Pending body',
          type: NotificationType.schoolAlert,
          time: DateTime.now(),
          read: false,
        ),
      );

      controller.setPendingNotificationId('p_notif_1');

      await tester.pumpWidget(_wrapWithAppScope(child: const old_notifications.NotificationsPage(), controller: controller));
      for (int i = 0; i < 4; i++) await tester.pump(const Duration(milliseconds: 200));

      // AlertDialog should be displayed automatically
      expect(find.byType(AlertDialog), findsOneWidget);
      final closeBtn = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextButton));
      if (closeBtn.evaluate().isNotEmpty) {
        await tester.tap(closeBtn.first);
        await tester.pumpAndSettle();
      }
      expect(controller.pendingNotificationId, isNull);
    });

    testWidgets('4. New NotificationsPage renders list and handles delete sweep dialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      controller.addNotification(
        AppNotification(
          id: 'new_n_1',
          title: 'إشعار جديد 1',
          titleEn: 'New Alert 1',
          body: 'تفاصيل الإشعار الجديد',
          bodyEn: 'New details',
          type: NotificationType.schoolAlert,
          time: DateTime.now(),
          read: false,
        ),
      );

      await tester.pumpWidget(_wrapWithAppScope(child: const new_notifications.NotificationsPage(), controller: controller));
      for (int i = 0; i < 3; i++) await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(new_notifications.NotificationsPage), findsOneWidget);
      expect(find.text('إشعار جديد 1'), findsOneWidget);

      // Tap delete sweep icon
      final deleteIcon = find.byIcon(Icons.delete_sweep_outlined);
      expect(deleteIcon, findsOneWidget);
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      // Tap cancel first
      final cancelBtn = find.text('إلغاء');
      if (cancelBtn.evaluate().isNotEmpty) {
        await tester.tap(cancelBtn);
        await tester.pumpAndSettle();
      }
      expect(find.byType(AlertDialog), findsNothing);

      // Tap delete sweep again and confirm
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();
      final confirmButtons = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextButton));
      if (confirmButtons.evaluate().length >= 2) {
        await tester.tap(confirmButtons.last);
        await tester.pumpAndSettle();
      }
      expect(controller.notifications, isEmpty);
    });

    testWidgets('5. New NotificationsPage handles chat notification tap', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      controller.addNotification(
        AppNotification(
          id: 'chat_n_1',
          title: 'رسالة مشرف',
          titleEn: 'Supervisor Message',
          body: 'مرحبا بكم',
          bodyEn: 'Hello',
          type: NotificationType.supervisorMessage,
          time: DateTime.now(),
          read: false,
          data: {
            'conversation_id': '105',
            'sender_name': 'أحمد المشرف',
            'sender_role': 'supervisor',
          },
        ),
      );

      await tester.pumpWidget(_wrapWithAppScope(child: const new_notifications.NotificationsPage(), controller: controller));
      for (int i = 0; i < 3; i++) await tester.pump(const Duration(milliseconds: 200));

      final chatItem = find.text('رسالة مشرف');
      expect(chatItem, findsOneWidget);
      await tester.tap(chatItem);
      await tester.pumpAndSettle();

      // Controller should have marked it read
      expect(controller.notifications.first.read, isTrue);
    });
  });
}
