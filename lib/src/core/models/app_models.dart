import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
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
  adminAnnouncement,
  locationRequest,
  locationApproved,
  locationRejected,
  tripStarted,
  tripEnded,
  schoolAttendance,
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
      case NotificationType.adminAnnouncement:
        return arabic ? 'إعلان من المدرسة' : 'School announcement';
      case NotificationType.locationRequest:
        return arabic ? 'طلب تغيير موقع' : 'Location change request';
      case NotificationType.locationApproved:
        return arabic ? 'تمت الموافقة على الموقع' : 'Location approved';
      case NotificationType.locationRejected:
        return arabic ? 'تم رفض طلب الموقع' : 'Location request rejected';
      case NotificationType.tripStarted:
        return arabic ? 'بدأت الرحلة' : 'Trip started';
      case NotificationType.tripEnded:
        return arabic ? 'انتهت الرحلة' : 'Trip ended';
      case NotificationType.schoolAttendance:
        return arabic ? 'تحديث الحضور' : 'Attendance update';
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
    this.nameEn,
    this.phone,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String? nameEn;
  final String? phone;
  final String? imageUrl;

  String getLocalizedName(String languageCode) {
    if (languageCode.toLowerCase() == 'en') {
      return (nameEn != null && nameEn!.trim().isNotEmpty) ? nameEn! : name;
    }
    return name;
  }

  factory BusStaffInfo.fromJson(Map<String, dynamic> json) {
    return BusStaffInfo(
      id: json['id'] is int 
          ? json['id'] as int 
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? json['nameEn'] as String?,
      phone: json['phone'] as String?,
      imageUrl: AppConfig.normalizeImageUrl(json['image_url'] as String?),
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
    this.targetLatitude,
    this.targetLongitude,
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
  final double? targetLatitude;
  final double? targetLongitude;

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
    double? targetLatitude,
    double? targetLongitude,
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
      targetLatitude: targetLatitude ?? this.targetLatitude,
      targetLongitude: targetLongitude ?? this.targetLongitude,
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
      )?.toLocal(),
      targetLatitude: double.tryParse(json['target_lat']?.toString() ?? ''),
      targetLongitude: double.tryParse(json['target_lng']?.toString() ?? ''),
    );
  }
}

class Student {
  const Student({
    required this.id,
    required this.name,
    required this.grade,
    this.gradeEn,
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
    this.pendingLocation,
  });

  final String id;
  final String name;
  final String? nameEn;
  final String grade;
  final String? gradeEn;
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
  final Map<String, dynamic>? pendingLocation;

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

  String getLocalizedName(String languageCode) {
    if (languageCode == 'en' && nameEn != null && nameEn!.trim().isNotEmpty) {
      return nameEn!;
    }
    return displayName;
  }

  String getLocalizedGrade(String languageCode) {
    if (languageCode == 'en' && gradeEn != null && gradeEn!.trim().isNotEmpty) {
      return gradeEn!;
    }
    return grade;
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
      nameEn: json['name_en'] as String? ?? json['nameEn'] as String?,
      nationalId: json['national_id'] as String?,
      gender: json['gender'] as String?,
      studentCode: json['student_code'] as String?,
      grade: json['grade'] as String? ?? '',
      gradeEn: json['grade_en'] as String?,
      schoolId: json['school']?['id']?.toString() ?? '',
      bus: json['bus'] != null
          ? BusInfo.fromJson(json['bus'] as Map<String, dynamic>)
          : const BusInfo(id: '', number: '-', plate: '-'),
      status: deriveStudentStatus(
        json['status'] as String?,
        json['suggested_direction'] as String?,
        arrivedHomeTime: json['arrived_home_time'] != null ? DateTime.tryParse(json['arrived_home_time'])?.toLocal() : null,
        onBusToHomeTime: json['on_bus_to_home_time'] != null ? DateTime.tryParse(json['on_bus_to_home_time'])?.toLocal() : null,
        atSchoolTime: json['at_school_time'] != null ? DateTime.tryParse(json['at_school_time'])?.toLocal() : null,
        onBusToSchoolTime: json['on_bus_to_school_time'] != null ? DateTime.tryParse(json['on_bus_to_school_time'])?.toLocal() : null,
        waitingAtHomeTime: json['waiting_at_home_time'] != null ? DateTime.tryParse(json['waiting_at_home_time'])?.toLocal() : null,
      ),
      suggestedDirection: json['suggested_direction'] as String?,
      avatarUrl: AppConfig.normalizeImageUrl(json['image_url'] as String?),
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
      waitingAtHomeTime: json['waiting_at_home_time'] != null ? DateTime.tryParse(json['waiting_at_home_time'])?.toLocal() : null,
      onBusToSchoolTime: json['on_bus_to_school_time'] != null ? DateTime.tryParse(json['on_bus_to_school_time'])?.toLocal() : null,
      atSchoolTime: json['at_school_time'] != null ? DateTime.tryParse(json['at_school_time'])?.toLocal() : null,
      onBusToHomeTime: json['on_bus_to_home_time'] != null ? DateTime.tryParse(json['on_bus_to_home_time'])?.toLocal() : null,
      arrivedHomeTime: json['arrived_home_time'] != null ? DateTime.tryParse(json['arrived_home_time'])?.toLocal() : null,
      etaMinutes: json['eta_minutes'] as int?,
      pendingLocation: json['pending_location'] as Map<String, dynamic>?,
    );
  }



  /// Derives the 5-state trip cycle status from API status + direction + timestamps
  static StudentStatus deriveStudentStatus(
    String? rawStatus,
    String? direction, {
    DateTime? arrivedHomeTime,
    DateTime? onBusToHomeTime,
    DateTime? atSchoolTime,
    DateTime? onBusToSchoolTime,
    DateTime? waitingAtHomeTime,
  }) {
    if (arrivedHomeTime != null) {
      return StudentStatus.arrivedHome;
    }
    if (onBusToHomeTime != null) {
      if (rawStatus == 'atHome' || rawStatus == 'arrivedHome') {
        return StudentStatus.arrivedHome;
      }
      return StudentStatus.onBusToHome;
    }
    if (atSchoolTime != null) {
      if (direction == 'to_home' || direction == 'back' || direction == 'return') {
        if (rawStatus == 'onBus') return StudentStatus.onBusToHome;
      }
      return StudentStatus.atSchool;
    }
    if (onBusToSchoolTime != null) {
      if (rawStatus == 'atSchool') return StudentStatus.atSchool;
      return StudentStatus.onBusToSchool;
    }
    if (waitingAtHomeTime != null) {
      if (rawStatus == 'onBus') return StudentStatus.onBusToSchool;
      return StudentStatus.waitingAtHome;
    }

    switch (rawStatus) {
      case 'onBus':
        if (direction == 'to_school' || direction == 'forth' || direction == 'morning') return StudentStatus.onBusToSchool;
        if (direction == 'to_home' || direction == 'back' || direction == 'return') return StudentStatus.onBusToHome;
        return StudentStatus.onBus; // fallback
      case 'atSchool':
        return StudentStatus.atSchool;
      case 'atHome':
        if (direction == 'to_home' || direction == 'back' || direction == 'return') return StudentStatus.arrivedHome;
        return StudentStatus.waitingAtHome; // morning default
      case 'waiting':
        if (direction == 'to_school' || direction == 'forth' || direction == 'morning') return StudentStatus.waitingAtHome;
        if (direction == 'to_home' || direction == 'back' || direction == 'return') return StudentStatus.onBusToHome;
        return StudentStatus.waitingAtHome;
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
    String? gradeEn,
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
    Map<String, dynamic>? pendingLocation,
  }) {
    return Student(
      id: this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      grade: grade ?? this.grade,
      gradeEn: gradeEn ?? this.gradeEn,
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
      pendingLocation: pendingLocation ?? this.pendingLocation,
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
    this.language,
    this.category,
    this.targetScreen,
    this.unreadCount,
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
  final String? language;
  final int? unreadCount;
  /// Backend payload: notification category (e.g. bus_tracking, chat, student_status)
  final String? category;
  /// Backend payload: target screen for deep-linking (e.g. map_page, chat_details)
  final String? targetScreen;
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
    if (isEn) {
      if (titleEn != null && titleEn!.isNotEmpty) return titleEn!;
      // If we are in English mode but titleEn is missing, try to pick it from title if title is bilingual
      return _pickLanguage(title, true);
    }
    // Arabic mode
    return _pickLanguage(title, false);
  }

  String getDisplayBody(bool isEn) {
    if (isEn) {
      if (bodyEn != null && bodyEn!.isNotEmpty) return bodyEn!;
      
      // Translation fallback for Absence notification from website/system
      if (type == NotificationType.absence) {
        if (body.contains('لم يحضر')) {
          return body
              .replaceAll('الطالب', 'Student')
              .replaceAll('لم يحضر في الحافلة اليوم',
                  'did not attend the bus today');
        }
      }
      
      return _pickLanguage(body, true);
    }
    // Arabic mode
    return _pickLanguage(body, false);
  }

  String getDisplaySender(bool isEn) =>
      (isEn && senderNameEn != null && senderNameEn!.isNotEmpty)
          ? senderNameEn!
          : (senderName ?? '');

  factory AppNotification.fromMap(Map<String, dynamic> rawData) {
    Map<String, dynamic>? nestedData;
    if (rawData['data'] is Map) {
      nestedData = Map<String, dynamic>.from(rawData['data']);
    } else if (rawData['data'] is String) {
      try {
        final decoded = jsonDecode(rawData['data']);
        if (decoded is Map) {
          nestedData = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
    
    final data = Map<String, dynamic>.from(rawData);
    if (nestedData != null) {
      data.addAll(nestedData);
    }
    
    final notificationId = data['notification_id']?.toString() ??
        nestedData?['notification_id']?.toString() ??
        data['message_id']?.toString() ??
        data['id']?.toString();

    // Extract category/target_screen from nested data or top-level
    final category = data['category']?.toString() ??
        nestedData?['category']?.toString() ??
        data['type']?.toString();
    final targetScreen = data['target_screen']?.toString() ??
        nestedData?['target_screen']?.toString();

    // Safe extraction helper
    String? pick(List<dynamic> options) {
      for (final opt in options) {
        final str = opt?.toString();
        if (str != null && str.trim().isNotEmpty) return str;
      }
      return null;
    }

    final String titleAr = pick([data['title_ar'], data['title'], data['sender_name'], nestedData?['title_ar'], nestedData?['title'], nestedData?['sender_name']]) ?? '';
    final String? titleEn = pick([data['title_en'], data['titleEn'], data['title_English'], data['sender_name_en'], nestedData?['title_en'], nestedData?['titleEn'], nestedData?['sender_name_en']]);

    final String messageAr = pick([data['message_ar'], data['message'], data['body'], data['messagePreview'], nestedData?['message_ar'], nestedData?['message'], nestedData?['body']]) ?? '';
    final String? messageEn = pick([data['message_en'], data['messageEn'], data['message_English'], data['body_en'], data['bodyEn'], nestedData?['message_en'], nestedData?['messageEn']]);

    return AppNotification(
      id: notificationId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      correlationId: data['correlation_id']?.toString() ?? 
                    nestedData?['correlation_id']?.toString() ?? 
                    notificationId,
      title: titleAr,
      titleEn: titleEn,
      body: messageAr,
      bodyEn: messageEn,
      senderName: data['sender_name']?.toString() ??
          data['from_user_name']?.toString() ??
          nestedData?['sender_name']?.toString(),
      senderNameEn: data['sender_name_en']?.toString() ??
          data['from_user_name_en']?.toString() ??
          nestedData?['sender_name_en']?.toString(),
      type: parseType(data['type']?.toString() ?? nestedData?['type']?.toString()),
      time: DateTime.tryParse(data['created_at']?.toString() ?? '') ?? DateTime.now(),
      read: (data['read'] == true || data['read'] == 1 || data['read'] == 'true' || data['status']?.toString() == 'read'),
      language: data['language']?.toString().toLowerCase() ?? nestedData?['language']?.toString().toLowerCase(),
      unreadCount: int.tryParse(data['unread_count']?.toString() ?? nestedData?['unread_count']?.toString() ?? ''),
      category: category,
      targetScreen: targetScreen,
      data: data,
    );
  }

  factory AppNotification.fromFcm(RemoteMessage message) {
    final rawData = message.data;
    Map<String, dynamic>? nestedData;
    if (rawData['data'] is Map) {
      nestedData = Map<String, dynamic>.from(rawData['data'] as Map);
    } else if (rawData['data'] is String) {
      try {
        final decoded = jsonDecode(rawData['data'] as String);
        if (decoded is Map) {
          nestedData = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    final data = Map<String, dynamic>.from(rawData);
    if (nestedData != null) {
      data.addAll(nestedData);
    }

    final type = parseType(data['type']?.toString());

    final dbId = data['notification_id']?.toString() ??
        data['id']?.toString() ??
        data['message_id']?.toString() ??
        message.messageId;

    // Safe extraction helper
    String? pick(List<dynamic> options) {
      for (final opt in options) {
        final str = opt?.toString();
        if (str != null && str.trim().isNotEmpty) return str;
      }
      return null;
    }

    final String titleAr = pick([data['title_ar'], data['title'], data['sender_name'], message.notification?.title]) ?? '';
    final String? titleEn = pick([data['title_en'], data['titleEn'], data['title_English'], data['sender_name_en'], message.notification?.title]);

    final String messageAr = pick([data['message_ar'], data['message'], data['body'], data['messagePreview'], message.notification?.body]) ?? '';
    final String? messageEn = pick([data['message_en'], data['messageEn'], data['message_English'], data['body_en'], data['bodyEn'], message.notification?.body]);

    return AppNotification(
      id: dbId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      correlationId: data['correlation_id']?.toString() ?? 
                    data['notification_id']?.toString() ?? 
                    data['message_id']?.toString() ?? 
                    message.messageId,
      title: titleAr,
      titleEn: titleEn,
      body: messageAr,
      bodyEn: messageEn,
      senderName: data['sender_name']?.toString() ?? data['sender']?.toString(),
      senderNameEn: data['sender_name_en']?.toString(),
      type: type,
      time: DateTime.now(),
      language: data['language']?.toString().toLowerCase(),
      unreadCount: int.tryParse(data['unread_count']?.toString() ?? ''),
      category: data['category']?.toString(),
      targetScreen: data['target_screen']?.toString(),
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
      'language': language,
      'category': category,
      'target_screen': targetScreen,
      'unread_count': unreadCount,
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
      language: json['language'] as String?,
      category: json['category'] as String?,
      targetScreen: json['target_screen'] as String?,
      unreadCount: json['unread_count'] as int?,
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Maps the raw Laravel `type` string to [NotificationType].
  /// Supports both snake_case (from backend) and camelCase (from toJson round-trip).
  static NotificationType parseType(String? raw) {
    switch (raw) {
      case 'bus_boarding_morning':
      case 'bus_boarding_afternoon':
      case 'bus_boarding':
      case 'student_boarded':
      case 'check_in': // Added
      case 'checkIn':
        return NotificationType.checkIn;
      case 'student_alighted':
      case 'bus_alighting':
      case 'alighting':
      case 'check_out': // Added
      case 'checkOut':
        return NotificationType.checkOut;
      case 'bus_proximity':
      case 'bus_approaching':
      case 'near_me':
      case 'approach':
        return NotificationType.approach;
      case 'bus_arrived':
      case 'arrival':
        return NotificationType.arrival;
      case 'bus_delay':
      case 'delay':
        return NotificationType.delay;
      case 'bus_route_change':
      case 'route_change': // Added
      case 'routeChange':
        return NotificationType.routeChange;
      case 'student_absence':
      case 'absence':
        return NotificationType.absence;
      case 'absence_approved':
      case 'absenceApproved':
      case 'absence_request_processed':
        return NotificationType.absenceApproved;
      case 'absence_rejected':
      case 'absenceRejected':
        return NotificationType.absenceRejected;
      case 'late_boarding':
      case 'lateBoarding':
        return NotificationType.lateBoarding;
      case 'school_alert':
      case 'school_announcement':
      case 'school_information':
      case 'School Information':
      case 'schoolAlert':
        return NotificationType.schoolAlert;
      case 'admin_announcement':
      case 'Admin Announcement':
      case 'adminAnnouncement':
        return NotificationType.adminAnnouncement;
      case 'supervisor_message':
      case 'supervisor_msg': // Added
      case 'supervisorMessage':
        return NotificationType.supervisorMessage;
      case 'new_message':
      case 'chat':
      case 'chat_message':
        return NotificationType.chat;
      case 'location_request':
      case 'locationRequest':
        return NotificationType.locationRequest;
      case 'location_approved':
      case 'locationApproved':
        return NotificationType.locationApproved;
      case 'location_rejected':
      case 'locationRejected':
        return NotificationType.locationRejected;
      case 'student_status': // Added: mapped to checkIn/checkOut based on data usually
        return NotificationType.arrival; // Fallback or specific status
      case 'address_change': // Added
        return NotificationType.locationApproved;
      case 'trip_started':
      case 'tripStarted':
        return NotificationType.tripStarted;
      case 'trip_ended':
      case 'tripEnded':
        return NotificationType.tripEnded;
      case 'school_attendance':
      case 'schoolAttendance':
      case 'attendance_update':
        return NotificationType.schoolAttendance;
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
