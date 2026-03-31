import '../../domain/entities/bus_position.dart';

abstract class TrackingRepository {
  Future<BusPosition> fetchLivePosition(String busId);
}
