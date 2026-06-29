/// ============================================================
/// ApiConfig — Single source of truth for the API base URL.
/// All API calls must use [ApiConfig.baseUrl].
/// ============================================================
class ApiConfig {
  ApiConfig._(); // Non-instantiable

<<<<<<< HEAD
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
=======
  /// Local Development Backend base URLs:
  /// iOS Simulator:
  // static const String baseUrl = 'http://localhost:5001/api';
  /// Android Emulator:
  // static const String baseUrl = 'http://10.0.2.2:5001/api';

  /// Production backend deployed on Render.
  static const String baseUrl = 'https://build-track.onrender.com/api';
>>>>>>> b6ea0ac2883f79e6e2607b4764aeef4697d188ae
}
