import 'package:dio/dio.dart';
import 'package:msaratwasel_user/src/features/dashboard/domain/entities/child_summary.dart';
import './dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final Dio dio;

  DashboardRepositoryImpl({required this.dio});

  @override
  Future<List<ChildSummary>> fetchChildrenSummary() async {
    final response = await dio.get('guardian/dashboard');
    final List<dynamic> data = response.data['data'];
    return data.map((json) {
      String? avatarUrl = json['image_url'] ?? json['avatar_url'];
      if (avatarUrl != null && !avatarUrl.startsWith('http')) {
        avatarUrl = 'https://srv1428362.hstgr.cloud/storage/$avatarUrl';
      }

      return ChildSummary(
        id: json['id'].toString(),
        name: json['name'] ?? '',
        status: json['status_label'] ?? json['status'] ?? '',
        busStatus: json['bus_status_label'] ?? json['bus_status'] ?? '',
        etaMinutes: json['eta_minutes'],
        recentNotification: json['latest_notification']?['body'],
        avatarUrl: avatarUrl,
      );
    }).toList();
  }
}
