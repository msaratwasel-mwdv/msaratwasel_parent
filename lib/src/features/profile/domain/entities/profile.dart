class Profile {
  Profile({
    required this.name,
    required this.phone,
    this.email,
    this.languageCode,
    this.avatarUrl,
  });

  final String name;
  final String phone;
  final String? email;
  final String? languageCode;
  final String? avatarUrl;
}
