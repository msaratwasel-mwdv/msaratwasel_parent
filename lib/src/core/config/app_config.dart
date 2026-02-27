class AppConfig {
  const AppConfig._();

  // ─── Base URL ────────────────────────────────────────────────────────────
  // Android Emulator  → http://10.0.2.2:8000
  // Real Device (USB) → http://<IP_OF_YOUR_PC>:8000
  static const String apiBaseUrl = 'https://srv1428362.hstgr.cloud';

  // ─── Timeouts ────────────────────────────────────────────────────────────
  static const Duration defaultTimeout = Duration(seconds: 15);
}
