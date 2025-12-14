import '../../domain/entities/bus_position.dart';

abstract class TrackingRepository {
  /// TODO: call GET_BUS_LOCATION_API and parse bus location + ETA + polyline.
  Future<BusPosition> fetchLivePosition(String busId);
}
