/// ============================================================
/// ApiConfig — Single source of truth for the API base URL.
/// All API calls must use [ApiConfig.baseUrl].
/// ============================================================
class ApiConfig {
  ApiConfig._(); // Non-instantiable

  /// The active environment is set via --dart-define=ENV=environment.
  /// Valid values: 'development' (localhost), 'emulator' (10.0.2.2), 'production'.
  /// Defaults to 'production' if not specified.
  static const String environment = String.fromEnvironment('ENV', defaultValue: 'development');

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
