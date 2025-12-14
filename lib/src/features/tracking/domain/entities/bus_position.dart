class BusPosition {
  BusPosition({
    required this.lat,
    required this.lng,
    this.etaMinutes,
    this.busNumber,
  });

  final double lat;
  final double lng;
  final int? etaMinutes;
  final String? busNumber;
}
