class AppConfig {
  const AppConfig._();

  // هذا هو المتغير الوحيد الذي ستغيره للربط بين المحلي والاستضافة
  static const bool isLocal = false;

  // رابط المحاكي (ويجب أن يكون IP جهازك إذا كنت تستخدم هاتفاً حقيقياً)
  static const String _localUrl = 'http://192.168.8.188:8001/api/';

  // رابط الاستضافة
  static const String _productionUrl = 'https://masaratwasal.com/api/';

  static const String googleMapsApiKey =
      'AIzaSyA2ZcFQqhauhU3l-Rj36fbRYomIO7L-ahs';

  // ─── Base URL ────────────────────────────────────────────────────────────
  static String get apiBaseUrl => isLocal ? _localUrl : _productionUrl;

  // ─── Reverb / WebSocket ──────────────────────────────────────────────────
  static String get reverbHost => isLocal ? Uri.parse(_localUrl).host : 'masaratwasal.com';
  static int get reverbPort => isLocal ? 8080 : 443;
  static bool get reverbUseSsl => !isLocal;
  static const String reverbKey = 'masarat-wasel-key';

  // ─── Timeouts ────────────────────────────────────────────────────────────
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration markerImageTimeout = Duration(seconds: 10);
}
