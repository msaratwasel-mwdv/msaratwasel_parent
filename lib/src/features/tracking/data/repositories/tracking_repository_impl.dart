import 'package:dio/dio.dart';
import 'package:msaratwasel_user/src/features/tracking/domain/entities/bus_position.dart';
import './tracking_repository.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  final Dio dio;

  TrackingRepositoryImpl({required this.dio});

  @override
  Future<BusPosition> fetchLivePosition(String busId) async {
    final response = await dio.get('guardian/tracking/$busId');
    final data = response.data['data'];
    return BusPosition(
      lat: double.tryParse(data['lat'].toString()) ?? 0.0,
      lng: double.tryParse(data['lng'].toString()) ?? 0.0,
      etaMinutes: data['eta_minutes'],
      busNumber: data['bus_number'],
    );
  }
}
