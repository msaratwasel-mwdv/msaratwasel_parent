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
  });

  final String id;
  final String name;
  final String grade;
  final String schoolId;
  final BusInfo bus;
  final StudentStatus status;
  final String? avatarUrl;
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
