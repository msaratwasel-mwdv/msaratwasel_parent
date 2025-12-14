import 'package:flutter/material.dart';

import 'package:msaratwasel_user/src/core/models/app_models.dart';

class SampleData {
  SampleData._();

  static final bus1 = BusInfo(id: 'bus-21', number: '21', plate: 'ح م ل 3456');
  static final bus2 = BusInfo(id: 'bus-14', number: '14', plate: 'ن و ك 1298');

  static final students = <Student>[
    Student(
      id: 'st-1',
      name: 'سارة أحمد',
      grade: 'الصف الرابع',
      schoolId: '210345',
      bus: bus1,
      status: StudentStatus.onBus,
    ),
    Student(
      id: 'st-2',
      name: 'عبدالله محمد',
      grade: 'الصف الأول',
      schoolId: '210346',
      bus: bus2,
      status: StudentStatus.atHome,
    ),
  ];

  static final tracking = <String, TrackingSnapshot>{
    'st-1': TrackingSnapshot(
      lat: 24.7136,
      lng: 46.6753,
      speedKmh: 38,
      etaMinutes: 9,
      distanceKm: 2.7,
      studentsOnBoard: 14,
      busState: BusState.enRoute,
      updatedAt: DateTime.now().subtract(const Duration(seconds: 4)),
      routeDescription: 'طريق الملك عبدالله ⇢ شارع الجامعة ⇢ حي الندى',
    ),
    'st-2': TrackingSnapshot(
      lat: 24.7136,
      lng: 46.6753,
      speedKmh: 0,
      etaMinutes: 0,
      distanceKm: 0,
      studentsOnBoard: 0,
      busState: BusState.atHome,
      updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      routeDescription: 'لا توجد رحلة حالياً',
    ),
  };

  static List<AppNotification> notifications() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'n1',
        title: 'اقتراب الحافلة',
        body: 'الحافلة تبعد 5 دقائق عن المنزل.',
        type: NotificationType.approach,
        time: now.subtract(const Duration(minutes: 2)),
      ),
      AppNotification(
        id: 'n2',
        title: 'صعود الطالب',
        body: 'سارة صعدت للحافلة الساعة 6:55 ص.',
        type: NotificationType.checkIn,
        time: now.subtract(const Duration(minutes: 20)),
      ),
      AppNotification(
        id: 'n3',
        title: 'تنبيه المدرسة',
        body: 'غداً دوام جزئي بسبب فعالية رياضية.',
        type: NotificationType.schoolAlert,
        time: now.subtract(const Duration(hours: 3, minutes: 10)),
      ),
      AppNotification(
        id: 'n4',
        title: 'رسالة من المشرفة',
        body: 'يرجى تذكير سارة بإحضار بطاقة الدخول.',
        type: NotificationType.supervisorMessage,
        time: now.subtract(const Duration(hours: 6)),
      ),
    ];
  }

  static final messages = <MessageItem>[
    MessageItem(
      id: 'm1',
      sender: 'المشرفة نورة',
      text: 'صباح الخير، الحافلة على الطريق وستصل خلال 10 دقائق.',
      time: DateTime.now().subtract(const Duration(minutes: 12)),
      incoming: true,
    ),
    MessageItem(
      id: 'm2',
      sender: 'أنت',
      text: 'شكراً للتنبيه.',
      time: DateTime.now().subtract(const Duration(minutes: 11)),
      incoming: false,
    ),
    MessageItem(
      id: 'm3',
      sender: 'المشرفة نورة',
      text: 'تم صعود سارة للحافلة.',
      time: DateTime.now().subtract(const Duration(minutes: 5)),
      incoming: true,
    ),
  ];

  static final attendance = <AttendanceEntry>[
    AttendanceEntry(
      date: DateTime.now().subtract(const Duration(days: 1)),
      direction: AttendanceDirection.outbound,
      status: 'تم الإبلاغ بعدم الذهاب',
      note: 'الطالبة مريضة',
    ),
    AttendanceEntry(
      date: DateTime.now().subtract(const Duration(days: 2)),
      direction: AttendanceDirection.fullDay,
      status: 'حضرت',
    ),
  ];

  static final trips = <TripEntry>[
    TripEntry(
      date: DateTime.now().subtract(const Duration(days: 1)),
      checkIn: DateTime.now().subtract(const Duration(days: 1, hours: 9)),
      checkOut: DateTime.now().subtract(
        const Duration(days: 1, hours: 8, minutes: 30),
      ),
      arrival: DateTime.now().subtract(
        const Duration(days: 1, hours: 7, minutes: 50),
      ),
      delayed: false,
      events: const ['صعود 6:55 ص', 'وصول للمدرسة 7:35 ص'],
    ),
    TripEntry(
      date: DateTime.now().subtract(const Duration(days: 2)),
      checkIn: DateTime.now().subtract(const Duration(days: 2, hours: 9)),
      checkOut: DateTime.now().subtract(
        const Duration(days: 2, hours: 8, minutes: 22),
      ),
      arrival: DateTime.now().subtract(
        const Duration(days: 2, hours: 7, minutes: 44),
      ),
      delayed: true,
      events: const ['تأخير 6 دقائق بسبب ازدحام', 'تم الإبلاغ للمشرفة'],
    ),
  ];

  static String studentStatusText(StudentStatus status) {
    switch (status) {
      case StudentStatus.onBus:
        return 'في الحافلة';
      case StudentStatus.atSchool:
        return 'في المدرسة';
      case StudentStatus.atHome:
        return 'في المنزل';
      case StudentStatus.notBoarded:
        return 'لم يصعد';
      case StudentStatus.late:
        return 'متأخر';
    }
  }

  static IconData statusIcon(StudentStatus status) {
    switch (status) {
      case StudentStatus.onBus:
        return Icons.directions_bus_filled_outlined;
      case StudentStatus.atSchool:
        return Icons.school_outlined;
      case StudentStatus.atHome:
        return Icons.home_outlined;
      case StudentStatus.notBoarded:
        return Icons.hourglass_top_outlined;
      case StudentStatus.late:
        return Icons.warning_amber_outlined;
    }
  }
}
