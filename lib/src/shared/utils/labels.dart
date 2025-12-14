import 'package:msaratwasel_user/src/core/models/app_models.dart';

class Labels {
  const Labels._();

  static String studentStatus(StudentStatus status, {required bool arabic}) {
    switch (status) {
      case StudentStatus.onBus:
        return arabic ? 'في الحافلة' : 'On the bus';
      case StudentStatus.atSchool:
        return arabic ? 'في المدرسة' : 'At school';
      case StudentStatus.atHome:
        return arabic ? 'في المنزل' : 'At home';
      case StudentStatus.notBoarded:
        return arabic ? 'لم يصعد' : 'Not boarded';
      case StudentStatus.late:
        return arabic ? 'متأخر' : 'Late';
    }
  }

  static String busState(BusState state, {required bool arabic}) {
    switch (state) {
      case BusState.enRoute:
        return arabic ? 'في الطريق' : 'On route';
      case BusState.atSchool:
        return arabic ? 'وصلت المدرسة' : 'At school';
      case BusState.atHome:
        return arabic ? 'وصلت المنزل' : 'At home';
    }
  }

  static String notification(NotificationType type, {required bool arabic}) {
    switch (type) {
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

  static String attendanceDirection(
    AttendanceDirection direction, {
    required bool arabic,
  }) {
    switch (direction) {
      case AttendanceDirection.outbound:
        return arabic ? 'ذهاب' : 'Morning';
      case AttendanceDirection.inbound:
        return arabic ? 'عودة' : 'Return';
      case AttendanceDirection.fullDay:
        return arabic ? 'اليوم كامل' : 'Full day';
    }
  }
}
