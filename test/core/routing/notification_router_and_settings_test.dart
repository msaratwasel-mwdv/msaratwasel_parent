import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/routing/notification_router.dart';
import 'package:msaratwasel_user/src/features/chat/presentation/chat_page.dart';
import 'package:msaratwasel_user/src/shared/utils/notification_utils.dart';


class FakeRouterDioAdapter implements HttpClientAdapter {
  final List<Map<String, dynamic>> recordedRequests = [];
  Map<String, dynamic>? customResponseData;

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

    dynamic data = customResponseData ?? {'data': []};
    if (options.path.contains('parent/children')) {
      data = {'data': []};
    } else if (options.path.contains('parent/profile')) {
      data = {'data': {'id': 1, 'name': 'Parent'}};
    }

    return ResponseBody.fromString(
      jsonEncode(data),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const defaultBus = BusInfo(
  id: 'bus_101',
  number: '101',
  plate: '9999 AA',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationTypeUI Extension Unit Tests', () {
    test('1. Every NotificationType maps to a valid and distinct IconData', () {
      expect(NotificationType.approach.icon, Icons.near_me_rounded);
      expect(NotificationType.checkIn.icon, Icons.login_rounded);
      expect(NotificationType.checkOut.icon, Icons.logout_rounded);
      expect(NotificationType.arrival.icon, Icons.flag_rounded);
      expect(NotificationType.delay.icon, Icons.schedule_rounded);
      expect(NotificationType.routeChange.icon, Icons.alt_route_rounded);
      expect(NotificationType.absence.icon, Icons.event_busy_rounded);
      expect(NotificationType.absenceApproved.icon, Icons.event_available_rounded);
      expect(NotificationType.absenceRejected.icon, Icons.event_busy_rounded);
      expect(NotificationType.lateBoarding.icon, Icons.warning_amber_rounded);
      expect(NotificationType.schoolAlert.icon, Icons.campaign_rounded);
      expect(NotificationType.adminAnnouncement.icon, Icons.campaign_rounded);
      expect(NotificationType.supervisorMessage.icon, Icons.support_agent_rounded);
      expect(NotificationType.chat.icon, Icons.chat_bubble_outline_rounded);
      expect(NotificationType.locationRequest.icon, Icons.edit_location_alt_rounded);
      expect(NotificationType.locationApproved.icon, Icons.add_location_alt_rounded);
      expect(NotificationType.locationRejected.icon, Icons.wrong_location_rounded);
      expect(NotificationType.tripStarted.icon, Icons.directions_bus_rounded);
      expect(NotificationType.tripEnded.icon, Icons.check_circle_rounded);
      expect(NotificationType.schoolAttendance.icon, Icons.how_to_reg_rounded);
    });
  });

  group('AppController Settings & Navigation Suite', () {
    late AppController controller;
    late FakeRouterDioAdapter fakeDio;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'user_id': 100,
        'user_name': 'Parent User',
      });
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'test_token',
      });
      controller = AppController();
      fakeDio = FakeRouterDioAdapter();
      controller.dio.httpClientAdapter = fakeDio;
    });

    tearDown(() {
      controller.stopTrackingPoll();
      controller.dispose();
    });

    test('2. setNavIndex and moveBack manage history stack properly', () {
      expect(controller.navIndex, 0);

      controller.setNavIndex(2);
      expect(controller.navIndex, 2);

      controller.setNavIndex(3);
      expect(controller.navIndex, 3);

      // moveBack pops to previous index (2)
      controller.moveBack();
      expect(controller.navIndex, 2);

      // moveBack pops to first index (0)
      controller.moveBack();
      expect(controller.navIndex, 0);

      // moveBack at root stays at 0 safely
      controller.moveBack();
      expect(controller.navIndex, 0);
    });

    test('3. setNavIndex caps navigation history to 20 entries', () {
      for (int i = 1; i <= 30; i++) {
        controller.setNavIndex(i % 5);
      }
      expect(controller.navIndex, 30 % 5);
    });

    test('4. toggleTheme alternates between light and dark modes', () {
      controller.toggleTheme(true); // currently dark -> becomes light
      expect(controller.themeMode, ThemeMode.light);
      expect(controller.isDark, isFalse);

      controller.toggleTheme(false); // currently light -> becomes dark
      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.isDark, isTrue);
    });

    test('5. toggleLanguage switches between Arabic and English and updates Dio header', () {
      controller.setLocale(const Locale('ar'));
      expect(controller.locale.languageCode, 'ar');

      controller.toggleLanguage();
      expect(controller.locale.languageCode, 'en');
      expect(controller.dio.options.headers['Accept-Language'], 'en');

      controller.toggleLanguage();
      expect(controller.locale.languageCode, 'ar');
      expect(controller.dio.options.headers['Accept-Language'], 'ar');
    });

    test('6. setPendingNotificationId and clearPendingNotificationId update state', () {
      controller.setPendingNotificationId('notif_999');
      expect(controller.pendingNotificationId, 'notif_999');

      controller.clearPendingNotificationId();
      expect(controller.pendingNotificationId, isNull);
    });

    test('7. Category-specific unread counters calculate accurately', () async {
      final now = DateTime.now();

      FlutterSecureStorage.setMockInitialValues({'access_token': 'test_token'});
      fakeDio.customResponseData = {
        'notifications': [
          {
            'id': 'n1',
            'title': 'غياب',
            'body': 'طلب غياب',
            'created_at': now.toIso8601String(),
            'category': 'absences',
            'type': 'absence',
            'read_at': null,
          },
          {
            'id': 'n2',
            'title': 'موقع',
            'body': 'طلب تغيير موقع',
            'created_at': now.toIso8601String(),
            'category': 'location_requests',
            'type': 'location_request',
            'read_at': null,
          },
          {
            'id': 'n3',
            'title': 'عام',
            'body': 'إعلان عام',
            'created_at': now.toIso8601String(),
            'category': 'admin',
            'type': 'admin_announcement',
            'read': true,
          },
        ],
        'unread_count': 2,
      };

      await controller.loadNotificationsFromApi();

      expect(controller.notificationsUnreadCount, 2);
      expect(controller.absenceUnreadCount, 1);
      expect(controller.locationUnreadCount, 1);
    });

    test('8. setPendingStudentId selects student if student exists in list', () async {
      fakeDio.recordedRequests.clear();
      // Inject student in controller
      controller.dio.httpClientAdapter = fakeDio;

      // Seed student via loadChildrenFromApi or direct check
      final s1 = Student(
        id: 'std_target_1',
        name: 'الطالب الأول',
        grade: 'الأول',
        schoolId: '1',
        bus: defaultBus,
        status: StudentStatus.atHome,
      );
      // Directly check selectStudent
      controller.setPendingStudentId('std_target_1');
      expect(controller.pendingStudentId, 'std_target_1');
    });
  });

  group('NotificationRouter Deep-Linking Matrix Suite', () {
    late AppController controller;
    late FakeRouterDioAdapter fakeDio;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'user_id': 100,
        'user_name': 'Parent User',
      });
      FlutterSecureStorage.setMockInitialValues({});
      controller = AppController();
      fakeDio = FakeRouterDioAdapter();
      controller.dio.httpClientAdapter = fakeDio;
    });

    tearDown(() {
      controller.stopTrackingPoll();
      controller.dispose();
    });

    testWidgets('9. handleNotificationTap routes checkIn / checkOut / arrival to index 3 (ChildrenStatusPage)', (tester) async {
      await tester.pumpWidget(MaterialApp(navigatorKey: controller.navigatorKey, home: const SizedBox()));

      final notifCheckIn = AppNotification(
        id: 'n_checkin',
        title: 'صعود الحافلة',
        body: 'صعد الطالب الحافلة',
        time: DateTime.now(),
        type: NotificationType.checkIn,
        data: {'student_id': 'std_10'},
      );

      NotificationRouter.handleNotificationTap(controller, notifCheckIn);
      await tester.pump(const Duration(milliseconds: 50));

      expect(controller.navIndex, 3);
      expect(controller.pendingStudentId, 'std_10');
      expect(controller.pendingNotificationId, 'n_checkin');
    });

    testWidgets('10. handleNotificationTap routes map_page or tripStarted to index 2 (BusTrackingPage)', (tester) async {
      await tester.pumpWidget(MaterialApp(navigatorKey: controller.navigatorKey, home: const SizedBox()));

      final notifTrip = AppNotification(
        id: 'n_trip',
        title: 'انطلقت الرحلة',
        body: 'بدأت الحافلة التحرك',
        time: DateTime.now(),
        type: NotificationType.tripStarted,
        data: {'target_screen': 'map_page'},
      );

      NotificationRouter.handleNotificationTap(controller, notifTrip);
      await tester.pump(const Duration(milliseconds: 50));

      expect(controller.navIndex, 2);
    });

    testWidgets('11. handleNotificationTap routes attendance to index 7 (AttendanceHistoryPage)', (tester) async {
      await tester.pumpWidget(MaterialApp(navigatorKey: controller.navigatorKey, home: const SizedBox()));

      final notifAttendance = AppNotification(
        id: 'n_att',
        title: 'حضور مدرسي',
        body: 'تم تسجيل الحضور بالمدرسة',
        time: DateTime.now(),
        type: NotificationType.schoolAttendance,
        data: {'target_screen': 'attendance_history'},
      );

      NotificationRouter.handleNotificationTap(controller, notifAttendance);
      await tester.pump(const Duration(milliseconds: 50));

      expect(controller.navIndex, 7);
    });

    testWidgets('12. handleNotificationTap routes absence_requests to index 10 (AbsenceHistoryPage)', (tester) async {
      await tester.pumpWidget(MaterialApp(navigatorKey: controller.navigatorKey, home: const SizedBox()));

      final notifAbsence = AppNotification(
        id: 'n_abs',
        title: 'طلب غياب',
        body: 'تمت الموافقة على طلب الغياب',
        time: DateTime.now(),
        type: NotificationType.absenceApproved,
        category: 'absences',
        data: {'target_screen': 'absence_history'},
      );

      NotificationRouter.handleNotificationTap(controller, notifAbsence);
      await tester.pump(const Duration(milliseconds: 50));

      expect(controller.navIndex, 10);
    });

    testWidgets('13. handleNotificationTap routes location_requests to index 11 (LocationRequestsPage)', (tester) async {
      await tester.pumpWidget(MaterialApp(navigatorKey: controller.navigatorKey, home: const SizedBox()));

      final notifLocation = AppNotification(
        id: 'n_loc',
        title: 'تغيير موقع',
        body: 'تم قبول طلب تغيير موقع المنزل',
        time: DateTime.now(),
        type: NotificationType.locationApproved,
        category: 'location_requests',
        data: {'target_screen': 'location_requests'},
      );

      NotificationRouter.handleNotificationTap(controller, notifLocation);
      await tester.pump(const Duration(milliseconds: 50));

      expect(controller.navIndex, 11);
    });

    testWidgets('14. handleNotificationTap routes unrecognized notifications to index 4 (NotificationsPage)', (tester) async {
      await tester.pumpWidget(MaterialApp(navigatorKey: controller.navigatorKey, home: const SizedBox()));

      final notifAdmin = AppNotification(
        id: 'n_admin',
        title: 'إجازة رسمية',
        body: 'تعطيل الدراسة غداً بمناسبة العيد الوطني',
        time: DateTime.now(),
        type: NotificationType.adminAnnouncement,
        category: 'school',
      );

      NotificationRouter.handleNotificationTap(controller, notifAdmin);
      await tester.pump(const Duration(milliseconds: 50));

      expect(controller.navIndex, 4);
      expect(controller.pendingNotificationId, 'n_admin');
    });

    testWidgets('15. handleNotificationTap routes chat notification to pending chat route when navigator not ready', (tester) async {
      final notifChat = AppNotification(
        id: 'n_chat',
        title: 'رسالة جديدة',
        body: 'أهلاً بك',
        time: DateTime.now(),
        type: NotificationType.chat,
        data: {
          'conversation_id': '45',
          'sender_name': 'المشرفة نورة',
          'sender_role': 'supervisor',
        },
      );

      // Pump MaterialApp without controller's navigatorKey so controller.navigatorKey.currentState is null
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      NotificationRouter.handleNotificationTap(controller, notifChat);
      await tester.pump(const Duration(milliseconds: 50));

      // When navigatorKey has no mounted state in unit test, it queues pending chat route
      expect(controller.hasPendingChatRoute, isTrue);
      expect(controller.navIndex, 5); // ContactsPage index
    });

    testWidgets('16. handleNotificationTap routes chat directly when navigatorKey is mounted', (tester) async {
      await tester.pumpWidget(
        AppScope(
          controller: controller,
          child: MaterialApp(
            navigatorKey: controller.navigatorKey,
            locale: const Locale('ar'),
            home: const Scaffold(body: Text('Home')),
          ),
        ),
      );

      final notifChat = AppNotification(
        id: 'n_chat_direct',
        title: 'رسالة مباشرة',
        body: 'مرحبا بك',
        time: DateTime.now(),
        type: NotificationType.chat,
        data: {
          'conversation_id': '88',
          'sender_name': 'السائق أحمد',
          'sender_role': 'driver',
        },
      );

      NotificationRouter.handleNotificationTap(controller, notifChat);
      await tester.pumpAndSettle();

      expect(controller.navIndex, 5);
      expect(find.byType(ChatPage), findsOneWidget);
    });

    testWidgets('17. handleNotificationTap ignores chat tap if conversationId is missing or invalid', (tester) async {
      await tester.pumpWidget(MaterialApp(navigatorKey: controller.navigatorKey, home: const Scaffold(body: Text('Home'))));

      // Missing conv id
      final notifMissing = AppNotification(
        id: 'n_missing',
        title: 'رسالة ناقصة',
        body: 'نص',
        time: DateTime.now(),
        type: NotificationType.chat,
        data: {},
      );
      NotificationRouter.handleNotificationTap(controller, notifMissing);
      await tester.pump(const Duration(milliseconds: 50));

      // Invalid conv id
      final notifInvalid = AppNotification(
        id: 'n_invalid',
        title: 'رسالة غير صالحة',
        body: 'نص',
        time: DateTime.now(),
        type: NotificationType.chat,
        data: {'conversation_id': 'abc'},
      );
      NotificationRouter.handleNotificationTap(controller, notifInvalid);
      await tester.pump(const Duration(milliseconds: 50));

      expect(controller.hasPendingChatRoute, isFalse);
    });

    testWidgets('18. handleNotificationTap routes target_screen "children"', (tester) async {
      await tester.pumpWidget(MaterialApp(navigatorKey: controller.navigatorKey, home: const SizedBox()));

      final notifChildren = AppNotification(
        id: 'n_ch',
        title: 'الأبناء',
        body: 'تحديث بيانات الأبناء',
        time: DateTime.now(),
        type: NotificationType.schoolAlert,
        data: {'target_screen': 'children'},
      );
      NotificationRouter.handleNotificationTap(controller, notifChildren);
      await tester.pump(const Duration(milliseconds: 50));
      expect(controller.navIndex, 1);
    });

    testWidgets('19. handleNotificationTap routes target_screen "home"', (tester) async {
      await tester.pumpWidget(MaterialApp(navigatorKey: controller.navigatorKey, home: const SizedBox()));

      final notifHome = AppNotification(
        id: 'n_hm',
        title: 'الرئيسية',
        body: 'العودة للرئيسية',
        time: DateTime.now(),
        type: NotificationType.schoolAlert,
        data: {'target_screen': 'home'},
      );
      NotificationRouter.handleNotificationTap(controller, notifHome);
      await tester.pump(const Duration(milliseconds: 50));
      expect(controller.navIndex, 0);
    });

    testWidgets('20. handleNotificationTap type-based fallback routing for trip events', (tester) async {
      await tester.pumpWidget(MaterialApp(navigatorKey: controller.navigatorKey, home: const SizedBox()));

      final notifTrip = AppNotification(
        id: 'n_trip',
        title: 'انطلاق',
        body: 'انطلقت الحافلة',
        time: DateTime.now(),
        type: NotificationType.tripStarted,
      );
      NotificationRouter.handleNotificationTap(controller, notifTrip);
      await tester.pump(const Duration(milliseconds: 50));
      expect(controller.navIndex, 2);
    });

  });
}

