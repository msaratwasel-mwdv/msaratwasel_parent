import '../../domain/entities/student.dart';

abstract class StudentsRepository {
  /// TODO: call GET_STUDENTS_API.
  Future<List<Student>> fetchStudents();

  /// TODO: fetch details by id.
  Future<Student> fetchStudent(String id);

  /// TODO: add/link new student.
  Future<void> addStudent(Student student);
}
