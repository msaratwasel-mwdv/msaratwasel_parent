import '../../domain/entities/complaint.dart';

abstract class ComplaintsRepository {
  /// TODO: call SEND_COMPLAINT_API.
  Future<void> submitComplaint(Complaint complaint);
}
