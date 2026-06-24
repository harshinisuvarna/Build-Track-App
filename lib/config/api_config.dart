/// ============================================================
/// ApiConfig — Single source of truth for the API base URL.
/// All API calls must use [ApiConfig.baseUrl].
/// ============================================================
class ApiConfig {
  ApiConfig._(); // Non-instantiable

  /// Development backend running locally on port 5001.
  static const String baseUrl = 'http://localhost:5001/api';
  
}
