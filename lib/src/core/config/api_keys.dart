/// API Keys configuration
///
/// ⚠️ IMPORTANT: Do NOT commit this file with real API keys to version control.
/// Use environment variables or a separate secrets management system for production.
///
/// For local development, you can modify these values directly.
/// For production, consider using:
/// - `--dart-define` build flags
/// - Environment variables with `String.fromEnvironment`
/// - A secure secrets manager
class ApiKeys {
  const ApiKeys._();

  /// Google Maps API Key
  /// Used for: Maps display, Places Autocomplete, Geocoding
  ///
  /// To change this key:
  /// 1. Go to Google Cloud Console
  /// 2. Create or select a project
  /// 3. Enable Maps SDK, Places API, and Geocoding API
  /// 4. Create an API key with appropriate restrictions
  static const String googleMaps = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyA4Njj1ohfXqbPbNOb3HOainiexMR5WFs0',
  );

  /// Firebase API Key (if needed separately)
  static const String firebase = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );
}
