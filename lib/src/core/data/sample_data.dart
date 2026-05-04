import 'package:flutter/material.dart';

import 'package:msaratwasel_user/src/core/models/app_models.dart';

/// Utility methods for mapping student status to display labels and icons.
/// NOTE: All sample/mock data collections have been removed.
/// Tracking, messages, attendance, and trips are now loaded exclusively from API.
class SampleData {
  SampleData._();

  static String studentStatusText(StudentStatus status) {
    switch (status) {
      case StudentStatus.waitingAtHome:
      case StudentStatus.arrivedHome:
      case StudentStatus.atHome:
        return 'في المنزل';
      case StudentStatus.onBusToSchool:
      case StudentStatus.onBusToHome:
      case StudentStatus.onBus:
        return 'في الحافلة';
      case StudentStatus.atSchool:
        return 'في المدرسة';
      case StudentStatus.notBoarded:
        return 'لم يصعد';
      case StudentStatus.late:
        return 'متأخر';
    }
  }

  static IconData statusIcon(StudentStatus status) {
    switch (status) {
      case StudentStatus.onBus:
      case StudentStatus.onBusToSchool:
      case StudentStatus.onBusToHome:
        return Icons.directions_bus_filled_outlined;
      case StudentStatus.atSchool:
        return Icons.school_outlined;
      case StudentStatus.atHome:
      case StudentStatus.waitingAtHome:
      case StudentStatus.arrivedHome:
        return Icons.home_outlined;
      case StudentStatus.notBoarded:
        return Icons.hourglass_top_outlined;
      case StudentStatus.late:
        return Icons.warning_amber_outlined;
    }
  }
}

