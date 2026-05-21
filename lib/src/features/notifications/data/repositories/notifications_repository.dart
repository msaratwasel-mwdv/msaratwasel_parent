import 'package:msaratwasel_user/src/core/models/app_models.dart';

class NotificationFetchResult {
  final List<AppNotification> notifications;
  final int unreadCount;

  NotificationFetchResult({
    required this.notifications,
    required this.unreadCount,
  });
}

abstract class NotificationsRepository {
  /// Calls GET /api/guardian/notifications and returns [NotificationFetchResult].
  Future<NotificationFetchResult> fetchNotifications();
}
