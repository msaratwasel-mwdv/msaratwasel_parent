import 'package:dio/dio.dart';
import 'package:msaratwasel_user/src/features/complaints/domain/entities/complaint.dart';
import './complaints_repository.dart';

class ComplaintsRepositoryImpl implements ComplaintsRepository {
  final Dio dio;

  ComplaintsRepositoryImpl({required this.dio});

  @override
  Future<void> submitComplaint(Complaint complaint) async {
    await dio.post('guardian/complaints', data: {
      'type': complaint.type.name,
      'message': complaint.message,
      'student_id': complaint.studentId,
    });
  }
}
