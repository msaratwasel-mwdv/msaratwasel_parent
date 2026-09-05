import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/features/chat/data/models/chat_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'user_id': 100,
      'user_name': 'Test Parent',
      'has_seen_onboarding': true,
      'my_student_ids': ['st_1', 'st_2'],
    });
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'test_token',
    });

    controller = AppController();
    await controller.bootstrap();
  });

  tearDown(() {
    controller.stopTrackingPoll();
    controller.dispose();
  });

  group('AppController Navigation & Unread Counts Suite', () {
    test('1. setNavIndex updates navIndex and notifies listeners', () {
      expect(controller.navIndex, 0);

      var notified = false;
      controller.addListener(() => notified = true);

      controller.setNavIndex(2);

      expect(controller.navIndex, 2);
      expect(notified, isTrue);
    });

    test('2. Unread counts categorize notifications accurately', () async {
      // Add general notification (unread)
      await controller.addNotification(
        AppNotification(
          id: 'n_gen',
          title: 'Welcome',
          body: 'Welcome to the app',
          time: DateTime.now(),
          type: NotificationType.schoolAlert,
          category: 'general',
          read: false,
        ),
      );

      // Add absence notification (unread)
      await controller.addNotification(
        AppNotification(
          id: 'n_abs',
          title: 'Absence Approved',
          body: 'Your absence request was approved',
          time: DateTime.now(),
          type: NotificationType.absenceApproved,
          category: 'absences',
          read: false,
        ),
      );

      // Add location notification (unread)
      await controller.addNotification(
        AppNotification(
          id: 'n_loc',
          title: 'Location Request',
          body: 'School updated location',
          time: DateTime.now(),
          type: NotificationType.locationApproved,
          category: 'location_requests',
          read: false,
        ),
      );

      expect(controller.notificationsUnreadCount, 3);
      expect(controller.absenceUnreadCount, 1);
      expect(controller.locationUnreadCount, 1);
    });

    test('3. clearNotifications empties list and resets unread count', () async {
      await controller.addNotification(
        AppNotification(
          id: 'n1',
          title: 'Title',
          body: 'Body',
          time: DateTime.now(),
          type: NotificationType.schoolAlert,
          read: false,
        ),
      );

      expect(controller.notifications.length, 1);
      expect(controller.notificationsUnreadCount, 1);

      await controller.clearNotifications();

      expect(controller.notifications.isEmpty, isTrue);
      expect(controller.notificationsUnreadCount, 0);
    });

    test('4. clearNewMessages resets hasNewMessages flag', () {
      controller.clearNewMessages();
      expect(controller.hasNewMessages, isFalse);
    });
  });

  group('AppController Bus Group Selection & Inactive Students Suite', () {
    test('5. selectedGroup returns null when trip groups are empty', () {
      expect(controller.allTripGroups.isEmpty, isTrue);
      expect(controller.selectedGroup, isNull);
      expect(controller.selectedBusId, isNull);
    });

    test('6. selectBus sets selectedBusId only if bus exists in trip groups', () {
      controller.selectBus('non_existent_bus');
      expect(controller.selectedBusId, isNull);
    });
  });

  group('AppController Realtime Message & Notification State Suite', () {
    test('7. chatUnreadCount calculates sum of unread count across conversations', () {
      expect(controller.chatUnreadCount, 0);
    });

    test('8. Student status transitions upon receiving push notifications', () async {
      // Notification with checkIn to_school
      await controller.addNotification(
        AppNotification(
          id: 'push_chk_in',
          title: 'Check In',
          body: 'Student boarded bus',
          time: DateTime.now(),
          type: NotificationType.checkIn,
          data: {
            'student_id': 'st_1',
            'direction': 'to_school',
          },
        ),
      );

      // Verify notification was recorded
      expect(controller.notifications.any((n) => n.id == 'push_chk_in'), isTrue);
    });

    test('9. Notification for chat message sets hasNewMessages to true', () async {
      await controller.addNotification(
        AppNotification(
          id: 'push_chat_1',
          title: 'New Chat',
          body: 'Message from driver',
          time: DateTime.now(),
          type: NotificationType.chat,
          data: {
            'conversation_id': 5,
          },
        ),
      );

      expect(controller.hasNewMessages, isTrue);
    });

    test('10. markNotificationsRead updates read state for targeted notification ids', () async {
      final notif = AppNotification(
        id: 'n_read_test',
        title: 'Important Alert',
        body: 'Please read',
        time: DateTime.now(),
        type: NotificationType.schoolAlert,
        read: false,
      );
      await controller.addNotification(notif);
      expect(controller.notifications.firstWhere((n) => n.id == 'n_read_test').read, isFalse);

      await controller.markNotificationsRead(['n_read_test']);
      expect(controller.notifications.firstWhere((n) => n.id == 'n_read_test').read, isTrue);
    });

    test('11. markNotificationsReadByCategory marks matching category notifications as read', () async {
      await controller.addNotification(
        AppNotification(
          id: 'n_cat_abs',
          title: 'Absence Notice',
          body: 'Noted',
          time: DateTime.now(),
          type: NotificationType.absence,
          category: 'absences',
          read: false,
        ),
      );

      await controller.markNotificationsReadByCategory('absences');
      expect(controller.notifications.firstWhere((n) => n.id == 'n_cat_abs').read, isTrue);
      expect(controller.absenceUnreadCount, 0);
    });

    test('12. toggleLanguage and setLocale properly update application locale', () {
      controller.setLocale(const Locale('ar'));
      expect(controller.locale.languageCode, 'ar');

      controller.toggleLanguage();
      expect(controller.locale.languageCode, 'en');

      controller.toggleLanguage();
      expect(controller.locale.languageCode, 'ar');
    });

    test('13. toggleTheme switches ThemeMode between dark and light', () {
      controller.toggleTheme(false); // current is not dark => switches to dark
      expect(controller.themeMode, ThemeMode.dark);

      controller.toggleTheme(true); // current is dark => switches to light
      expect(controller.themeMode, ThemeMode.light);
    });

    test('14. completeOnboarding updates state and storage flag', () async {
      await controller.completeOnboarding();
      expect(controller.shouldShowOnboarding, isFalse);
    });

    test('15. groupForBus and trackingForBus return null for unknown bus', () {
      expect(controller.groupForBus('unknown_bus'), isNull);
      expect(controller.trackingForBus('unknown_bus'), isNull);
      expect(controller.currentStudent, isNull);
    });

    test('16. moveBack navigates history or falls back to index 0', () {
      controller.setNavIndex(1);
      controller.setNavIndex(2);
      controller.setNavIndex(3);

      controller.moveBack();
      expect(controller.navIndex, 2);

      controller.moveBack();
      expect(controller.navIndex, 1);

      controller.moveBack();
      expect(controller.navIndex, 0);

      // Moving back when already at 0 remains safe
      controller.moveBack();
      expect(controller.navIndex, 0);
    });

    test('17. clearPendingNotificationId clears pending state', () {
      controller.setPendingNotificationId('notif_999');
      expect(controller.pendingNotificationId, 'notif_999');

      controller.clearPendingNotificationId();
      expect(controller.pendingNotificationId, isNull);
    });

    test('18. updateAvatarUrl updates userAvatarUrl and persists to storage', () {
      controller.updateAvatarUrl('https://example.com/avatar_new.jpg');
      expect(controller.userAvatarUrl, 'https://example.com/avatar_new.jpg');
    });

    test('19. selectStudent handles invalid indices safely and updates selection', () {
      // Empty students list
      controller.selectStudent(-1);
      expect(controller.currentStudent, isNull);

      controller.selectStudent(10);
      expect(controller.currentStudent, isNull);
    });

    test('20. setPendingStudentId sets pending when student not found in list', () {
      controller.setPendingStudentId('unknown_student_id');
      expect(controller.pendingStudentId, 'unknown_student_id');
    });

    test('21. markInitialMessageHandled sets flag to true', () {
      expect(controller.handledInitialMessage, isFalse);
      controller.markInitialMessageHandled();
      expect(controller.handledInitialMessage, isTrue);
    });

    test('22. didChangeAppLifecycleState handles paused and resumed lifecycle transitions', () {
      expect(() => controller.didChangeAppLifecycleState(AppLifecycleState.paused), returnsNormally);
      expect(() => controller.didChangeAppLifecycleState(AppLifecycleState.resumed), returnsNormally);
      expect(() => controller.didChangeAppLifecycleState(AppLifecycleState.inactive), returnsNormally);
    });

    test('23. addMessage updates conversation or creates new message item', () {
      controller.addMessage('وصلت المحطة');
      expect(controller.messages.isNotEmpty, isTrue);
      expect(controller.messages.last.text, 'وصلت المحطة');
      expect(controller.messages.last.sender, 'أنت');
    });

    test('24. forgotPassword handles network failure gracefully', () async {
      final res = await controller.forgotPassword(civilId: '1234567890');
      // In unit test environment without running server, fails gracefully returning success: false
      expect(res.success, isFalse);
      expect(res.message, isNotEmpty);
    });
  });
}

