// frontend/lib/core/config/environment.dart

enum Environment {
  dev,
  staging,
  production,
}

extension EnvironmentExtension on Environment {
  String get name {
    switch (this) {
      case Environment.dev:
        return 'dev';
      case Environment.staging:
        return 'staging';
      case Environment.production:
        return 'prod';
    }
  }

  bool get isDevelopment => this == Environment.dev;
  bool get isStaging => this == Environment.staging;
  bool get isProduction => this == Environment.production;
}

class EnvironmentConfig {
  static Environment current = Environment.dev;

  static void setEnvironment(Environment env) {
    current = env;
  }

  static String get baseUrl {
    switch (current) {
      case Environment.dev:
        return const String.fromEnvironment('API_BASE_URL',
            defaultValue: 'http://localhost:8000');
      case Environment.staging:
        return const String.fromEnvironment('API_BASE_URL',
            defaultValue: 'https://staging-api.guide-scolaire.com');
      case Environment.production:
        return const String.fromEnvironment('API_BASE_URL',
            defaultValue: 'https://api.guide-scolaire.com');
    }
  }

  static String get apiVersion => 'v1';
  static String get apiBase => '$baseUrl/api/$apiVersion';
}