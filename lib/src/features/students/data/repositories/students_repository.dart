import '../../domain/entities/student.dart';

abstract class StudentsRepository {
  Future<List<Student>> fetchStudents();

  Future<Student> fetchStudent(String id);

  Future<void> addStudent(Student student);
}
