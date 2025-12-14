import '../../domain/entities/child_summary.dart';

abstract class DashboardRepository {
  /// TODO: fetch dashboard summary (students, statuses, ETA, notifications).
  Future<List<ChildSummary>> fetchChildrenSummary();
}
