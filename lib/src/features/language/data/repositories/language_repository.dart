abstract class LanguageRepository {
  /// Persist locale code and notify app.
  Future<void> setLocale(String code);

  /// Read saved locale or return system default.
  Future<String?> getSavedLocale();
}
