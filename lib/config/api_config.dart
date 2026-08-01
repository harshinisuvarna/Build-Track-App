class ApiConfig {
  ApiConfig._();
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );
  static String get baseUrl {
    return 'https://build-track.onrender.com/api';
  }
}
