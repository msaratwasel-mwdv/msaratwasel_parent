import 'package:dio/dio.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import './notifications_repository.dart';

class NotificationRepositoryImpl implements NotificationsRepository {
  final Dio dio;

  NotificationRepositoryImpl({required this.dio});

  @override
  Future<List<AppNotification>> fetchNotifications() async {
    try {
      final response = await dio.get('guardian/notifications');

      if (response.statusCode == 200) {
        // API returns { notifications: { data: [...] }, unread_count: N }
        final notificationsMap = response.data['notifications'];
        final List<dynamic> data = (notificationsMap is Map)
            ? (notificationsMap['data'] ?? [])
            : (notificationsMap ?? []);

        return data.map((json) {
          return AppNotification.fromMap(json);
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
