import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/features/absence/domain/entities/absence_request.dart';

class _MockApiAdapter implements HttpClientAdapter {
  Map<String, dynamic> responses = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    for (final entry in responses.entries) {
      if (options.path.contains(entry.key)) {
        return ResponseBody.fromString(
          jsonEncode(entry.value),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      }
    }

    if (options.path.contains('profile')) {
      return ResponseBody.fromString(
        jsonEncode({
          'data': {'id': 101, 'name': 'أحمد الوالد', 'phone': '96812345678'},
          'success': true,
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'data': [], 'success': true}),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppController controller;
  late _MockApiAdapter adapter;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
      (call) async => null,
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding': true,
      'user_id': 101,
      'user_name': 'أحمد الوالد',
      'app_locale': 'ar',
      'my_student_ids': ['std_1', 'std_2'],
    });
    FlutterSecureStorage.setMockInitialValues({'access_token': 'mock_token'});
    adapter = _MockApiAdapter();
    adapter.responses['parent/children'] = {
      'data': [
        {
          'id': 'std_1',
          'name': 'عمر',
          'name_en': 'Omar',
          'grade': 'الصف الرابع',
          'school_id': 'sc1',
          'status': 'at_home',
          'bus': {'id': 'b1', 'number': '101', 'plate': '123'},
        }
      ],
      'success': true,
    };
    controller = AppController();
    controller.dio.httpClientAdapter = adapter;
    await controller.bootstrap();
    await Future.delayed(const Duration(milliseconds: 100));
    controller.stopTrackingPoll();
  });

  tearDown(() {
    controller.stopTrackingPoll();
    controller.dispose();
  });

  group('AppController Comprehensive Edge Cases & Notification Suite', () {
    test('1. addNotification suppresses foreign student notifications', () async {
      final foreignNotif = AppNotification(
        id: 'notif_foreign',
        title: 'Foreign',
        body: 'Body',
        time: DateTime.now(),
        type: NotificationType.checkIn,
        data: {'student_id': 'std_unknown_foreign'},
      );

      await controller.addNotification(foreignNotif);
      expect(controller.notifications.any((n) => n.id == 'notif_foreign'), isFalse);
    });

    test('2. addNotification deduplicates by CID in memory and storage', () async {
      final notif1 = AppNotification(
        id: 'notif_cid_1',
        title: 'Title',
        body: 'Body',
        time: DateTime.now(),
        type: NotificationType.schoolAlert,
        correlationId: 'cid_test_123',
        data: {'student_id': 'std_1'},
      );

      await controller.addNotification(notif1);
      final countFirst = controller.notifications.where((n) => n.id == 'notif_cid_1').length;
      expect(countFirst, 1);

      // Duplicate with same CID
      final notifDuplicate = AppNotification(
        id: 'notif_cid_2',
        title: 'Title 2',
        body: 'Body 2',
        time: DateTime.now(),
        type: NotificationType.schoolAlert,
        correlationId: 'cid_test_123',
        data: {'student_id': 'std_1'},
      );
      await controller.addNotification(notifDuplicate);
      expect(controller.notifications.any((n) => n.id == 'notif_cid_2'), isFalse);
    });

    test('3. addNotification updates student status for checkIn, checkOut, arrival, and approach', () async {
      expect(controller.students.isNotEmpty, isTrue);

      // CheckIn to school
      final checkInNotif = AppNotification(
        id: 'notif_checkin',
        title: 'ركب الحافلة',
        body: 'ركب عمر الحافلة',
        time: DateTime.now(),
        type: NotificationType.checkIn,
        data: {'student_id': 'std_1', 'direction': 'to_school'},
      );
      await controller.addNotification(checkInNotif);
      expect(controller.students.first.status, StudentStatus.onBusToSchool);

      // Arrival at school
      final arrivalNotif = AppNotification(
        id: 'notif_arrival',
        title: 'وصل إلى المدرسة',
        body: 'وصل عمر المدرسة',
        time: DateTime.now(),
        type: NotificationType.arrival,
        data: {'student_id': 'std_1', 'direction': 'to_school'},
      );
      await controller.addNotification(arrivalNotif);
      expect(controller.students.first.status, StudentStatus.atSchool);

      // CheckIn to home
      final checkInHomeNotif = AppNotification(
        id: 'notif_checkin_home',
        title: 'ركب العودة',
        body: 'ركب الحافلة عائد للمنزل',
        time: DateTime.now(),
        type: NotificationType.checkIn,
        data: {'student_id': 'std_1', 'direction': 'to_home'},
      );
      await controller.addNotification(checkInHomeNotif);
      expect(controller.students.first.status, StudentStatus.onBusToHome);

      // CheckOut at home
      final checkOutHomeNotif = AppNotification(
        id: 'notif_checkout_home',
        title: 'وصل للمنزل',
        body: 'نزل عمر عند المنزل',
        time: DateTime.now(),
        type: NotificationType.checkOut,
        data: {'student_id': 'std_1', 'direction': 'to_home'},
      );
      await controller.addNotification(checkOutHomeNotif);
      expect(controller.students.first.status, StudentStatus.arrivedHome);
    });

    test('4. addNotification with isTap=true marks notification as read and navigates', () async {
      final notif = AppNotification(
        id: 'notif_tap_test',
        title: 'تنبيه إشعار',
        body: 'تفاصيل الإشعار',
        time: DateTime.now(),
        type: NotificationType.schoolAlert,
        data: {'student_id': 'std_1'},
      );

      await controller.addNotification(notif, isTap: true);
      expect(notif.read, isTrue);
      expect(controller.notifications.any((n) => n.id == 'notif_tap_test'), isTrue);
    });

    test('5. markNotificationsReadByCategory filters and marks categories correctly', () async {
      final notifAbsence = AppNotification(
        id: 'notif_abs_1',
        title: 'طلب غياب',
        body: 'تمت الموافقة',
        time: DateTime.now(),
        type: NotificationType.absenceApproved,
        category: 'absence',
        targetScreen: 'absence_history',
        data: {'student_id': 'std_1'},
      );
      final notifLoc = AppNotification(
        id: 'notif_loc_1',
        title: 'طلب موقع',
        body: 'تمت الموافقة',
        time: DateTime.now(),
        type: NotificationType.locationApproved,
        category: 'location_requests',
        targetScreen: 'location_requests',
        data: {'student_id': 'std_1'},
      );

      await controller.addNotification(notifAbsence);
      await controller.addNotification(notifLoc);

      await controller.markNotificationsReadByCategory('absence');
      final updatedAbsence = controller.notifications.firstWhere((n) => n.id == 'notif_abs_1');
      expect(updatedAbsence.read, isTrue);

      await controller.markNotificationsReadByCategory('location_requests');
      final updatedLoc = controller.notifications.firstWhere((n) => n.id == 'notif_loc_1');
      expect(updatedLoc.read, isTrue);
    });

    test('6. API operations: submitAbsenceRequest and updateHomeLocationApi execute gracefully', () async {
      adapter.responses['parent/absence-requests'] = {'success': true, 'message': 'تم إرسال الطلب'};
      adapter.responses['location/update'] = {'success': true, 'message': 'تم تحديث الموقع'};

      final absenceSuccess = await controller.submitAbsenceRequest(
        studentIds: ['std_1'],
        type: AbsenceType.both,
        date: DateTime.now(),
        reason: 'إجازة مرضية',
      );
      expect(absenceSuccess, isTrue);

      final locationResult = await controller.updateHomeLocationApi(
        const LatLng(23.5880, 58.3829),
        studentId: 'std_1',
        address: 'مسقط',
        note: 'بالقرب من المسجد',
      );
      expect(locationResult, isNotNull);
    });
  });
}
