
/// Environment Configurations
class Env {
  const Env._();

  /// Sentry DSN
  /// Can be overridden via `--dart-define=SENTRY_DSN=your_dsn` at build/run time.
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: 'https://8adfbcae8fb55fae2f47c92b23a9d4a8@o4507028168212480.ingest.us.sentry.io/4507038161747968',
  );
}
