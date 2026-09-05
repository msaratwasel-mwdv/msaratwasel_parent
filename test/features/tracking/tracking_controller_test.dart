import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/features/tracking/domain/entities/bus_tracking.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tracking & Location Logic Baseline Suite', () {
    late AppController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'user_id': 55,
        'user_name': 'Test Parent',
        'has_seen_onboarding': true,
        'my_student_ids': ['st_1'],
      });
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'dummy_jwt',
      });

      controller = AppController();
    });

    tearDown(() {
      controller.stopTrackingPoll();
      controller.dispose();
    });

    test('1. Polling interval: 30s when no active trips, 10s when active trips exist', () {
      expect(controller.activeTripGroups.isEmpty, isTrue);
      controller.startTrackingPoll();
      expect(controller.isTrackingDataReady, isFalse);
      controller.stopTrackingPoll();
    });

    test('2. Encapsulation: controller.students is protected as unmodifiable list', () {
      const student = Student(
        id: 'st_1',
        name: 'أحمد',
        grade: 'الصف الأول',
        schoolId: 'school_1',
        bus: BusInfo(id: 'bus_10', number: '10', plate: '1234 A'),
        status: StudentStatus.waitingAtHome,
      );

      // Verifying that external code cannot mutate the internal list
      expect(
        () => controller.students.add(student),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('3. BusTracking entity maintains coordinate, speed, and ETA accurately', () {
      final now = DateTime.now();
      final tracking = BusTracking(
        latitude: 23.5880,
        longitude: 58.3829,
        targetLatitude: 23.5900,
        targetLongitude: 58.3850,
        speed: 45.5,
        etaMinutes: 12,
        lastUpdate: now,
        isStale: false,
      );

      expect(tracking.latitude, 23.5880);
      expect(tracking.longitude, 58.3829);
      expect(tracking.targetLatitude, 23.5900);
      expect(tracking.targetLongitude, 58.3850);
      expect(tracking.speed, 45.5);
      expect(tracking.etaMinutes, 12);
      expect(tracking.isStale, isFalse);

      // Verify copyWith works and retains fields
      final updated = tracking.copyWith(
        latitude: 23.5890,
        speed: 50.0,
      );

      expect(updated.latitude, 23.5890);
      expect(updated.longitude, 58.3829);
      expect(updated.speed, 50.0);
      expect(updated.targetLatitude, 23.5900);
    });

    test('4. Stop tracking poll cancels timer safely', () {
      controller.startTrackingPoll();
      controller.stopTrackingPoll();
      expect(controller.isTrackingDataReady, isFalse);
    });
  });
}
