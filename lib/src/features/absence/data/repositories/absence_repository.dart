import '../../domain/entities/absence_request.dart';

abstract class AbsenceRepository {
  /// TODO: call MARK_ABSENT_API.
  Future<void> submitAbsence(AbsenceRequest request);

  /// TODO: call GET_ABSENCE_HISTORY_API.
  Future<List<AbsenceRequest>> fetchHistory();
}
