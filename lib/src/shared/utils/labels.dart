import 'package:flutter/widgets.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';

class Labels {
  const Labels._();

  static String studentStatus(BuildContext context, StudentStatus status) {
    switch (status) {
      case StudentStatus.waitingAtHome:
        return context.t('waitingAtHome');
      case StudentStatus.arrivedHome:
        return context.t('arrivedHome');
      case StudentStatus.atHome:
        return context.t('atHome');
      case StudentStatus.onBusToSchool:
      case StudentStatus.onBusToHome:
      case StudentStatus.onBus:
        return context.t('onBus');
      case StudentStatus.atSchool:
        return context.t('atSchool');
      case StudentStatus.notBoarded:
        return context.t('notBoarded');
      case StudentStatus.late:
        return context.t('late');
    }
  }

  static String busState(BuildContext context, BusState state) {
    switch (state) {
      case BusState.enRoute:
        return context.t('enRoute');
      case BusState.atSchool:
        return context.t('arrivedSchool');
      case BusState.atHome:
        return context.t('arrivedHome');
    }
  }

  static String attendanceDirection(
    BuildContext context,
    AttendanceDirection direction,
  ) {
    switch (direction) {
      case AttendanceDirection.outbound:
        return context.t('morning');
      case AttendanceDirection.inbound:
        return context.t('return');
      case AttendanceDirection.fullDay:
        return context.t('fullDay');
    }
  }
}

