import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../config/app_config.dart';

enum StudentStatus {
  // 5 distinct trip-cycle states
  waitingAtHome, // Step 1: Morning - waiting for bus at home
  onBusToSchool, // Step 2: On bus heading to school
  atSchool, // Step 3: At school
  onBusToHome, // Step 4: On bus heading back home
  arrivedHome, // Step 5: Arrived home after school
  // Legacy/utility states (kept for compatibility)
  onBus, // Generic on bus (fallback)
  atHome, // Generic at home (fallback)
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
  absenceApproved,
  absenceRejected,
  lateBoarding,
  schoolAlert,
  supervisorMessage,
  chat,
  locationRequest,
  locationApproved,
  locationRejected,
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
      case NotificationType.absenceApproved:
        return arabic ? 'تمت الموافقة على الغياب' : 'Absence approved';
      case NotificationType.absenceRejected:
        return arabic ? 'تم رفض طلب الغياب' : 'Absence request rejected';
      case NotificationType.lateBoarding:
        return arabic ? 'تأخر في الصعود' : 'Late boarding';
      case NotificationType.schoolAlert:
        return arabic ? 'تنبيه المدرسة' : 'School alert';
      case NotificationType.supervisorMessage:
        return arabic ? 'رسالة من المشرفة' : 'Supervisor message';
      case NotificationType.chat:
        return arabic ? 'محادثة جديدة' : 'New chat message';
      case NotificationType.locationRequest:
        return arabic ? 'طلب تغيير موقع' : 'Location change request';
      case NotificationType.locationApproved:
        return arabic ? 'تمت الموافقة على الموقع' : 'Location approved';
      case NotificationType.locationRejected:
        return arabic ? 'تم رفض طلب الموقع' : 'Location request rejected';
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
  const BusStaffInfo({
    required this.id,
    required this.name,
    this.phone,
    this.imageUrl,
  });

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
    this.status,
    this.latitude,
    this.longitude,
    this.totalStudents,
    this.onBoardCount,
    this.speed,
    this.etaMinutes,
    this.startTime,
  });

  final String id;
  final String number;
  final String plate;
  final BusStaffInfo? driver;
  final BusStaffInfo? supervisor;
  final String? status;
  final double? latitude;
  final double? longitude;
  final int? totalStudents;
  final int? onBoardCount;
  final double? speed;
  final int? etaMinutes;
  final DateTime? startTime;

  BusInfo copyWith({
    String? id,
    String? number,
    String? plate,
    BusStaffInfo? driver,
    BusStaffInfo? supervisor,
    String? status,
    double? latitude,
    double? longitude,
    int? totalStudents,
    int? onBoardCount,
    double? speed,
    int? etaMinutes,
    DateTime? startTime,
  }) {
    return BusInfo(
      id: id ?? this.id,
      number: number ?? this.number,
      plate: plate ?? this.plate,
      driver: driver ?? this.driver,
      supervisor: supervisor ?? this.supervisor,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      totalStudents: totalStudents ?? this.totalStudents,
      onBoardCount: onBoardCount ?? this.onBoardCount,
      speed: speed ?? this.speed,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      startTime: startTime ?? this.startTime,
    );
  }

  factory BusInfo.fromJson(Map<String, dynamic> json) {
    return BusInfo(
      id: json['id']?.toString() ?? '',
      number: json['bus_number']?.toString() ?? '',
      plate: json['plate_number']?.toString() ?? '',
      status: (json['trip_status'] ?? json['status'])?.toString(),
      driver: json['driver'] != null
          ? BusStaffInfo.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
      supervisor: json['supervisor'] != null
          ? BusStaffInfo.fromJson(json['supervisor'] as Map<String, dynamic>)
          : null,
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      totalStudents: int.tryParse(
        json['total_students']?.toString() ??
            json['students_count']?.toString() ??
            '',
      ),
      onBoardCount: int.tryParse(
        json['on_board_count']?.toString() ??
            json['on_board']?.toString() ??
            '',
      ),
      speed: double.tryParse(
        json['speed']?.toString() ?? json['speed_kmh']?.toString() ?? '',
      ),
      etaMinutes: int.tryParse(json['eta_minutes']?.toString() ?? ''),
      startTime: DateTime.tryParse(
        json['departure_time']?.toString() ??
            json['start_time']?.toString() ??
            '',
      ),
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
    this.schoolCoords,
    this.waitingAtHomeTime,
    this.onBusToSchoolTime,
    this.atSchoolTime,
    this.onBusToHomeTime,
    this.arrivedHomeTime,
    this.etaMinutes,
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
  final String? avatarUrl; // image_url from API
  final int tripCount; // trip_count from API
  final int attendancePercentage; // attendance_percentage from API
  final LatLng? homeLocation;
  final String? locationNote;
  final String? schoolName;
  final String? schoolLocation;
  final LatLng? schoolCoords;

  /// Returns true if the student has a valid home location (non-null and non-zero)
  bool get hasLocation =>
      homeLocation != null &&
      homeLocation!.latitude != 0 &&
      homeLocation!.longitude != 0;

  /// Returns a displayable name for the student, falling back to code or ID if missing.
  String get displayName {
    if (name.trim().isNotEmpty) return name;
    if (studentCode != null && studentCode!.trim().isNotEmpty) return studentCode!;
    return id;
  }

  // Timestamps for the 5-step cycle
  final DateTime? waitingAtHomeTime;
  final DateTime? onBusToSchoolTime;
  final DateTime? atSchoolTime;
  final DateTime? onBusToHomeTime;
  final DateTime? arrivedHomeTime;
  final int? etaMinutes; // New: ETA in minutes from API

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
      status: deriveStudentStatus(
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
      schoolCoords: (json['school']?['latitude'] != null && json['school']?['longitude'] != null)
          ? LatLng(
              double.tryParse(json['school']['latitude'].toString()) ?? 0.0,
              double.tryParse(json['school']['longitude'].toString()) ?? 0.0,
            )
          : null,
      // These will be populated by AppController when updates arrive
      waitingAtHomeTime: null,
      onBusToSchoolTime: null,
      atSchoolTime: null,
      onBusToHomeTime: null,
      arrivedHomeTime: null,
      etaMinutes: json['eta_minutes'] as int?,
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
  static StudentStatus deriveStudentStatus(
    String? rawStatus,
    String? direction,
  ) {
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
    LatLng? schoolCoords,
    DateTime? waitingAtHomeTime,
    DateTime? onBusToSchoolTime,
    DateTime? atSchoolTime,
    DateTime? onBusToHomeTime,
    DateTime? arrivedHomeTime,
    int? etaMinutes,
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
      schoolCoords: schoolCoords ?? this.schoolCoords,
      waitingAtHomeTime: waitingAtHomeTime ?? this.waitingAtHomeTime,
      onBusToSchoolTime: onBusToSchoolTime ?? this.onBusToSchoolTime,
      atSchoolTime: atSchoolTime ?? this.atSchoolTime,
      onBusToHomeTime: onBusToHomeTime ?? this.onBusToHomeTime,
      arrivedHomeTime: arrivedHomeTime ?? this.arrivedHomeTime,
      etaMinutes: etaMinutes ?? this.etaMinutes,
    );
  }
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    this.titleEn,
    required this.body,
    this.bodyEn,
    this.senderName,
    this.senderNameEn,
    required this.type,
    required this.time,
    this.correlationId,
    this.read = false,
    this.data = const {},
  });

  final String id;
  final String? correlationId;
  final String title;
  final String? titleEn;
  final String body;
  final String? bodyEn;
  final String? senderName;
  final String? senderNameEn;
  final NotificationType type;
  final DateTime time;
  bool read;
  final Map<String, dynamic> data;

  String _pickLanguage(String text, bool isEn) {
    if (text.isEmpty) return text;

    // Common separators used for bilingual text
    final separators = [' / ', ' /', '/ ', '/', ' | ', ' |', '| ', '|'];
    for (var sep in separators) {
      if (text.contains(sep)) {
        final parts = text.split(sep);
        if (parts.length >= 2) {
          // Typically: Index 0 is Arabic, Index 1 is English
          // Return based on isEn flag
          return isEn ? parts[1].trim() : parts[0].trim();
        }
      }
    }
    return text;
  }

  String getDisplayTitle(bool isEn) {
    if (isEn && titleEn != null && titleEn!.isNotEmpty) return titleEn!;
    return _pickLanguage(title, isEn);
  }

  String getDisplayBody(bool isEn) {
    if (isEn && bodyEn != null && bodyEn!.isNotEmpty) return bodyEn!;

    // Translation fallback for Absence notification from website/system
    if (isEn && type == NotificationType.absence) {
      if (body.contains('لم يحضر')) {
        return body
            .replaceAll('الطالب', 'Student')
            .replaceAll('لم يحضر في الحافلة اليوم',
                'did not attend the bus today');
      }
    }

    return _pickLanguage(body, isEn);
  }

  String getDisplaySender(bool isEn) =>
      (isEn && senderNameEn != null && senderNameEn!.isNotEmpty)
          ? senderNameEn!
          : (senderName ?? '');

  factory AppNotification.fromMap(Map<String, dynamic> data) {
    return AppNotification(
      id: data['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      correlationId: data['correlation_id']?.toString(),
      title: data['title'] as String? ?? data['title_ar'] as String? ?? '',
      titleEn: data['title_en'] as String? ?? data['titleEn'] as String?,
      body: data['message'] as String? ??
          data['body'] as String? ??
          data['content'] as String? ??
          data['content_ar'] as String? ??
          '',
      bodyEn: data['message_en'] as String? ??
          data['body_en'] as String? ??
          data['content_en'] as String? ??
          data['bodyEn'] as String?,
      senderName: data['sender_name'] as String? ??
          data['from_user_name'] as String? ??
          data['sender'] as String?,
      senderNameEn: data['sender_name_en'] as String? ??
          data['from_user_name_en'] as String?,
      type: parseType(data['type'] as String?),
      time: DateTime.tryParse(data['created_at']?.toString() ?? '') ??
          DateTime.now(),
      data: data,
    );
  }

  factory AppNotification.fromFcm(RemoteMessage message) {
    final data = message.data;
    final type = parseType(data['type'] as String?);

    // Prioritize the database ID for deduplication with real-time events
    final dbId = data['notification_id']?.toString() ??
        data['id']?.toString() ??
        message.messageId;

    return AppNotification(
      id: dbId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      correlationId: data['correlation_id']?.toString(),
      title: message.notification?.title ??
          data['title'] ??
          data['title_ar'] ??
          '',
      titleEn: data['title_en'] as String? ?? data['titleEn'] as String?,
      body: message.notification?.body ??
          data['body'] ??
          data['message'] ??
          data['content'] ??
          '',
      bodyEn: data['message_en'] as String? ??
          data['body_en'] as String? ??
          data['content_en'] as String? ??
          data['bodyEn'] as String?,
      senderName: data['sender_name'] as String? ?? data['sender'] as String?,
      senderNameEn: data['sender_name_en'] as String?,
      type: type,
      time: DateTime.now(),
      data: data,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'correlation_id': correlationId,
      'title': title,
      'title_en': titleEn,
      'body': body,
      'body_en': bodyEn,
      'sender_name': senderName,
      'sender_name_en': senderNameEn,
      'type': type.toString().split('.').last,
      'time': time.toIso8601String(),
      'read': read,
      'data': data,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      correlationId: json['correlation_id'] as String?,
      title: json['title'] as String,
      titleEn: json['title_en'] as String?,
      body: json['body'] as String,
      bodyEn: json['body_en'] as String?,
      senderName: json['sender_name'] as String?,
      senderNameEn: json['sender_name_en'] as String?,
      type: parseType(json['type'] as String?),
      time: DateTime.parse(json['time'] as String),
      read: json['read'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }

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
      case 'absence_approved':
        return NotificationType.absenceApproved;
      case 'absence_rejected':
        return NotificationType.absenceRejected;
      case 'late_boarding':
        return NotificationType.lateBoarding;
      case 'school_alert':
      case 'school_announcement':
        return NotificationType.schoolAlert;
      case 'supervisor_message':
        return NotificationType.supervisorMessage;
      case 'new_message':
      case 'chat':
        return NotificationType.chat;
      case 'location_request':
        return NotificationType.locationRequest;
      case 'location_approved':
        return NotificationType.locationApproved;
      case 'location_rejected':
        return NotificationType.locationRejected;
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

class LocationChangeRequest {
  const LocationChangeRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.createdAt,
    required this.status,
    this.newLatitude,
    this.newLongitude,
    this.newAddress,
    this.rejectionReason,
  });

  final String id;
  final String studentId;
  final String studentName;
  final DateTime createdAt;
  final String status;
  final double? newLatitude;
  final double? newLongitude;
  final String? newAddress;
  final String? rejectionReason;

  factory LocationChangeRequest.fromJson(Map<String, dynamic> json) {
    return LocationChangeRequest(
      id: json['id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      studentName: json['student_name'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      status: json['status'] as String? ?? 'pending',
      newLatitude: double.tryParse(json['new_latitude']?.toString() ?? ''),
      newLongitude: double.tryParse(json['new_longitude']?.toString() ?? ''),
      newAddress: json['new_address'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}
