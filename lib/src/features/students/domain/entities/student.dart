class Student {
  Student({
    required this.id,
    required this.name,
    required this.grade,
    required this.busNumber,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String grade;
  final String busNumber;
  final String? avatarUrl;
}
