class Student {
  Student({
    required this.id,
    required this.name,
    this.nameEn,
    required this.grade,
    required this.busNumber,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String? nameEn;
  final String grade;
  final String busNumber;
  final String? avatarUrl;

  String getLocalizedName(String languageCode) {
    if (languageCode.toLowerCase() == 'en') {
      return (nameEn != null && nameEn!.trim().isNotEmpty) ? nameEn! : name;
    }
    return name;
  }
}
