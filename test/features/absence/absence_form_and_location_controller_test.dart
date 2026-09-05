import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/absence/domain/entities/absence_request.dart';
import 'package:msaratwasel_user/src/features/absence/data/repositories/absence_repository_impl.dart';

class FakeAbsenceDioAdapter implements HttpClientAdapter {
  final List<Map<String, dynamic>> recordedRequests = [];
  Map<String, dynamic>? customResponseData;
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
          statusCode: 422,
          data: {'message': dioErrorMessage ?? 'Unprocessable Entity'},
        ),
      );
    }

    dynamic data = customResponseData;
    if (options.path.contains('parent/children')) {
      data = (customResponseData != null && customResponseData!['data'] is List)
          ? customResponseData
          : {'data': []};
    } else if (options.path.contains('parent/profile')) {
      data = {'data': {'id': 1, 'name': 'Parent'}};
    } else if (options.path.contains('parent/location-requests') && customResponseData == null) {
      data = {'data': []};
    } else {
      data = customResponseData ?? {'data': []};
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

  group('AbsenceRequest Entity Unit Tests', () {
    final testDate = DateTime(2026, 9, 4);

    test('1. getLocalizedStudentName resolves language code correctly', () {
      final request = AbsenceRequest(
        id: '1',
        studentIds: ['s1'],
        studentName: 'أحمد علي',
        studentNameEn: 'Ahmed Ali',
        type: AbsenceType.morning,
        date: testDate,
      );

      expect(request.getLocalizedStudentName('en'), 'Ahmed Ali');
      expect(request.getLocalizedStudentName('EN'), 'Ahmed Ali');
      expect(request.getLocalizedStudentName('ar'), 'أحمد علي');
      expect(request.getLocalizedStudentName('fr'), 'أحمد علي');
    });

    test('2. getLocalizedStudentName falls back to Arabic if English is null or empty', () {
      final requestEmptyEn = AbsenceRequest(
        id: '2',
        studentIds: ['s2'],
        studentName: 'فاطمة خالد',
        studentNameEn: '   ',
        type: AbsenceType.both,
        date: testDate,
      );

      expect(requestEmptyEn.getLocalizedStudentName('en'), 'فاطمة خالد');

      final requestNullEn = AbsenceRequest(
        id: '3',
        studentIds: ['s3'],
        studentName: 'خالد عمر',
        studentNameEn: null,
        type: AbsenceType.returnOnly,
        date: testDate,
      );

      expect(requestNullEn.getLocalizedStudentName('en'), 'خالد عمر');
    });
  });

  group('AbsenceRepositoryImpl Suite', () {
    late Dio dio;
    late FakeAbsenceDioAdapter fakeAdapter;
    late AbsenceRepositoryImpl repo;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://example.com/api/'));
      fakeAdapter = FakeAbsenceDioAdapter();
      dio.httpClientAdapter = fakeAdapter;
      repo = AbsenceRepositoryImpl(dio: dio);
    });

    test('3. submitAbsence loops through studentIds and maps AbsenceTypes correctly', () async {
      final requestMorning = AbsenceRequest(
        studentIds: ['std_10', 'std_20'],
        type: AbsenceType.morning,
        date: DateTime(2026, 9, 15),
        note: 'Medical appointment',
      );

      await repo.submitAbsence(requestMorning);

      expect(fakeAdapter.recordedRequests.length, 2);
      expect(fakeAdapter.recordedRequests[0]['data']['student_id'], 'std_10');
      expect(fakeAdapter.recordedRequests[0]['data']['type'], 'morning');
      expect(fakeAdapter.recordedRequests[0]['data']['date'], '2026-09-15');
      expect(fakeAdapter.recordedRequests[0]['data']['reason'], 'Medical appointment');

      expect(fakeAdapter.recordedRequests[1]['data']['student_id'], 'std_20');
      expect(fakeAdapter.recordedRequests[1]['data']['type'], 'morning');

      // Test returnOnly and both mappings
      fakeAdapter.recordedRequests.clear();
      final requestReturn = AbsenceRequest(
        studentIds: ['std_30'],
        type: AbsenceType.returnOnly,
        date: DateTime(2026, 9, 16),
      );
      await repo.submitAbsence(requestReturn);
      expect(fakeAdapter.recordedRequests.first['data']['type'], 'afternoon');

      fakeAdapter.recordedRequests.clear();
      final requestBoth = AbsenceRequest(
        studentIds: ['std_40'],
        type: AbsenceType.both,
        date: DateTime(2026, 9, 17),
      );
      await repo.submitAbsence(requestBoth);
      expect(fakeAdapter.recordedRequests.first['data']['type'], 'full_day');
    });

    test('4. fetchHistory parses list of absence requests and types accurately', () async {
      fakeAdapter.customResponseData = {
        'data': [
          {
            'id': 101,
            'student_id': 501,
            'student_name': 'عمر حسن',
            'student_name_en': 'Omar Hassan',
            'type': 'morning',
            'date': '2026-09-10',
            'reason': 'موعد طبيب',
            'status': 'approved',
            'rejection_reason': null,
          },
          {
            'id': 102,
            'student_id': 502,
            'student': {
              'name': 'ليلى',
              'name_en': 'Layla',
            },
            'type': 'afternoon',
            'date': '2026-09-11',
            'reason': 'سفر عائلي',
            'status': 'rejected',
            'rejection_reason': 'غير مبرر',
          },
          {
            'id': 103,
            'student_id': 503,
            'type': 'full_day',
            'date': '2026-09-12',
            'reason': 'إجازة',
            'status': 'pending',
          },
        ]
      };

      final history = await repo.fetchHistory();

      expect(history.length, 3);
      expect(history[0].id, '101');
      expect(history[0].studentIds, ['501']);
      expect(history[0].studentName, 'عمر حسن');
      expect(history[0].type, AbsenceType.morning);
      expect(history[0].status, 'approved');

      expect(history[1].id, '102');
      expect(history[1].studentName, 'ليلى');
      expect(history[1].studentNameEn, 'Layla');
      expect(history[1].type, AbsenceType.returnOnly);
      expect(history[1].status, 'rejected');
      expect(history[1].rejectionReason, 'غير مبرر');

      expect(history[2].type, AbsenceType.both);
      expect(history[2].status, 'pending');
    });

    test('5. fetchHistory returns empty list on non-200 status code', () async {
      dio.options.validateStatus = (status) => true;
      fakeAdapter.statusCode = 204;
      final history = await repo.fetchHistory();
      expect(history, isEmpty);
    });
  });

  group('LocationChangeRequest Model Unit Tests', () {
    test('6. LocationChangeRequest parses json with coordinates and status flags', () {
      final json = {
        'id': 'req_123',
        'student_id': 'std_99',
        'student_name': 'يوسف خالد',
        'created_at': '2026-09-01T10:00:00Z',
        'status': 'pending',
        'new_latitude': '23.6100',
        'new_longitude': '58.5400',
        'new_address': 'مسقط - الخوض',
        'rejection_reason': null,
      };

      final request = LocationChangeRequest.fromJson(json);

      expect(request.id, 'req_123');
      expect(request.studentId, 'std_99');
      expect(request.studentName, 'يوسف خالد');
      expect(request.newLatitude, 23.6100);
      expect(request.newLongitude, 58.5400);
      expect(request.newAddress, 'مسقط - الخوض');
      expect(request.isPending, isTrue);
      expect(request.isApproved, isFalse);
      expect(request.isRejected, isFalse);
    });

    test('7. LocationChangeRequest handles approved/rejected statuses and missing fields', () {
      final jsonApproved = {
        'id': 456,
        'student_id': 789,
        'status': 'approved',
      };
      final reqApproved = LocationChangeRequest.fromJson(jsonApproved);
      expect(reqApproved.id, '456');
      expect(reqApproved.isApproved, isTrue);
      expect(reqApproved.newLatitude, isNull);
      expect(reqApproved.studentName, '');

      final jsonRejected = {
        'id': '789',
        'student_id': '101',
        'status': 'rejected',
        'rejection_reason': 'خارج نطاق المدرسة',
      };
      final reqRejected = LocationChangeRequest.fromJson(jsonRejected);
      expect(reqRejected.isRejected, isTrue);
      expect(reqRejected.rejectionReason, 'خارج نطاق المدرسة');
    });
  });

  group('AppController Absence & Location Integration Suite', () {
    late AppController controller;
    late FakeAbsenceDioAdapter fakeDio;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'user_id': 100,
        'user_name': 'Parent Test',
      });
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'mock_token',
      });
      controller = AppController();
      fakeDio = FakeAbsenceDioAdapter();
      controller.dio.httpClientAdapter = fakeDio;
    });

    tearDown(() {
      controller.stopTrackingPoll();
      controller.dispose();
    });

    test('8. submitAbsence successfully delegates to AbsenceRepository and returns success', () async {
      fakeDio.customResponseData = {'status': 'success'};

      final result = await controller.submitAbsence(
        studentId: 'std_100',
        period: 'morning',
        reason: 'sick',
        note: 'flu',
      );

      expect(result.success, isTrue);
      expect(result.message, isNull);
      expect(fakeDio.recordedRequests.isNotEmpty, isTrue);
      expect(fakeDio.recordedRequests.first['path'], 'parent/absence-requests');
      expect(fakeDio.recordedRequests.first['data']['student_id'], 'std_100');
      expect(fakeDio.recordedRequests.first['data']['type'], 'morning');
      expect(fakeDio.recordedRequests.first['data']['reason'], 'sick: flu');
    });

    test('9. submitAbsence catches DioException and extracts error message', () async {
      fakeDio.shouldThrowDioException = true;
      fakeDio.dioErrorMessage = 'الطالب مسجل غائب بالفعل لهذا اليوم';

      final result = await controller.submitAbsence(
        studentId: 'std_100',
        period: 'full_day',
        reason: 'personal',
        note: '',
      );

      expect(result.success, isFalse);
      expect(result.message, 'الطالب مسجل غائب بالفعل لهذا اليوم');
    });

    test('10. loadAbsenceRequestsFromApi updates controller absenceRequests list', () async {
      fakeDio.customResponseData = {
        'data': [
          {
            'id': 1,
            'student_id': 10,
            'student_name': 'سعيد',
            'type': 'full_day',
            'date': '2026-09-04',
            'reason': 'إجازة',
            'status': 'approved',
          }
        ]
      };

      await controller.loadAbsenceRequestsFromApi();

      expect(controller.absenceRequests.length, 1);
      expect(controller.absenceRequests.first.studentName, 'سعيد');
      expect(controller.absenceRequests.first.type, AbsenceType.both);
    });

    test('11. loadLocationRequestsFromApi parses requests and handles corrupt items gracefully', () async {
      fakeDio.customResponseData = {
        'data': [
          {
            'id': 'loc_1',
            'student_id': 'std_1',
            'student_name': 'حمد',
            'status': 'pending',
            'new_latitude': 23.5880,
            'new_longitude': 58.3829,
          },
          // Corrupt item that fails parsing
          null,
        ]
      };

      await controller.loadLocationRequestsFromApi();

      expect(controller.isLocationRequestsLoading, isFalse);
      expect(controller.locationRequests.length, 1);
      expect(controller.locationRequests.first.id, 'loc_1');
      expect(controller.locationRequests.first.studentName, 'حمد');
    });

    test('12. updateStudentLocation updates local student homeLocation and note', () async {
      // Pre-seed a student in controller
      fakeDio.customResponseData = {
        'data': [
          {
            'id': 'std_location_test',
            'name': 'طالب الفحص',
            'grade': 'الثالث',
            'bus': {'id': 'b1', 'bus_number': '1', 'plate_number': '111'},
            'status': 'atHome',
            'home_lat': 23.5000,
            'home_lng': 58.5000,
          }
        ]
      };
      await controller.loadChildrenFromApi();

      expect(controller.students.first.homeLocation?.latitude, 23.5000);

      controller.updateStudentLocation(
        'std_location_test',
        const LatLng(23.6000, 58.6000),
        note: 'الموقع الجديد بجوار المسجد',
      );

      final updated = controller.students.first;
      expect(updated.homeLocation?.latitude, 23.6000);
      expect(updated.homeLocation?.longitude, 58.6000);
      expect(updated.locationNote, 'الموقع الجديد بجوار المسجد');
    });

    test('13. updateHomeLocationApi posts coordinates and reloads data', () async {
      fakeDio.customResponseData = {
        'success': true,
        'message': 'تم تحديث الموقع بنجاح',
      };

      final msg = await controller.updateHomeLocationApi(
        const LatLng(23.5500, 58.4500),
        studentId: 'std_99',
        address: 'شارع المعرفة',
        note: 'بوابة رقم 2',
      );

      expect(msg, 'تم تحديث الموقع بنجاح');
      expect(fakeDio.recordedRequests.isNotEmpty, isTrue);
      final updateReq = fakeDio.recordedRequests.firstWhere(
        (r) => r['path'] == 'parent/student/location/update',
      );
      expect(updateReq['data']['latitude'], 23.5500);
      expect(updateReq['data']['longitude'], 58.4500);
      expect(updateReq['data']['student_id'], 'std_99');
      expect(updateReq['data']['address'], 'شارع المعرفة');
      expect(updateReq['data']['note'], 'بوابة رقم 2');
    });
  });
}
