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
      'in_progress',
      'awaiting_confirmation',
      'awaiting_video',
      'on_route',
    };

    final isExplicitlyActive = tripStatus != null && activeStatuses.contains(tripStatus);

    // Fallback: If any student in this group is currently on the bus
    bool hasStudentsOnBus = false;
    for (final student in students) {
      if (student.status == StudentStatus.onBus ||
          student.status == StudentStatus.onBusToSchool ||
          student.status == StudentStatus.onBusToHome) {
        hasStudentsOnBus = true;
        break;
      }
    }

    return isExplicitlyActive || hasStudentsOnBus;
  }

  DateTime? get resolvedStartTime {
    if (startTime != null) return startTime;

    DateTime? earliest;
    for (final student in students) {
      final times = [
        student.waitingAtHomeTime,
        student.onBusToSchoolTime,
        student.onBusToHomeTime,
        student.atSchoolTime,
        student.arrivedHomeTime,
      ];
      for (final t in times) {
        if (t != null) {
          if (earliest == null || t.isBefore(earliest)) {
            earliest = t;
          }
        }
      }
    }
    return earliest;
  }


  BusState get busState {
    switch (tripStatus) {
      case 'to_school':
      case 'to_home':
      case 'started':
      case 'en_route':
      case 'active':
      case 'in_progress':
      case 'awaiting_confirmation':
      case 'awaiting_video':
      case 'on_route':
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
