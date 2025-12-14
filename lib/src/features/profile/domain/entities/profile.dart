class Profile {
  Profile({
    required this.name,
    required this.phone,
    this.email,
    this.languageCode,
  });

  final String name;
  final String phone;
  final String? email;
  final String? languageCode;
}
