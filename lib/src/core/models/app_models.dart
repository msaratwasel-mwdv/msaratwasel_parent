import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/app_config.dart';

enum StudentStatus {
  // 5 distinct trip-cycle states
  waitingAtHome,   // Step 1: Morning - waiting for bus at home
  onBusToSchool,   // Step 2: On bus heading to school
  atSchool,        // Step 3: At school
  onBusToHome,     // Step 4: On bus heading back home
  arrivedHome,     // Step 5: Arrived home after school

  // Legacy/utility states (kept for compatibility)
  onBus,           // Generic on bus (fallback)
  atHome,          // Generic at home (fallback)
  notBoarded,
  late,
}

enum BusState { enRoute, atSchool, atHome }

enum AttendanceDirection { outbound, inbound, fullDay }

enum NotificationType {
  approach,
  checkIn,
  checkOut,
  arrival,
  delay,
  routeChange,
  absence,
  lateBoarding,
  schoolAlert,
  supervisorMessage,
  chat,
}

extension NotificationTypeX on NotificationType {
  String label(bool arabic) {
    switch (this) {
      case NotificationType.approach:
        return arabic ? 'اقتراب الحافلة' : 'Bus approaching';
      case NotificationType.checkIn:
        return arabic ? 'صعود' : 'Check-in';
      case NotificationType.checkOut:
        return arabic ? 'نزول' : 'Check-out';
      case NotificationType.arrival:
        return arabic ? 'وصول' : 'Arrival';
      case NotificationType.delay:
        return arabic ? 'تأخير' : 'Delay';
      case NotificationType.routeChange:
        return arabic ? 'تغيير مسار' : 'Route change';
      case NotificationType.absence:
        return arabic ? 'غياب' : 'Absence';
      case NotificationType.lateBoarding:
        return arabic ? 'تأخر في الصعود' : 'Late boarding';
      case NotificationType.schoolAlert:
        return arabic ? 'تنبيه المدرسة' : 'School alert';
      case NotificationType.supervisorMessage:
        return arabic ? 'رسالة من المشرفة' : 'Supervisor message';
      case NotificationType.chat:
        return arabic ? 'محادثة جديدة' : 'New chat message';
    }
  }

  // Note: Since AppModels is in core, we might not want to import material here
  // to keep it pure. However, in this project it seems acceptable or we use
  // a separate UI mapper. Given the current structure, I'll keep it simple
  // or use a mapper in the UI layer if needed.
  // Actually, I'll check if material is already imported in some models.
  // It's not. So I'll move the Icon mapping to a UI extension or keep it in the page but cleaner.
}

class BusStaffInfo {
  const BusStaffInfo({required this.id, required this.name, this.phone, this.imageUrl});

  final int id;
  final String name;
  final String? phone;
  final String? imageUrl;

  factory BusStaffInfo.fromJson(Map<String, dynamic> json) {
    return BusStaffInfo(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }
}

class BusInfo {
  const BusInfo({
    required this.id,
    required this.number,
    required this.plate,
    this.driver,
    this.supervisor,
  });

  final String id;
  final String number;
  final String plate;
  final BusStaffInfo? driver;
  final BusStaffInfo? supervisor;

  factory BusInfo.fromJson(Map<String, dynamic> json) {
    return BusInfo(
      id: json['id'].toString(),
      number: json['bus_number'] as String? ?? '',
      plate: json['plate_number'] as String? ?? '',
      driver: json['driver'] != null
          ? BusStaffInfo.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
      supervisor: json['supervisor'] != null
          ? BusStaffInfo.fromJson(json['supervisor'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Student {
  const Student({
    required this.id,
    required this.name,
    required this.grade,
    required this.schoolId,
    required this.bus,
    required this.status,
    this.nameEn,
    this.nationalId,
    this.gender,
    this.studentCode,
    this.suggestedDirection,
    this.avatarUrl,
    this.tripCount = 0,
    this.attendancePercentage = 0,
    this.homeLocation,
    this.locationNote,
    this.schoolName,
    this.schoolLocation,
    this.waitingAtHomeTime,
    this.onBusToSchoolTime,
    this.atSchoolTime,
    this.onBusToHomeTime,
    this.arrivedHomeTime,
  });

  final String id;
  final String name;
  final String? nameEn;
  final String grade;
  final String schoolId;
  final String? nationalId;
  final String? gender;
  final String? studentCode;
  final BusInfo bus;
  final StudentStatus status;
  final String? suggestedDirection;
  final String? avatarUrl;     // image_url from API
  final int tripCount;         // trip_count from API
  final int attendancePercentage; // attendance_percentage from API
  final LatLng? homeLocation;
  final String? locationNote;
  final String? schoolName;
  final String? schoolLocation;
  
  /// Returns true if the student has a valid home location (non-null and non-zero)
  bool get hasLocation => homeLocation != null && homeLocation!.latitude != 0 && homeLocation!.longitude != 0;

  // Timestamps for the 5-step cycle
  final DateTime? waitingAtHomeTime;
  final DateTime? onBusToSchoolTime;
  final DateTime? atSchoolTime;
  final DateTime? onBusToHomeTime;
  final DateTime? arrivedHomeTime;

  /// إنشاء كائن Student من استجابة الـ API
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      nameEn: json['name_en'] as String?,
      nationalId: json['national_id'] as String?,
      gender: json['gender'] as String?,
      studentCode: json['student_code'] as String?,
      grade: json['grade'] as String? ?? '',
      schoolId: json['school']?['id']?.toString() ?? '',
      bus: json['bus'] != null
          ? BusInfo.fromJson(json['bus'] as Map<String, dynamic>)
          : const BusInfo(id: '', number: '-', plate: '-'),
      status: _deriveStudentStatus(
        json['status'] as String?,
        json['suggested_direction'] as String?,
      ),
      suggestedDirection: json['suggested_direction'] as String?,
      avatarUrl: _fixImageUrl(json['image_url'] as String?),
      tripCount: json['trip_count'] as int? ?? 0,
      attendancePercentage: json['attendance_percentage'] as int? ?? 0,
      homeLocation: (json['home_lat'] != null && json['home_lng'] != null)
          ? LatLng(
              double.tryParse(json['home_lat'].toString()) ?? 0.0,
              double.tryParse(json['home_lng'].toString()) ?? 0.0,
            )
          : null,
      locationNote: json['location_note'] as String?,
      schoolName: json['school']?['name'] as String?,
      schoolLocation: json['school']?['location'] as String?,
      // These will be populated by AppController when updates arrive
      waitingAtHomeTime: null,
      onBusToSchoolTime: null,
      atSchoolTime: null,
      onBusToHomeTime: null,
      arrivedHomeTime: null,
    );
  }

  static String? _fixImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    // Remove leading slash if present
    final path = url.startsWith('/') ? url.substring(1) : url;
    // Assume storage path if it doesn't contain storage/
    final fullPath = path.contains('storage/') ? path : 'storage/$path';
    
    // Use the base URL from AppConfig instead of a hardcoded one
    final baseUrl = AppConfig.apiBaseUrl.replaceAll('/api/', '');
    return '$baseUrl/$fullPath';
  }

  /// Derives the 5-state trip cycle status from API status + direction
  static StudentStatus _deriveStudentStatus(String? rawStatus, String? direction) {
    switch (rawStatus) {
      case 'onBus':
        if (direction == 'to_school') return StudentStatus.onBusToSchool;
        if (direction == 'to_home') return StudentStatus.onBusToHome;
        return StudentStatus.onBus; // fallback
      case 'atSchool':
        return StudentStatus.atSchool;
      case 'atHome':
        if (direction == 'to_home') return StudentStatus.arrivedHome;
        return StudentStatus.waitingAtHome; // morning default
      case 'notBoarded':
        return StudentStatus.notBoarded;
      case 'late':
        return StudentStatus.late;
      default:
        return StudentStatus.waitingAtHome;
    }
  }

  Student copyWith({
    String? name,
    String? nameEn,
    String? grade,
    String? schoolId,
    String? nationalId,
    String? gender,
    String? studentCode,
    BusInfo? bus,
    StudentStatus? status,
    String? avatarUrl,
    int? tripCount,
    int? attendancePercentage,
    LatLng? homeLocation,
    String? locationNote,
    String? schoolName,
    String? schoolLocation,
    DateTime? waitingAtHomeTime,
    DateTime? onBusToSchoolTime,
    DateTime? atSchoolTime,
    DateTime? onBusToHomeTime,
    DateTime? arrivedHomeTime,
  }) {
    return Student(
      id: id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      grade: grade ?? this.grade,
      schoolId: schoolId ?? this.schoolId,
      nationalId: nationalId ?? this.nationalId,
      gender: gender ?? this.gender,
      studentCode: studentCode ?? this.studentCode,
      bus: bus ?? this.bus,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      tripCount: tripCount ?? this.tripCount,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
      homeLocation: homeLocation ?? this.homeLocation,
      locationNote: locationNote ?? this.locationNote,
      schoolName: schoolName ?? this.schoolName,
      schoolLocation: schoolLocation ?? this.schoolLocation,
      waitingAtHomeTime: waitingAtHomeTime ?? this.waitingAtHomeTime,
      onBusToSchoolTime: onBusToSchoolTime ?? this.onBusToSchoolTime,
      atSchoolTime: atSchoolTime ?? this.atSchoolTime,
      onBusToHomeTime: onBusToHomeTime ?? this.onBusToHomeTime,
      arrivedHomeTime: arrivedHomeTime ?? this.arrivedHomeTime,
    );
  }
}


class TrackingSnapshot {
  const TrackingSnapshot({
    required this.lat,
    required this.lng,
    required this.speedKmh,
    required this.etaMinutes,
    required this.distanceKm,
    required this.studentsOnBoard,
    required this.busState,
    required this.updatedAt,
    required this.routeDescription,
    this.driverName,
    this.driverImageUrl,
    this.tripType,
    this.busNumber,
    this.plateNumber,
    this.polylinePoints = const [],
  });

  final double lat;
  final double lng;
  final double speedKmh;
  final int etaMinutes;
  final double distanceKm;
  final int studentsOnBoard;
  final BusState busState;
  final DateTime updatedAt;
  final String routeDescription;
  final String? driverName;
  final String? driverImageUrl;
  final String? tripType;
  final String? busNumber;
  final String? plateNumber;
  final List<LatLng> polylinePoints;
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.time,
    this.read = false,
    this.data = const {},
  });

  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime time;
  bool read;
  final Map<String, dynamic> data;

  /// Maps the raw Laravel `type` string to [NotificationType].
  static NotificationType parseType(String? raw) {
    switch (raw) {
      case 'bus_boarding_morning':
      case 'bus_boarding_afternoon':
      case 'bus_boarding':
      case 'student_boarded':
        return NotificationType.checkIn;
      case 'student_alighted':
      case 'bus_alighting':
      case 'alighting':
        return NotificationType.checkOut;
      case 'bus_proximity':
      case 'bus_approaching':
      case 'near_me':
        return NotificationType.approach;
      case 'bus_arrived':
        return NotificationType.arrival;
      case 'bus_delay':
        return NotificationType.delay;
      case 'bus_route_change':
        return NotificationType.routeChange;
      case 'student_absence':
        return NotificationType.absence;
      case 'late_boarding':
        return NotificationType.lateBoarding;
      case 'school_alert':
      case 'school_announcement':
        return NotificationType.schoolAlert;
      case 'supervisor_message':
        return NotificationType.supervisorMessage;
      case 'new_message':
        return NotificationType.chat;
      default:
        return NotificationType.schoolAlert;
    }
  }
}

class AttendanceEntry {
  AttendanceEntry({
    required this.date,
    required this.direction,
    required this.status,
    this.note,
  });

  final DateTime date;
  final AttendanceDirection direction;
  final String status;
  final String? note;
}

class TripEntry {
  const TripEntry({
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.arrival,
    required this.delayed,
    required this.events,
  });

  final DateTime date;
  final DateTime checkIn;
  final DateTime checkOut;
  final DateTime arrival;
  final bool delayed;
  final List<String> events;

  DateTime get boardingTime => checkIn;
  DateTime get dropOffTime => arrival;
}

class MessageItem {
  const MessageItem({
    required this.id,
    required this.sender,
    required this.text,
    required this.time,
    required this.incoming,
    this.mediaUrl,
  });

  final String id;
  final String sender;
  final String text;
  final DateTime time;
  final bool incoming;
  final String? mediaUrl;
}
