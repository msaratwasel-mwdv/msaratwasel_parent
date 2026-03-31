import '../../domain/entities/complaint.dart';

abstract class ComplaintsRepository {
  /// Call SEND_COMPLAINT_API.
  Future<void> submitComplaint(Complaint complaint);
}
