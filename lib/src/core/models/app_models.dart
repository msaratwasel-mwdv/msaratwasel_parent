import 'package:google_maps_flutter/google_maps_flutter.dart';

enum StudentStatus { onBus, atSchool, atHome, notBoarded, late }

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
    }
  }

  // Note: Since AppModels is in core, we might not want to import material here
  // to keep it pure. However, in this project it seems acceptable or we use
  // a separate UI mapper. Given the current structure, I'll keep it simple
  // or use a mapper in the UI layer if needed.
  // Actually, I'll check if material is already imported in some models.
  // It's not. So I'll move the Icon mapping to a UI extension or keep it in the page but cleaner.
}

class BusInfo {
  const BusInfo({required this.id, required this.number, required this.plate});

  final String id;
  final String number;
  final String plate;
}

class Student {
  const Student({
    required this.id,
    required this.name,
    required this.grade,
    required this.schoolId,
    required this.bus,
    required this.status,
    this.avatarUrl,
    this.homeLocation,
    this.locationNote,
  });

  final String id;
  final String name;
  final String grade;
  final String schoolId;
  final BusInfo bus;
  final StudentStatus status;
  final String? avatarUrl;
  final LatLng? homeLocation;
  final String? locationNote;
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
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.time,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime time;
  bool read;

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
