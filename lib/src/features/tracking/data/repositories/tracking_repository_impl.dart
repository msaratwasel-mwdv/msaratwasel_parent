import 'package:dio/dio.dart';
import 'package:msaratwasel_user/src/features/tracking/domain/entities/bus_position.dart';
import './tracking_repository.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  final Dio dio;

  TrackingRepositoryImpl({required this.dio});

  @override
  Future<BusPosition> fetchLivePosition(String busId) async {
    final response = await dio.get('bus/$busId/location');
    final data = response.data; // LocationController returns it directly usually or under data
    return BusPosition(
      lat: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      lng: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      etaMinutes: (data['eta_minutes'] as num?)?.toInt() ?? 0,
      busNumber: data['bus_number'] ?? '',
    );
  }
}
