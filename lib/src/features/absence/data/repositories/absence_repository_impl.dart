import 'package:dio/dio.dart';
import 'package:msaratwasel_user/src/features/absence/domain/entities/absence_request.dart';
import './absence_repository.dart';

class AbsenceRepositoryImpl implements AbsenceRepository {
  final Dio dio;

  AbsenceRepositoryImpl({required this.dio});

  @override
  Future<void> submitAbsence(AbsenceRequest request) async {
    // Since request might have multiple students, and backend handles one student_id
    // We loop through them in the repository or controller.
    // Given the UI, let's assume one student for now as selected in the Page.
    
    for (final studentId in request.studentIds) {
      final typeStr = _mapType(request.type);
      await dio.post('parent/absence-requests', data: {
        'student_id': studentId,
        'date': request.date.toIso8601String().split('T')[0],
        'type': typeStr,
        'reason': request.note ?? '',
      });
    }
  }

  @override
  Future<List<AbsenceRequest>> fetchHistory() async {
    final response = await dio.get('parent/absence-requests');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data['data'];
      return data.map((json) {
        return AbsenceRequest(
          id: json['id'].toString(),
          studentIds: [json['student_id'].toString()],
          studentName: json['student']?['name'],
          type: _parseType(json['type']),
          date: DateTime.tryParse(json['date']) ?? DateTime.now(),
          note: json['reason'],
          status: json['status'],
          rejectionReason: json['rejection_reason'],
        );
      }).toList();
    }
    return [];
  }

  String _mapType(AbsenceType type) {
    switch (type) {
      case AbsenceType.morning:
        return 'morning';
      case AbsenceType.returnOnly:
        return 'afternoon';
      case AbsenceType.both:
        return 'full_day';
    }
  }

  AbsenceType _parseType(String? type) {
    switch (type) {
      case 'morning':
        return AbsenceType.morning;
      case 'afternoon':
        return AbsenceType.returnOnly;
      case 'full_day':
      default:
        return AbsenceType.both;
    }
  }
}
