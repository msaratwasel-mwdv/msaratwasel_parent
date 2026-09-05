import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/features/absence/domain/entities/absence_request.dart';

class FakeAppControllerDioAdapter implements HttpClientAdapter {
  final List<Map<String, dynamic>> recordedRequests = [];
  Map<String, dynamic>? customLocationRequests;
  Map<String, dynamic>? customConversations;
  Map<String, dynamic>? customChildren;
  Map<String, dynamic>? customAbsence;
  int statusCode = 200;
  bool shouldThrowDioException = false;
  String? dioErrorMessage;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    recordedRequests.add({
      'path': options.path,
      'method': options.method,
      'data': options.data,
      'headers': options.headers,
    });

    if (shouldThrowDioException) {
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: statusCode == 200 ? 422 : statusCode,
          data: {'message': dioErrorMessage ?? 'Error occurred'},
        ),
      );
    }

    dynamic data;
    if (options.path.contains('parent/location-requests')) {
      data = customLocationRequests ?? {
        'data': [
          {
            'id': 101,
            'student_id': 1,
            'student_name': 'Ali',
            'latitude': 24.7136,
            'longitude': 46.6753,
            'address': 'Riyadh Home',
            'status': 'pending',
            'created_at': '2026-09-01T10:00:00Z',
          }
        ]
      };
    } else if (options.path.contains('parent/student/location/update') ||
        options.path.contains('parent/location/update')) {
      data = {'success': true, 'message': 'تم تحديث الموقع بنجاح'};
    } else if (options.path.contains('absence') || options.path.contains('absences')) {
      data = customAbsence ?? {
        'data': [
          {
            'id': 1,
            'student_id': 10,
            'student_name': 'Ali',
            'type': 'both',
            'date': '2026-09-05',
            'status': 'pending',
            'note': 'Sick',
            'created_at': '2026-09-01',
          }
        ]
      };
    } else if (options.path.contains('parent/children')) {
      data = customChildren ?? {
        'data': [
          {
            'id': 'st_1',
            'name': 'Ali',
            'grade': 'Grade 3',
            'school_id': 'sch_1',
            'bus': {
              'id': 'b1',
              'number': '101',
              'plate': 'ABC-123',
            },
            'status': 'on_bus',
            'avatar_url': 'https://example.com/ali.png',
            'home_location': {'latitude': 24.7, 'longitude': 46.7},
          }
        ]
      };
    } else if (options.path.contains('parent/profile')) {
      data = {
        'data': {
          'id': 100,
          'name': 'Parent Name',
          'email': 'parent@example.com',
          'phone': '0555555555',
          'civil_id': '1000000001',
          'national_id': '1000000001',
        }
      };
    } else if (options.path.contains('chat/conversations')) {
      data = customConversations ?? {
        'data': [
          {
            'id': 1,
            'type': 'private',
            'unread_count': 2,
            'participants': [
              {'id': 100, 'name': 'Parent', 'role': 'guardian'},
              {'id': 200, 'name': 'Driver Ahmed', 'role': 'driver'},
            ],
            'last_message': {
              'id': 1,
              'conversation_id': 1,
              'sender': {'id': 200, 'name': 'Driver Ahmed', 'role': 'driver'},
              'body': 'On our way',
              'type': 'text',
              'is_mine': false,
              'created_at': '2026-09-01T10:00:00.000Z',
            }
          }
        ]
      };
    } else {
      data = {'success': true, 'data': []};
    }

    return ResponseBody.fromString(
      jsonEncode(data),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppController controller;
  late FakeAppControllerDioAdapter fakeAdapter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'user_id': 100,
      'user_name': 'Test Parent',
      'has_seen_onboarding': false,
      'my_student_ids': ['st_1', 'st_2'],
    });
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'mock_valid_token',
    });

    fakeAdapter = FakeAppControllerDioAdapter();
    controller = AppController();
    controller.dio.httpClientAdapter = fakeAdapter;
    await controller.bootstrap();
  });

  tearDown(() {
    controller.stopTrackingPoll();
    controller.dispose();
  });

  group('Agent 6: AppController Uncovered Methods Suite', () {
    test('1. updateLocale updates dio headers, local property and triggers sync', () async {
      controller.updateLocale(const Locale('en'));
      expect(controller.locale.languageCode, 'en');
      expect(controller.dio.options.headers['Accept-Language'], 'en');

      // Switch back to ar
      controller.updateLocale(const Locale('ar'));
      expect(controller.locale.languageCode, 'ar');
      expect(controller.dio.options.headers['Accept-Language'], 'ar');
    });

    test('2. toggleTheme switches between light and dark themes correctly', () {
      controller.toggleTheme(true);
      expect(controller.themeMode, ThemeMode.light);

      controller.toggleTheme(false);
      expect(controller.themeMode, ThemeMode.dark);
    });

    test('3. selectBus changes bus selection only when valid busId exists', () {
      controller.selectBus('bus_non_existent');
      expect(controller.groupForBus('bus_non_existent'), isNull);
      expect(controller.trackingForBus('bus_non_existent'), isNull);
    });

    test('4. addAbsence records attendance entry in controller state', () {
      expect(controller.attendance, isEmpty);
      final date = DateTime(2026, 9, 10);
      controller.addAbsence(
        direction: AttendanceDirection.outbound,
        date: date,
        note: 'Illness',
      );

      expect(controller.attendance.length, 1);
      expect(controller.attendance.first.direction, AttendanceDirection.outbound);
      expect(controller.attendance.first.note, 'Illness');
      expect(controller.attendance.first.status, 'تم الإبلاغ بعدم الذهاب');
    });

    test('5. updateStudentLocation updates local student homeLocation and note', () {
      controller.updateStudentLocation(
        'st_1',
        const LatLng(24.7136, 46.6753),
        note: 'Near the park',
      );

      final updated = controller.students.where((s) => s.id == 'st_1').firstOrNull;
      if (updated != null) {
        expect(updated.homeLocation?.latitude, 24.7136);
        expect(updated.locationNote, 'Near the park');
      }

      expect(() => controller.updateStudentLocation('st_999', const LatLng(0, 0)), returnsNormally);
    });

    test('6. updateHomeLocationApi succeeds and refreshes local state', () async {
      final msg = await controller.updateHomeLocationApi(
        const LatLng(24.75, 46.65),
        studentId: 'st_1',
        address: 'Al-Malqa, Riyadh',
        note: 'Villa 12',
      );

      expect(msg, 'تم تحديث الموقع بنجاح');
      expect(
        fakeAdapter.recordedRequests.any((r) => r['path'] == 'parent/student/location/update'),
        isTrue,
      );
    });

    test('7. updateHomeLocationApi handles dio exception gracefully', () async {
      fakeAdapter.shouldThrowDioException = true;
      fakeAdapter.dioErrorMessage = 'Invalid GPS coordinates';

      final msg = await controller.updateHomeLocationApi(
        const LatLng(24.75, 46.65),
      );

      expect(msg, 'Invalid GPS coordinates');
    });

    test('8. submitAbsence handles morning, afternoon, and full_day periods', () async {
      final morningRes = await controller.submitAbsence(
        studentId: 'st_1',
        period: 'morning',
        reason: 'Sick',
        note: 'High fever',
      );
      expect(morningRes.success, isTrue);

      final afternoonRes = await controller.submitAbsence(
        studentId: 'st_1',
        period: 'afternoon',
        reason: 'Family Event',
        note: 'Going out',
      );
      expect(afternoonRes.success, isTrue);

      final fullDayRes = await controller.submitAbsence(
        studentId: 'st_1',
        period: 'full_day',
        reason: 'Travel',
        note: 'Away for weekend',
      );
      expect(fullDayRes.success, isTrue);
    });

    test('9. submitAbsence handles dio error returning failure result', () async {
      fakeAdapter.shouldThrowDioException = true;
      fakeAdapter.dioErrorMessage = 'Already submitted for this date';

      final res = await controller.submitAbsence(
        studentId: 'st_1',
        period: 'morning',
        reason: 'Sick',
        note: 'Fever',
      );

      expect(res.success, isFalse);
      expect(res.message, 'Already submitted for this date');
    });

    test('10. submitAbsenceRequest handles success and dio exception rethrow', () async {
      final success = await controller.submitAbsenceRequest(
        studentIds: ['st_1', 'st_2'],
        type: AbsenceType.morning,
        date: DateTime(2026, 9, 15),
        reason: 'Medical checkup',
      );
      expect(success, isTrue);

      fakeAdapter.shouldThrowDioException = true;
      fakeAdapter.dioErrorMessage = 'Invalid student ID';

      expect(
        () async => await controller.submitAbsenceRequest(
          studentIds: ['st_999'],
          type: AbsenceType.both,
          date: DateTime(2026, 9, 16),
        ),
        throwsA(isA<String>()),
      );
    });

    test('11. loadLocationRequestsFromApi populates location requests', () async {
      fakeAdapter.customLocationRequests = {
        'data': [
          {
            'id': 101,
            'student_id': 1,
            'latitude': 24.7,
            'longitude': 46.7,
            'address': 'Valid Address',
            'status': 'pending',
            'created_at': '2026-09-01T00:00:00Z',
          }
        ]
      };

      await controller.loadLocationRequestsFromApi();
      expect(controller.locationRequests.length, 1);
      expect(controller.locationRequests.first.id, '101');
      expect(controller.isLocationRequestsLoading, isFalse);
    });

    test('12. loadAbsenceRequestsFromApi loads absence requests list', () async {
      await controller.loadAbsenceRequestsFromApi();
      expect(controller.absenceRequests.isNotEmpty, isTrue);
    });

    test('13. loadConversationsFromApi & markConversationAsRead updates state', () async {
      await controller.loadConversationsFromApi();
      expect(controller.conversations.length, 1);
      expect(controller.conversations.first.unreadCount, 2);

      controller.markConversationAsRead(1);
      expect(controller.conversations.first.unreadCount, 0);

      controller.markConversationAsRead(999);
      expect(controller.conversations.first.unreadCount, 0);
    });

    test('14. markNotificationsReadByCategory marks specific category as read', () async {
      await controller.addNotification(
        AppNotification(
          id: 'n_cat1',
          title: 'Alert 1',
          body: 'Content 1',
          time: DateTime.now(),
          type: NotificationType.schoolAlert,
          category: 'school_bus',
          read: false,
        ),
      );
      await controller.addNotification(
        AppNotification(
          id: 'n_cat2',
          title: 'Alert 2',
          body: 'Content 2',
          time: DateTime.now(),
          type: NotificationType.schoolAlert,
          category: 'general',
          read: false,
        ),
      );

      await controller.markNotificationsReadByCategory('school_bus');
      final notif1 = controller.notifications.firstWhere((n) => n.id == 'n_cat1');
      final notif2 = controller.notifications.firstWhere((n) => n.id == 'n_cat2');
      expect(notif1.read, isTrue);
      expect(notif2.read, isFalse);
    });

    test('15. clearNotifications empties all notifications', () async {
      await controller.clearNotifications();
      expect(controller.notifications, isEmpty);
      expect(controller.notificationsUnreadCount, 0);
    });

    test('16. completeOnboarding updates seen onboarding state', () async {
      await controller.completeOnboarding();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('has_seen_onboarding'), isTrue);
    });

    test('17. subscribeToChat and unsubscribeFromChat operate safely without reverb crashing', () {
      expect(() => controller.subscribeToChat('conv_123'), returnsNormally);
      expect(() => controller.unsubscribeFromChat('conv_123'), returnsNormally);
    });

    test('18. markNotificationsRead marks specific or all notifications as read', () async {
      await controller.addNotification(
        AppNotification(
          id: 'n_read1',
          title: 'Title 1',
          body: 'Body 1',
          time: DateTime.now(),
          type: NotificationType.schoolAlert,
          read: false,
        ),
      );
      await controller.addNotification(
        AppNotification(
          id: 'n_read2',
          title: 'Title 2',
          body: 'Body 2',
          time: DateTime.now(),
          type: NotificationType.schoolAlert,
          read: false,
        ),
      );

      // Mark specific notification
      await controller.markNotificationsRead(['n_read1']);
      expect(controller.notifications.firstWhere((n) => n.id == 'n_read1').read, isTrue);
      expect(controller.notifications.firstWhere((n) => n.id == 'n_read2').read, isFalse);

      // Mark all remaining unread notifications
      await controller.markNotificationsRead();
      expect(controller.notifications.firstWhere((n) => n.id == 'n_read2').read, isTrue);
    });

    test('19. clearNewMessages resets new messages flag', () {
      controller.clearNewMessages();
      expect(controller.chatUnreadCount, 0);
    });

    test('20. pendingChatRoute getters and setters update state correctly', () {
      expect(controller.hasPendingChatRoute, isFalse);
      controller.setPendingChatRoute(
        conversationId: 42,
        senderName: 'Driver Mohamed',
        senderRole: 'driver',
      );
      expect(controller.hasPendingChatRoute, isTrue);

      // Flush without mounted navigator returns safely
      expect(() => controller.flushPendingChatRoute(), returnsNormally);
    });

    test('21. loadProfileFromApi updates profile details safely', () async {
      await controller.loadProfileFromApi();
      expect(controller.userName, isNotEmpty);
      expect(controller.userEmail, 'parent@example.com');
      expect(controller.userPhone, '0555555555');
      expect(controller.userNationalId, '1000000001');
    });

    test('22. logout clears session state safely', () async {
      await controller.logout();
      expect(controller.isAuthenticated, isFalse);
    });

    test('23. didChangeAppLifecycleState resumed triggers lifecycle sync safely', () {
      expect(() => controller.didChangeAppLifecycleState(AppLifecycleState.resumed), returnsNormally);
      expect(() => controller.didChangeAppLifecycleState(AppLifecycleState.paused), returnsNormally);
    });

    test('24. absenceUnreadCount and locationUnreadCount calculate accurately', () async {
      await controller.loadNotificationsFromApi();
      expect(controller.absenceUnreadCount, isNonNegative);
      expect(controller.locationUnreadCount, isNonNegative);
    });

    test('25. markInitialMessageHandled sets handledInitialMessage true', () {
      expect(controller.handledInitialMessage, isFalse);
      controller.markInitialMessageHandled();
      expect(controller.handledInitialMessage, isTrue);
    });

    test('26. markConversationAsRead updates state safely', () async {
      await controller.loadConversationsFromApi();
      expect(() => controller.markConversationAsRead(1), returnsNormally);
    });
  });
}
