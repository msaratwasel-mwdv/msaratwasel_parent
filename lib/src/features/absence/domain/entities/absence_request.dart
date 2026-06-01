enum AbsenceType { morning, returnOnly, both }

class AbsenceRequest {
  const AbsenceRequest({
    this.id,
    required this.studentIds,
    required this.type,
    required this.date,
    this.note,
    this.status,
    this.studentName,
    this.studentNameEn,
    this.rejectionReason,
  });

  final String? id;
  final List<String> studentIds;
  final String? studentName;
  final String? studentNameEn;
  final AbsenceType type;
  final DateTime date;
  final String? note;
  final String? status;
  final String? rejectionReason;

  String getLocalizedStudentName(String languageCode) {
    if (languageCode.toLowerCase() == 'en') {
      return (studentNameEn != null && studentNameEn!.trim().isNotEmpty)
          ? studentNameEn!
          : (studentName ?? '');
    }
    return studentName ?? '';
  }
}
