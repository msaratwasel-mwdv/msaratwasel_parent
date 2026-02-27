import 'package:msaratwasel_user/src/core/models/app_models.dart';

abstract class NotificationsRepository {
  /// Calls GET /api/guardian/notifications and returns [AppNotification] list.
  Future<List<AppNotification>> fetchNotifications();
}
