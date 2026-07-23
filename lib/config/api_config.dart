class ApiConfig {
  ApiConfig._();

  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'production',
  );

  static String get baseUrl {
    switch (environment) {
      case 'development':
        return 'http://localhost:5001/api';
      case 'emulator':
        return 'http://10.0.2.2:5001/api';
      case 'production':
      default:
        return 'https://build-track.onrender.com/api';
    }
  }
}
