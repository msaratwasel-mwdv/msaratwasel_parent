class AppConfig {
  const AppConfig._();

  // هذا هو المتغير الوحيد الذي ستغيره للربط بين المحلي والاستضافة
  static const bool isLocal = true;

  // رابط المحاكي (ويجب أن يكون IP جهازك إذا كنت تستخدم هاتفاً حقيقياً)
  static const String _localUrl = 'http://10.11.5.139:8001/api/';

  // رابط الاستضافة
  static const String _productionUrl = 'https://srv1428362.hstgr.cloud/api/';

  // ─── Base URL ────────────────────────────────────────────────────────────
  static String get apiBaseUrl => isLocal ? _localUrl : _productionUrl;

  // ─── Timeouts ────────────────────────────────────────────────────────────
  static const Duration defaultTimeout = Duration(seconds: 30);
}
