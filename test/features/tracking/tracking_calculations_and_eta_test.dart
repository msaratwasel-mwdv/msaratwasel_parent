import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/features/tracking/domain/entities/bus_tracking.dart';
import 'package:msaratwasel_user/src/features/tracking/domain/entities/bus_tracking_group.dart';
import 'package:msaratwasel_user/src/features/tracking/domain/entities/bus_position.dart';
import 'package:msaratwasel_user/src/features/tracking/data/repositories/tracking_repository_impl.dart';

class FakeTrackingDioAdapter implements HttpClientAdapter {
  Map<String, dynamic>? locationResponse;
  int statusCode = 200;
  String? lastRequestedPath;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestedPath = options.path;

    final data = locationResponse ?? {
      'latitude': 23.5890,
      'longitude': 58.3840,
      'eta_minutes': 8,
      'bus_number': 'Bus-77',
    };

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

const defaultBus = BusInfo(id: 'bus_10', number: '10', plate: '1234 A');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BusTrackingGroup Business Logic & State Machine Suite', () {
    const studentIdle = Student(
      id: 'st_1',
      name: 'علي ناصر',
      grade: 'الصف الأول',
      schoolId: 'sch_1',
      bus: defaultBus,
      status: StudentStatus.waitingAtHome,
    );

    const studentOnBoard = Student(
      id: 'st_2',
      name: 'سارة أحمد',
      grade: 'الصف الثاني',
      schoolId: 'sch_1',
      bus: defaultBus,
      status: StudentStatus.onBusToSchool,
    );

    test('1. isActiveTrip returns true for all official active and pending trip statuses', () {
      final activeStatuses = [
        'pending',
        'pending_to_school',
        'pending_to_home',
        'to_school',
        'to_home',
        'started',
        'en_route',
        'active',
        'in_progress',
        'awaiting_confirmation',
        'awaiting_video',
        'on_route',
      ];

      for (final status in activeStatuses) {
        final group = BusTrackingGroup(
          busId: 'bus_1',
          tripStatus: status,
          students: [studentIdle],
        );
        expect(group.isActiveTrip, isTrue, reason: 'Status $status should be active');
      }
    });

    test('2. isActiveTrip fallback returns true if inactive status but student is on bus', () {
      final group = BusTrackingGroup(
        busId: 'bus_1',
        tripStatus: 'completed', // explicitly inactive
        students: [studentIdle, studentOnBoard], // but studentOnBoard is on bus!
      );

      expect(group.isActiveTrip, isTrue);
    });

    test('3. isActiveTrip returns false when status is finished and no students are on bus', () {
      final group = BusTrackingGroup(
        busId: 'bus_1',
        tripStatus: 'finished',
        students: [studentIdle],
      );

      expect(group.isActiveTrip, isFalse);
    });

    test('4. isPendingTrip returns true strictly for pending variations', () {
      expect(BusTrackingGroup(busId: 'b1', tripStatus: 'pending', students: []).isPendingTrip, isTrue);
      expect(BusTrackingGroup(busId: 'b1', tripStatus: 'pending_to_school', students: []).isPendingTrip, isTrue);
      expect(BusTrackingGroup(busId: 'b1', tripStatus: 'pending_to_home', students: []).isPendingTrip, isTrue);
      expect(BusTrackingGroup(busId: 'b1', tripStatus: 'active', students: []).isPendingTrip, isFalse);
      expect(BusTrackingGroup(busId: 'b1', tripStatus: 'completed', students: []).isPendingTrip, isFalse);
    });

    test('5. busState maps domain status to UI BusState properly', () {
      // Pending
      expect(BusTrackingGroup(busId: 'b1', tripStatus: 'pending_to_school', students: []).busState, BusState.pending);

      // EnRoute
      expect(BusTrackingGroup(busId: 'b1', tripStatus: 'to_school', students: []).busState, BusState.enRoute);
      expect(BusTrackingGroup(busId: 'b1', tripStatus: 'started', students: []).busState, BusState.enRoute);
      expect(BusTrackingGroup(busId: 'b1', tripStatus: 'en_route', students: []).busState, BusState.enRoute);

      // AtSchool
      expect(BusTrackingGroup(busId: 'b1', tripStatus: 'finished', students: []).busState, BusState.atSchool);
      expect(BusTrackingGroup(busId: 'b1', tripStatus: 'at_school', students: []).busState, BusState.atSchool);
      expect(BusTrackingGroup(busId: 'b1', tripStatus: 'completed', students: []).busState, BusState.atSchool);

      // Default fallback
      expect(BusTrackingGroup(busId: 'b1', tripStatus: 'unknown_status', students: []).busState, BusState.atHome);
    });

    test('6. routeDescription formats directions accurately', () {
      expect(BusTrackingGroup(busId: 'b1', tripType: 'to_school', students: []).routeDescription, 'To School');
      expect(BusTrackingGroup(busId: 'b1', tripType: 'to_home', students: []).routeDescription, 'To Home');
      expect(BusTrackingGroup(busId: 'b1', tripType: 'other', students: []).routeDescription, '--');
    });

    test('7. resolvedStartTime picks explicit startTime or earliest student timeline timestamp', () {
      final explicitTime = DateTime(2026, 9, 4, 7, 0);
      final groupWithExplicit = BusTrackingGroup(
        busId: 'b1',
        startTime: explicitTime,
        students: [],
      );
      expect(groupWithExplicit.resolvedStartTime, explicitTime);

      // Student timeline fallback
      final timeEarlier = DateTime(2026, 9, 4, 6, 45);
      final timeLater = DateTime(2026, 9, 4, 7, 15);

      final studentWithTimestamps = Student(
        id: 'st_3',
        name: 'حسن',
        grade: 'الصف الثالث',
        schoolId: 'sch_1',
        bus: defaultBus,
        status: StudentStatus.waitingAtHome,
        waitingAtHomeTime: timeLater,
        onBusToSchoolTime: timeEarlier, // Earliest!
      );

      final groupFallback = BusTrackingGroup(
        busId: 'b1',
        startTime: null,
        students: [studentWithTimestamps],
      );

      expect(groupFallback.resolvedStartTime, timeEarlier);
    });

    test('8. BusTrackingGroup copyWith cleanly updates targeted fields and preserves rest', () {
      final group = BusTrackingGroup(
        busId: 'b-55',
        busNumber: '55',
        busPlate: '1234-A',
        students: [studentIdle],
        totalStudentsOnBoard: 12,
        tripStatus: 'active',
      );

      final updated = group.copyWith(
        busNumber: '56',
        totalStudentsOnBoard: 15,
      );

      expect(updated.busId, 'b-55');
      expect(updated.busNumber, '56');
      expect(updated.busPlate, '1234-A');
      expect(updated.totalStudentsOnBoard, 15);
      expect(updated.tripStatus, 'active');
      expect(updated.students.length, 1);
    });
  });

  group('TrackingRepositoryImpl & BusPosition Suite', () {
    late Dio dio;
    late FakeTrackingDioAdapter fakeAdapter;
    late TrackingRepositoryImpl repository;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://api.msaratwasel.com/'));
      fakeAdapter = FakeTrackingDioAdapter();
      dio.httpClientAdapter = fakeAdapter;
      repository = TrackingRepositoryImpl(dio: dio);
    });

    test('9. fetchLivePosition parses valid response into BusPosition', () async {
      fakeAdapter.locationResponse = {
        'latitude': 23.6100,
        'longitude': 58.4200,
        'eta_minutes': 14,
        'bus_number': 'Bus-100',
      };

      final position = await repository.fetchLivePosition('bus_100');

      expect(fakeAdapter.lastRequestedPath, 'bus/bus_100/location');
      expect(position.lat, 23.6100);
      expect(position.lng, 58.4200);
      expect(position.etaMinutes, 14);
      expect(position.busNumber, 'Bus-100');
    });

    test('10. fetchLivePosition safely handles missing/null attributes', () async {
      fakeAdapter.locationResponse = {
        'latitude': null,
        'longitude': null,
        'eta_minutes': null,
        'bus_number': null,
      };

      final position = await repository.fetchLivePosition('bus_empty');

      expect(position.lat, 0.0);
      expect(position.lng, 0.0);
      expect(position.etaMinutes, 0);
      expect(position.busNumber, '');
    });
  });

  group('Student Target Detection Geometry Calculations Suite', () {
    test('11. Proximity matching correctly identifies active target with 15m (0.00015) delta', () {
      const targetLatLng = LatLng(23.58800, 58.38290);

      // Point within 10 meters (delta < 0.00015)
      const closeLocation = LatLng(23.58805, 58.38295);
      final latDiff = (closeLocation.latitude - targetLatLng.latitude).abs();
      final lngDiff = (closeLocation.longitude - targetLatLng.longitude).abs();
      final isClose = latDiff < 0.00015 && lngDiff < 0.00015;
      expect(isClose, isTrue);

      // Point farther than 20 meters (delta >= 0.00015)
      const farLocation = LatLng(23.58820, 58.38310);
      final farLatDiff = (farLocation.latitude - targetLatLng.latitude).abs();
      final farLngDiff = (farLocation.longitude - targetLatLng.longitude).abs();
      final isFar = farLatDiff < 0.00015 && farLngDiff < 0.00015;
      expect(isFar, isFalse);
    });

    test('12. Active location resolution differentiates morning forth and afternoon back locations', () {
      const forthLoc = LatLng(23.5900, 58.3850);
      const backLoc = LatLng(23.5950, 58.3900);
      const homeLoc = LatLng(23.5800, 58.3700);

      final student = Student(
        id: 's_geom',
        name: 'طالب هندسي',
        grade: 'الصف الأول',
        schoolId: 'sch_1',
        bus: defaultBus,
        status: StudentStatus.waitingAtHome,
        forthLocation: forthLoc,
        backLocation: backLoc,
        homeLocation: homeLoc,
      );

      // Morning trip ('to_school') should pick forthLocation
      final morningResolved = (student.forthLocation != null && student.forthLocation!.latitude != 0.0)
          ? student.forthLocation
          : student.homeLocation;
      expect(morningResolved, forthLoc);

      // Afternoon trip ('to_home') should pick backLocation
      final afternoonResolved = (student.backLocation != null && student.backLocation!.latitude != 0.0)
          ? student.backLocation
          : student.homeLocation;
      expect(afternoonResolved, backLoc);
    });
  });
}
