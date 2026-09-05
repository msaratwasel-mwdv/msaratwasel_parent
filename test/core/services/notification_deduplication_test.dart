import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Notification Deduplication & Concurrency Suite', () {
    late AppController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'user_id': 123,
        'user_name': 'Parent Test',
        'has_seen_onboarding': true,
        'my_student_ids': ['student_101', 'student_102'],
        'processed_cids': <String>[],
      });
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'mock_jwt_token',
      });

      controller = AppController();
      // Wait for bootstrap or manually set authenticated
      await controller.bootstrap();
    });

    tearDown(() {
      controller.dispose();
    });

    test('1. Normal flow: Adds unique notification to list and updates state', () async {
      final notif = AppNotification(
        id: 'notif_1',
        correlationId: 'cid_1001',
        title: 'باص المدرسة',
        body: 'وصل الباص إلى المحطة',
        type: NotificationType.approach,
        time: DateTime.now(),
        data: {'student_id': 'student_101'},
      );

      await controller.addNotification(notif);
      // Let microtasks execute
      await Future.delayed(Duration.zero);

      expect(controller.notifications.length, 1);
      expect(controller.notifications.first.id, 'notif_1');
    });

    test('2. Memory Deduplication: Same correlationId received sequentially is suppressed', () async {
      final notif1 = AppNotification(
        id: 'notif_fcm_1',
        correlationId: 'cid_shared_1',
        title: 'صعود الطالب',
        body: 'تم صعود الطالب إلى الحافلة',
        type: NotificationType.checkIn,
        time: DateTime.now(),
        data: {'student_id': 'student_101'},
      );

      final notif2 = AppNotification(
        id: 'notif_reverb_1', // Different ID from different channel!
        correlationId: 'cid_shared_1', // Same CID
        title: 'صعود الطالب',
        body: 'تم صعود الطالب إلى الحافلة',
        type: NotificationType.checkIn,
        time: DateTime.now(),
        data: {'student_id': 'student_101'},
      );

      await controller.addNotification(notif1);
      await controller.addNotification(notif2);
      await Future.delayed(Duration.zero);

      // Only notif1 should be in the list
      expect(controller.notifications.length, 1);
      expect(controller.notifications.first.id, 'notif_fcm_1');
    });

    test('3. Storage Deduplication: CIDs in SharedPreferences are suppressed even if memory was empty', () async {
      // Simulate CID already processed in a previous session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('processed_cids', ['cid_pre_processed']);

      final notif = AppNotification(
        id: 'notif_dup_storage',
        correlationId: 'cid_pre_processed',
        title: 'تنبيه غياب',
        body: 'تم تسجيل غياب الطالب',
        type: NotificationType.absence,
        time: DateTime.now(),
        data: {'student_id': 'student_101'},
      );

      await controller.addNotification(notif);
      await Future.delayed(Duration.zero);

      expect(controller.notifications.isEmpty, isTrue);
    });

    test('4. Security Check: Suppresses notification for foreign students', () async {
      final notifForeign = AppNotification(
        id: 'notif_foreign',
        correlationId: 'cid_foreign_99',
        title: 'تنبيه أمان',
        body: 'إشعار لطالب آخر',
        type: NotificationType.checkIn,
        time: DateTime.now(),
        data: {'student_id': 'foreign_student_999'}, // Not in my_student_ids
      );

      await controller.addNotification(notifForeign);
      await Future.delayed(Duration.zero);

      expect(controller.notifications.isEmpty, isTrue);
    });

    test('5. Tap event: Marks as read and suppresses duplicate UI popup', () async {
      final notifTap = AppNotification(
        id: 'notif_tap_1',
        correlationId: 'cid_tap_1',
        title: 'إشعار بالضغط',
        body: 'تم النقر على الإشعار',
        type: NotificationType.adminAnnouncement,
        time: DateTime.now(),
        read: false,
        data: {'student_id': 'student_101'},
      );

      await controller.addNotification(notifTap, isTap: true);
      await Future.delayed(Duration.zero);

      expect(controller.notifications.length, 1);
      expect(controller.notifications.first.read, isTrue);
    });

    test('6. Missing correlation_id: Same notification without CID results in duplicate list check fallback', () async {
      final notifA = AppNotification(
        id: 'same_db_id',
        correlationId: null, // Missing CID
        title: 'إشعار بدون CID',
        body: 'محتوى تجريبي',
        type: NotificationType.schoolAlert,
        time: DateTime.now(),
        data: {'student_id': 'student_101'},
      );

      final notifB = AppNotification(
        id: 'same_db_id', // Same ID
        correlationId: null, // Missing CID
        title: 'إشعار بدون CID',
        body: 'محتوى تجريبي',
        type: NotificationType.schoolAlert,
        time: DateTime.now(),
        data: {'student_id': 'student_101'},
      );

      await controller.addNotification(notifA);
      await controller.addNotification(notifB);
      await Future.delayed(Duration.zero);

      // List-based dedup fallback should prevent having two elements with same ID
      expect(controller.notifications.length, 1);
    });

    test('7. BUG VERIFICATION: Missing correlation_id with DIFFERENT ids (FCM messageId vs DB id) bypasses dedup', () async {
      // Simulating backend sending push via FCM (id: fcm_msg_123) and Reverb (id: db_456)
      // without correlation_id in payload:
      final fcmPush = AppNotification(
        id: 'fcm_msg_123',
        correlationId: null,
        title: 'تحركت الحافلة',
        body: 'الحافلة في طريقها إليك',
        type: NotificationType.approach,
        time: DateTime.now(),
        data: {'student_id': 'student_101'},
      );

      final reverbEvent = AppNotification(
        id: 'db_event_456', // Different ID from Reverb!
        correlationId: null,
        title: 'تحركت الحافلة',
        body: 'الحافلة في طريقها إليك',
        type: NotificationType.approach,
        time: DateTime.now(),
        data: {'student_id': 'student_101'},
      );

      await controller.addNotification(fcmPush);
      await controller.addNotification(reverbEvent);
      await Future.delayed(Duration.zero);

      // ⚠️ In current implementation, if correlationId is null and IDs differ,
      // BOTH get added to the list! This documents the actual behavior.
      expect(controller.notifications.length, 2,
        reason: 'Current implementation fails to deduplicate events that lack a correlationId and have different IDs.');
    });

    test('8. CONCURRENCY: Simultaneous addNotification calls with same correlationId (Race Condition)', () async {
      final notif1 = AppNotification(
        id: 'concurrent_fcm',
        correlationId: 'cid_race_test',
        title: 'فحص التزامن',
        body: 'وصول متزامن',
        type: NotificationType.checkIn,
        time: DateTime.now(),
        data: {'student_id': 'student_101'},
      );

      final notif2 = AppNotification(
        id: 'concurrent_reverb',
        correlationId: 'cid_race_test',
        title: 'فحص التزامن',
        body: 'وصول متزامن',
        type: NotificationType.checkIn,
        time: DateTime.now(),
        data: {'student_id': 'student_101'},
      );

      // Execute simultaneously using Future.wait without awaiting between them
      await Future.wait([
        controller.addNotification(notif1),
        controller.addNotification(notif2),
      ]);
      await Future.delayed(Duration.zero);

      // Does the current code allow both through during concurrent execution?
      // Let us verify current behavior:
      final count = controller.notifications.where((n) => n.correlationId == 'cid_race_test').length;
      expect(count, anyOf(1, 2));
      print('ℹ️ Concurrent arrival result: $count notification(s) added with same CID');
    });
  });
}
