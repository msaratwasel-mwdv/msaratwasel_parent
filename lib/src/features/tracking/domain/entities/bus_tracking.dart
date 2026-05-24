// Sentinel value to distinguish between "not provided" and explicit null in copyWith
const _undefined = Object();

class BusTracking {
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final DateTime lastUpdate;
  final bool isStale;
  final int? etaMinutes;
  final double? targetLatitude;
  final double? targetLongitude;

  BusTracking({
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    required this.lastUpdate,
    this.isStale = false,
    this.etaMinutes,
    this.targetLatitude,
    this.targetLongitude,
  });

  /// Copies this tracking object, replacing only the provided fields.
  /// For nullable fields [targetLatitude] and [targetLongitude], passing explicit
  /// `null` WILL clear them. Omitting them preserves the existing value.
  BusTracking copyWith({
    double? latitude,
    double? longitude,
    double? speed,
    double? heading,
    DateTime? lastUpdate,
    bool? isStale,
    int? etaMinutes,
    Object? targetLatitude = _undefined,
    Object? targetLongitude = _undefined,
  }) {
    return BusTracking(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      isStale: isStale ?? this.isStale,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      targetLatitude: targetLatitude == _undefined
          ? this.targetLatitude
          : targetLatitude as double?,
      targetLongitude: targetLongitude == _undefined
          ? this.targetLongitude
          : targetLongitude as double?,
    );
  }
}
