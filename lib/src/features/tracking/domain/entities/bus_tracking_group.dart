import 'bus_tracking.dart';
import '../../../../core/models/app_models.dart';

class BusTrackingGroup {
  final String busId;
  final String? busNumber;
  final BusTracking? tracking;
  final List<Student> students;
  final String? tripStatus;

  final int? totalStudentsOnBoard;
  final String? busPlate;
  final String? tripType;
  final DateTime? startTime;
  final int? totalStudentsCount;
  final BusStaffInfo? driver;
  final BusStaffInfo? supervisor;

  BusTrackingGroup({
    required this.busId,
    this.busNumber,
    this.busPlate,
    this.tracking,
    required this.students,
    this.tripStatus,
    this.totalStudentsOnBoard,
    this.totalStudentsCount,
    this.driver,
    this.supervisor,
    this.tripType,
    this.startTime,
  });

  BusTrackingGroup copyWith({
    String? busId,
    String? busNumber,
    BusTracking? tracking,
    List<Student>? students,
    int? totalStudentsOnBoard,
    String? busPlate,
    String? tripStatus,
    String? tripType,
    DateTime? startTime,
    int? totalStudentsCount,
    BusStaffInfo? driver,
    BusStaffInfo? supervisor,
  }) {
    return BusTrackingGroup(
      busId: busId ?? this.busId,
      busNumber: busNumber ?? this.busNumber,
      busPlate: busPlate ?? this.busPlate,
      tracking: tracking ?? this.tracking,
      students: students ?? this.students,
      tripStatus: tripStatus ?? this.tripStatus,
      totalStudentsOnBoard: totalStudentsOnBoard ?? this.totalStudentsOnBoard,
      totalStudentsCount: totalStudentsCount ?? this.totalStudentsCount,
      driver: driver ?? this.driver,
      supervisor: supervisor ?? this.supervisor,
      tripType: tripType ?? this.tripType,
      startTime: startTime ?? this.startTime,
    );
  }

  String get routeDescription {
    if (tripType == 'to_school') return 'To School';
    if (tripType == 'to_home') return 'To Home';
    return '--';
  }

  int get myStudentsCount => students.length;

  bool get isActiveTrip {
    // Explicit active statuses from API
    const activeStatuses = {
      'to_school',
      'to_home',
      'started',
      'en_route',
      'active',
    };

    // A trip is active IF the status is in the active list.
    // tracking != null is no longer enough to consider it active if status is finished.
    return tripStatus != null && activeStatuses.contains(tripStatus);
  }

  BusState get busState {
    switch (tripStatus) {
      case 'to_school':
      case 'to_home':
      case 'started':
      case 'en_route':
      case 'active':
        return BusState.enRoute;
      case 'finished':
      case 'at_school':
      case 'completed':
        return BusState.atSchool;
      default:
        return BusState.atHome;
    }
  }
}
