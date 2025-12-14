class AppConfig {
  const AppConfig._();

  // TODO: Replace with real base URL.
  static const String apiBaseUrl = 'https://api.msaratwasel.local';

  // Shared keys for environment/feature flags.
  static const Duration defaultTimeout = Duration(seconds: 10);
}
