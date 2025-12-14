class ChildSummary {
  ChildSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.busStatus,
    this.etaMinutes,
    this.recentNotification,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String status;
  final String busStatus;
  final int? etaMinutes;
  final String? recentNotification;
  final String? avatarUrl;
}
