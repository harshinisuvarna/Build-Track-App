/// ============================================================
/// ApiConfig — Single source of truth for the API base URL.
/// All API calls must use [ApiConfig.baseUrl].
/// ============================================================
class ApiConfig {
  ApiConfig._(); // Non-instantiable

  /// Local Development Backend base URLs:
  /// iOS Simulator:
  // static const String baseUrl = 'http://localhost:5001/api';
  /// Android Emulator:
  // static const String baseUrl = 'http://10.0.2.2:5001/api';

  /// Production backend deployed on Render.
  static const String baseUrl = 'https://build-track.onrender.com/api';
  
}
