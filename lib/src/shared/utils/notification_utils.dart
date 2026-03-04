import 'package:flutter/material.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';

extension NotificationTypeUI on NotificationType {
  IconData get icon {
    switch (this) {
      case NotificationType.approach:
        return Icons.near_me_rounded;
      case NotificationType.checkIn:
        return Icons.login_rounded;
      case NotificationType.checkOut:
        return Icons.logout_rounded;
      case NotificationType.arrival:
        return Icons.flag_rounded;
      case NotificationType.delay:
        return Icons.schedule_rounded;
      case NotificationType.routeChange:
        return Icons.alt_route_rounded;
      case NotificationType.absence:
        return Icons.event_busy_rounded;
      case NotificationType.lateBoarding:
        return Icons.warning_amber_rounded;
      case NotificationType.schoolAlert:
        return Icons.campaign_rounded;
      case NotificationType.supervisorMessage:
        return Icons.support_agent_rounded;
    }
  }
}
