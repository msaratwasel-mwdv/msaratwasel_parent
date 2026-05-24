class Profile {
  Profile({
    required this.name,
    this.nameEn,
    required this.phone,
    this.email,
    this.languageCode,
    this.avatarUrl,
  });

  final String name;
  final String? nameEn;
  final String phone;
  final String? email;
  final String? languageCode;
  final String? avatarUrl;
}
