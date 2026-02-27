import 'package:dio/dio.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import './notifications_repository.dart';

class NotificationRepositoryImpl implements NotificationsRepository {
  final Dio dio;

  NotificationRepositoryImpl({required this.dio});

  @override
  Future<List<AppNotification>> fetchNotifications() async {
    try {
      final response = await dio.get('/api/guardian/notifications');

      if (response.statusCode == 200) {
        // API returns { notifications: { data: [...] }, unread_count: N }
        final notificationsMap = response.data['notifications'];
        final List<dynamic> data = (notificationsMap is Map)
            ? (notificationsMap['data'] ?? [])
            : (notificationsMap ?? []);

        return data.map((json) {
          return AppNotification(
            id: json['id'].toString(),
            title: json['title'] ?? '',
            body: json['message'] ?? json['body'] ?? '',
            type: _mapType(json['type']),
            time: json['created_at'] != null
                ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
                : DateTime.now(),
            read: json['read'] == true || json['status'] == 'read',
          );
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  NotificationType _mapType(String? type) {
    switch (type) {
      // ركوب الطالب (SCRUM-86 & SCRUM-87)
      case 'bus_boarding_morning':
      case 'bus_boarding_afternoon':
      case 'bus_boarding':
      case 'student_boarded':
        return NotificationType.checkIn;
      // نزول الطالب
      case 'bus_alighting':
      case 'student_alighted':
        return NotificationType.checkOut;
      // اقتراب الحافلة
      case 'bus_proximity':
      case 'bus_approaching':
        return NotificationType.approach;
      // وصول الحافلة
      case 'bus_arrived':
        return NotificationType.arrival;
      // تأخير
      case 'bus_delay':
        return NotificationType.delay;
      // تغيير المسار
      case 'bus_route_change':
        return NotificationType.routeChange;
      // غياب
      case 'student_absence':
        return NotificationType.absence;
      // تأخر في الركوب
      case 'late_boarding':
        return NotificationType.lateBoarding;
      // إعلان مدرسي
      case 'school_alert':
      case 'school_announcement':
        return NotificationType.schoolAlert;
      // رسالة مشرف
      case 'supervisor_message':
        return NotificationType.supervisorMessage;
      default:
        return NotificationType.schoolAlert;
    }
  }
}
