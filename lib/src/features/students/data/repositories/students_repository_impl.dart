import 'package:dio/dio.dart';
import 'package:msaratwasel_user/src/features/students/domain/entities/student.dart';
import './students_repository.dart';

class StudentsRepositoryImpl implements StudentsRepository {
  final Dio dio;

  StudentsRepositoryImpl({required this.dio});

  @override
  Future<List<Student>> fetchStudents() async {
    final response = await dio.get('guardian/students');
    final List<dynamic> data = response.data['data'];
    return data.map((json) => _mapToStudent(json)).toList();
  }

  @override
  Future<Student> fetchStudent(String id) async {
    final response = await dio.get('guardian/students/$id');
    return _mapToStudent(response.data['data']);
  }

  @override
  Future<void> addStudent(Student student) async {
    await dio.post('guardian/students/link', data: {
      'civil_id': student.id, // Assuming linking happens by ID
    });
  }

  Student _mapToStudent(Map<String, dynamic> json) {
    String? avatarUrl = json['avatar_url'];
    if (avatarUrl != null && !avatarUrl.startsWith('http')) {
      avatarUrl = 'https://srv1428362.hstgr.cloud/storage/$avatarUrl';
    }

    return Student(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      grade: json['grade'] ?? '',
      busNumber: json['bus']?['number'] ?? '-',
      avatarUrl: avatarUrl,
    );
  }
}
