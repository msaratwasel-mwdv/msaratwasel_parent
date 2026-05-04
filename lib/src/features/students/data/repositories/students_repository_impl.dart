import 'package:dio/dio.dart';
import 'package:msaratwasel_user/src/features/students/domain/entities/student.dart';
import './students_repository.dart';

class StudentsRepositoryImpl implements StudentsRepository {
  final Dio dio;

  StudentsRepositoryImpl({required this.dio});

  @override
  Future<List<Student>> fetchStudents() async {
    final response = await dio.get('parent/children');
    final List<dynamic> data = response.data['data'];
    return data.map((json) => _mapToStudent(json)).toList();
  }

  @override
  Future<Student> fetchStudent(String id) async {
    // ParentController returns all children in one call.
    // We can filter locally or if there was a detail endpoint we'd use it.
    final response = await dio.get('parent/children');
    final List<dynamic> data = response.data['data'];
    final studentJson = data.firstWhere((e) => e['id'].toString() == id);
    return _mapToStudent(studentJson);
  }

  @override
  Future<void> addStudent(Student student) async {
    // Placeholder for linking logic if needed in the future
    await dio.post('parent/children/link', data: {
      'national_id': student.id,
    });
  }

  Student _mapToStudent(Map<String, dynamic> json) {
    String? avatarUrl = json['image_url'];
    if (avatarUrl != null && !avatarUrl.startsWith('http')) {
      avatarUrl = 'http://10.60.17.139:8001/storage/$avatarUrl';
    }

    return Student(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      grade: json['grade'] ?? '',
      busNumber: json['bus']?['number']?.toString() ?? '-',
      avatarUrl: avatarUrl,
    );
  }
}
