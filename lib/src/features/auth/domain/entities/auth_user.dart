class AuthUser {
  AuthUser({
    required this.id,
    required this.name,
    this.nameEn,
    required this.role,
    required this.accessToken,
    this.refreshToken,
  });

  final String id;
  final String name;
  final String? nameEn;
  final String role;
  final String accessToken;
  final String? refreshToken;

  String getLocalizedName(String languageCode) {
    if (languageCode.toLowerCase() == 'en') {
      return (nameEn != null && nameEn!.trim().isNotEmpty) ? nameEn! : name;
    }
    return name;
  }
}
