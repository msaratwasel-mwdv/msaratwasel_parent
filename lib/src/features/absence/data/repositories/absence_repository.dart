import '../../domain/entities/absence_request.dart';

abstract class AbsenceRepository {
  /// Call MARK_ABSENT_API.
  Future<void> submitAbsence(AbsenceRequest request);

  /// Call GET_ABSENCE_HISTORY_API.
  Future<List<AbsenceRequest>> fetchHistory();
}
