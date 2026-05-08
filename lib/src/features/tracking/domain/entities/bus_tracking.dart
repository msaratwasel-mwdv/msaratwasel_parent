class BusTracking {
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final DateTime lastUpdate;
  final bool isStale;

  final int? etaMinutes;

  BusTracking({
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    required this.lastUpdate,
    this.isStale = false,
    this.etaMinutes,
  });

  BusTracking copyWith({
    double? latitude,
    double? longitude,
    double? speed,
    double? heading,
    DateTime? lastUpdate,
    bool? isStale,
    int? etaMinutes,
  }) {
    return BusTracking(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      isStale: isStale ?? this.isStale,
      etaMinutes: etaMinutes ?? this.etaMinutes,
    );
  }
}
