import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/tracking/domain/entities/bus_tracking_group.dart';

class FakeChildrenDioAdapter implements HttpClientAdapter {
  Map<String, dynamic> responseData = {
    'data': [
      {
        'id': 'std_1',
        'name': 'الابن الأول',
        'grade': 'الصف الأول',
        'bus': {'id': 'bus_1', 'bus_number': '1', 'plate_number': '1111 A'},
        'status': 'atHome',
        'home_lat': 23.5880,
        'home_lng': 58.3829,
      },
      {
        'id': 'std_2',
        'name': 'الابن الثاني',
        'grade': 'الصف الثاني',
        'bus': {'id': 'bus_2', 'bus_number': '2', 'plate_number': '2222 B'},
        'status': 'atHome',
      },
    ]
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(responseData),
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
  id: 'bus_10',
  number: '10',
  plate: '1234 A',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Student.deriveStudentStatus 5-Step Lifecycle Suite', () {
    final now = DateTime(2026, 9, 4, 7, 30);

    test('1. Timestamp precedence: arrivedHomeTime takes highest priority', () {
      final status = Student.deriveStudentStatus(
        'onBus',
        'to_home',
        arrivedHomeTime: now,
        onBusToHomeTime: now.subtract(const Duration(minutes: 20)),
        atSchoolTime: now.subtract(const Duration(hours: 4)),
      );
      expect(status, StudentStatus.arrivedHome);
    });

    test('2. onBusToHomeTime returns onBusToHome unless rawStatus is atHome/arrivedHome', () {
      // Normal on bus to home
      final statusEnRoute = Student.deriveStudentStatus(
        'onBus',
        'to_home',
        onBusToHomeTime: now,
        atSchoolTime: now.subtract(const Duration(hours: 3)),
      );
      expect(statusEnRoute, StudentStatus.onBusToHome);

      // Raw status already arrived at home
      final statusArrived = Student.deriveStudentStatus(
        'atHome',
        'to_home',
        onBusToHomeTime: now.subtract(const Duration(minutes: 30)),
      );
      expect(statusArrived, StudentStatus.arrivedHome);
    });

    test('3. atSchoolTime returns atSchool unless return trip started with rawStatus onBus', () {
      // Normal at school
      final statusAtSchool = Student.deriveStudentStatus(
        'atSchool',
        'to_school',
        atSchoolTime: now,
      );
      expect(statusAtSchool, StudentStatus.atSchool);

      // Return trip started
      final statusReturn = Student.deriveStudentStatus(
        'onBus',
        'to_home',
        atSchoolTime: now.subtract(const Duration(hours: 5)),
      );
      expect(statusReturn, StudentStatus.onBusToHome);
    });

    test('4. onBusToSchoolTime returns onBusToSchool unless rawStatus is atSchool', () {
      final statusMorningBus = Student.deriveStudentStatus(
        'onBus',
        'to_school',
        onBusToSchoolTime: now,
      );
      expect(statusMorningBus, StudentStatus.onBusToSchool);

      final statusSchoolArrival = Student.deriveStudentStatus(
        'atSchool',
        'to_school',
        onBusToSchoolTime: now.subtract(const Duration(minutes: 25)),
      );
      expect(statusSchoolArrival, StudentStatus.atSchool);
    });

    test('5. waitingAtHomeTime returns waitingAtHome unless rawStatus is onBus', () {
      final statusWaiting = Student.deriveStudentStatus(
        'waiting',
        'to_school',
        waitingAtHomeTime: now,
      );
      expect(statusWaiting, StudentStatus.waitingAtHome);

      final statusBoarded = Student.deriveStudentStatus(
        'onBus',
        'to_school',
        waitingAtHomeTime: now.subtract(const Duration(minutes: 10)),
      );
      expect(statusBoarded, StudentStatus.onBusToSchool);
    });

    test('6. Raw status fallback without timestamps respects trip direction', () {
      // onBus with morning directions
      expect(Student.deriveStudentStatus('onBus', 'to_school'), StudentStatus.onBusToSchool);
      expect(Student.deriveStudentStatus('onBus', 'forth'), StudentStatus.onBusToSchool);
      expect(Student.deriveStudentStatus('onBus', 'morning'), StudentStatus.onBusToSchool);

      // onBus with afternoon directions
      expect(Student.deriveStudentStatus('onBus', 'to_home'), StudentStatus.onBusToHome);
      expect(Student.deriveStudentStatus('onBus', 'back'), StudentStatus.onBusToHome);
      expect(Student.deriveStudentStatus('onBus', 'return'), StudentStatus.onBusToHome);

      // atHome direction
      expect(Student.deriveStudentStatus('atHome', 'to_home'), StudentStatus.arrivedHome);
      expect(Student.deriveStudentStatus('atHome', 'to_school'), StudentStatus.waitingAtHome);

      // notBoarded and late
      expect(Student.deriveStudentStatus('notBoarded', null), StudentStatus.notBoarded);
      expect(Student.deriveStudentStatus('late', null), StudentStatus.late);
    });
  });

  group('Student Model Behavioral Logic & Display Names Suite', () {
    test('7. displayName falls back gracefully: name -> studentCode -> id', () {
      // 1. Name present
      const s1 = Student(
        id: 'st_1',
        name: 'فيصل العماني',
        studentCode: 'CODE-99',
        grade: 'الصف الأول',
        schoolId: 'sch_1',
        bus: defaultBus,
        status: StudentStatus.waitingAtHome,
      );
      expect(s1.displayName, 'فيصل العماني');

      // 2. Name empty, studentCode present
      const s2 = Student(
        id: 'st_2',
        name: '   ',
        studentCode: 'CODE-99',
        grade: 'الصف الأول',
        schoolId: 'sch_1',
        bus: defaultBus,
        status: StudentStatus.waitingAtHome,
      );
      expect(s2.displayName, 'CODE-99');

      // 3. Both empty, falls back to id
      const s3 = Student(
        id: 'st_3',
        name: '',
        studentCode: null,
        grade: 'الصف الأول',
        schoolId: 'sch_1',
        bus: defaultBus,
        status: StudentStatus.waitingAtHome,
      );
      expect(s3.displayName, 'st_3');
    });

    test('8. getLocalizedName and getLocalizedGrade respect language codes', () {
      const student = Student(
        id: 'st_bilingual',
        name: 'سالم الشكيلي',
        nameEn: 'Salim Al-Shukaili',
        grade: 'الصف الرابع',
        gradeEn: 'Grade 4',
        schoolId: 'sch_1',
        bus: defaultBus,
        status: StudentStatus.waitingAtHome,
      );

      expect(student.getLocalizedName('ar'), 'سالم الشكيلي');
      expect(student.getLocalizedName('en'), 'Salim Al-Shukaili');
      expect(student.getLocalizedGrade('ar'), 'الصف الرابع');
      expect(student.getLocalizedGrade('en'), 'Grade 4');
    });

    test('9. hasLocation validates non-null and non-zero home coordinates', () {
      // Valid location
      const validStudent = Student(
        id: 'st_loc_1',
        name: 'مازن',
        grade: 'الصف الخامس',
        schoolId: 'sch_1',
        bus: defaultBus,
        status: StudentStatus.waitingAtHome,
        homeLocation: LatLng(23.5880, 58.3829),
      );
      expect(validStudent.hasLocation, isTrue);

      // Null location
      const nullStudent = Student(
        id: 'st_loc_2',
        name: 'مازن',
        grade: 'الصف الخامس',
        schoolId: 'sch_1',
        bus: defaultBus,
        status: StudentStatus.waitingAtHome,
        homeLocation: null,
      );
      expect(nullStudent.hasLocation, isFalse);

      // 0,0 dummy location
      const zeroStudent = Student(
        id: 'st_loc_3',
        name: 'مازن',
        grade: 'الصف الخامس',
        schoolId: 'sch_1',
        bus: defaultBus,
        status: StudentStatus.waitingAtHome,
        homeLocation: LatLng(0, 0),
      );
      expect(zeroStudent.hasLocation, isFalse);
    });

    test('10. Student fromJson parses nested objects and timestamps properly', () {
      final json = {
        'id': 701,
        'name': 'ريم',
        'name_en': 'Reem',
        'student_code': 'ST-701',
        'grade': 'الصف الثاني',
        'grade_en': 'Grade 2',
        'status': 'onBus',
        'suggested_direction': 'to_school',
        'trip_count': 14,
        'attendance_percentage': 96,
        'home_lat': '23.6000',
        'home_lng': '58.4000',
        'forth_lat': '23.6010',
        'forth_lng': '58.4010',
        'back_lat': '23.6020',
        'back_lng': '58.4020',
        'bus': {
          'id': 'bus_50',
          'bus_number': '50',
          'plate_number': '5555 B',
        },
        'school': {
          'id': 10,
          'name': 'مدرسة الأمل',
          'latitude': 23.5900,
          'longitude': 58.3800,
        },
      };

      final student = Student.fromJson(json);

      expect(student.id, '701');
      expect(student.name, 'ريم');
      expect(student.nameEn, 'Reem');
      expect(student.studentCode, 'ST-701');
      expect(student.status, StudentStatus.onBusToSchool);
      expect(student.tripCount, 14);
      expect(student.attendancePercentage, 96);
      expect(student.hasLocation, isTrue);
      expect(student.homeLocation?.latitude, 23.6000);
      expect(student.bus.id, 'bus_50');
      expect(student.schoolName, 'مدرسة الأمل');
      expect(student.schoolCoords?.latitude, 23.5900);
    });
  });

  group('AppController Student Management & Selection Suite', () {
    late AppController controller;
    late FakeChildrenDioAdapter fakeDio;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'user_id': 100,
        'user_name': 'Parent Test',
        'has_seen_onboarding': true,
      });
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'test_jwt',
      });
      controller = AppController();
      fakeDio = FakeChildrenDioAdapter();
      controller.dio.httpClientAdapter = fakeDio;
    });

    tearDown(() {
      controller.stopTrackingPoll();
      controller.dispose();
    });

    test('11. selectStudent updates selection index and currentStudent', () async {
      await controller.loadChildrenFromApi();

      expect(controller.students.length, 2);
      expect(controller.currentStudent?.id, 'std_1');

      // Select by index
      controller.selectStudent(1);
      expect(controller.currentStudent?.id, 'std_2');

      // Out-of-bounds index is handled safely without throwing
      controller.selectStudent(99);
      expect(controller.currentStudent?.id, 'std_2');

      // Select by ID resolution
      final idx = controller.students.indexWhere((s) => s.id == 'std_1');
      if (idx != -1) controller.selectStudent(idx);
      expect(controller.currentStudent?.id, 'std_1');
    });

    test('12. loadChildrenFromApi accurately identifies missing location flag', () async {
      // std_2 has no location coordinates in fakeDio
      await controller.loadChildrenFromApi();

      expect(controller.hasMissingLocation, isTrue);
      expect(controller.students[0].hasLocation, isTrue);
      expect(controller.students[1].hasLocation, isFalse);
    });
  });
}
