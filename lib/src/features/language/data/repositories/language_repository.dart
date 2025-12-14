abstract class LanguageRepository {
  /// TODO: persist locale code and notify app.
  Future<void> setLocale(String code);

  /// TODO: read saved locale or return system default.
  Future<String?> getSavedLocale();
}
