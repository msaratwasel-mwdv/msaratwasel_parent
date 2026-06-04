import 'package:dio/dio.dart';
import 'package:msaratwasel_user/src/features/dashboard/domain/entities/child_summary.dart';
import '../../../../core/config/app_config.dart';
import './dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final Dio dio;

  DashboardRepositoryImpl({required this.dio});

  @override
  Future<List<ChildSummary>> fetchChildrenSummary() async {
    final response = await dio.get('parent/children');
    final List<dynamic> data = response.data['data'];
    return data.map((json) {
      String? avatarUrl = json['image_url'];
      avatarUrl = AppConfig.normalizeImageUrl(avatarUrl);

      return ChildSummary(
        id: json['id'].toString(),
        name: json['name'] ?? '',
        status: json['status'] ?? '',
        busStatus: json['bus']?['trip_status'] ?? '',
        etaMinutes: 0, // Calculated elsewhere or if provided by API
        recentNotification: null,
        avatarUrl: avatarUrl,
      );
    }).toList();
  }
}
