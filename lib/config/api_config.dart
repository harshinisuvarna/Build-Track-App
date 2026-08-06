class ApiConfig {
  ApiConfig._();
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );
  static String get baseUrl {
    return 'http://localhost:5001/api';
    //return 'https://build-track.onrender.com/api';
  }
}
