import '../../domain/entities/child_summary.dart';

abstract class DashboardRepository {
  Future<List<ChildSummary>> fetchChildrenSummary();
}
