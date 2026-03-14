import 'package:msaratwasel_user/src/core/models/app_models.dart';

class Labels {
  const Labels._();

  static String studentStatus(StudentStatus status, {required bool arabic}) {
    switch (status) {
      case StudentStatus.waitingAtHome:
      case StudentStatus.arrivedHome:
      case StudentStatus.atHome:
        return arabic ? 'في المنزل' : 'At home';
      case StudentStatus.onBusToSchool:
      case StudentStatus.onBusToHome:
      case StudentStatus.onBus:
        return arabic ? 'في الحافلة' : 'On the bus';
      case StudentStatus.atSchool:
        return arabic ? 'في المدرسة' : 'At school';
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
