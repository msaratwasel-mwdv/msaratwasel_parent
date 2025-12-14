class Complaint {
  Complaint({
    required this.type,
    required this.studentId,
    required this.message,
    this.imagePath,
  });

  final ComplaintType type;
  final String studentId;
  final String message;
  final String? imagePath;
}

enum ComplaintType { complaint, suggestion, urgent }
