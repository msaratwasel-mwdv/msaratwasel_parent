import '../../domain/entities/app_notification.dart';

abstract class NotificationsRepository {
  /// TODO: call GET_NOTIFICATIONS_API and sync with local store.
  Future<List<AppNotification>> fetchNotifications();
}
