/// ============================================================
/// ApiConfig — Single source of truth for the API base URL.
/// All API calls must use [ApiConfig.baseUrl].
/// ============================================================
class ApiConfig {
  ApiConfig._(); // Non-instantiable

  /// Production backend deployed on Render.
  static const String baseUrl = 'https://build-track.onrender.com/api';
  
}
