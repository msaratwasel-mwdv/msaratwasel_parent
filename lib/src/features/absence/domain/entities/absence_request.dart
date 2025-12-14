class AbsenceRequest {
  AbsenceRequest({
    required this.studentIds,
    required this.type,
    required this.date,
    this.note,
    this.status,
  });

  final List<String> studentIds;
  final AbsenceType type;
  final DateTime date;
  final String? note;
  final String? status;
}

enum AbsenceType { morning, returnOnly, both }
