enum AppEnvironment { dev, staging, production }

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.appName,
    required this.enableAnalytics,
    required this.enableCrashReporting,
    required this.sentryDsn,
    this.featureFlags = const {},
  });

  final AppEnvironment environment;
  final String appName;
  final bool enableAnalytics;
  final bool enableCrashReporting;
  final String sentryDsn;
  final Map<String, bool> featureFlags;

  bool isFeatureEnabled(String flag) => featureFlags[flag] ?? false;

  static AppConfig dev = const AppConfig(
    environment: AppEnvironment.dev,
    appName: 'HabitShare Dev',
    enableAnalytics: false,
    enableCrashReporting: false,
    sentryDsn: '',
    featureFlags: {
      'offline_sync': true,
      'apple_sign_in': true,
      'csv_import_export': true,
    },
  );

  static AppConfig staging = const AppConfig(
    environment: AppEnvironment.staging,
    appName: 'HabitShare Staging',
    enableAnalytics: true,
    enableCrashReporting: true,
    sentryDsn: '',
    featureFlags: {
      'offline_sync': true,
      'apple_sign_in': true,
      'csv_import_export': true,
    },
  );

  static AppConfig production = const AppConfig(
    environment: AppEnvironment.production,
    appName: 'HabitShare',
    enableAnalytics: true,
    enableCrashReporting: true,
    sentryDsn: '',
    featureFlags: {
      'offline_sync': true,
      'apple_sign_in': true,
      'csv_import_export': true,
    },
  );

  static AppConfig fromEnv(Map<String, String> env) {
    final appEnv = env['APP_ENV'] ?? 'dev';
    final base = switch (appEnv) {
      'staging' => staging,
      'production' || 'prod' => production,
      _ => dev,
    };
    return AppConfig(
      environment: base.environment,
      appName: base.appName,
      enableAnalytics:
          env['ENABLE_ANALYTICS']?.toLowerCase() == 'true' ||
          base.enableAnalytics,
      enableCrashReporting:
          env['ENABLE_CRASH_REPORTING']?.toLowerCase() == 'true' ||
          base.enableCrashReporting,
      sentryDsn: env['SENTRY_DSN'] ?? base.sentryDsn,
      featureFlags: base.featureFlags,
    );
  }
}
