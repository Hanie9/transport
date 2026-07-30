/// Backend / API configuration.
///
/// Switch [useMockApi] to `false` and set [apiBaseUrl] when Django is ready.
/// Example:
/// ```bash
/// flutter run --dart-define=API_BASE_URL=https://api.example.com/api --dart-define=USE_MOCK_API=false
/// ```
class ApiConfig {
  ApiConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const bool useMockApi = bool.fromEnvironment(
    'USE_MOCK_API',
    defaultValue: true,
  );

  static bool get hasApiBaseUrl => apiBaseUrl.trim().isNotEmpty;

  /// When false and base URL is set, remote repositories are used.
  static bool get shouldUseMock => useMockApi || !hasApiBaseUrl;

  // REST endpoint paths (Django REST Framework).
  static const String loginPath = '/auth/login/';
  static const String signupPath = '/auth/register/';
  static const String refreshTokenPath = '/auth/refresh/';
  static const String mePath = '/auth/me/';
  static const String changePasswordPath = '/auth/change-password/';
  static const String vehiclePath = '/drivers/vehicle/';
  static const String cargosPath = '/cargos/';
  static const String nearbyCargosPath = '/cargos/nearby/';
  static const String acceptCargoPath = '/cargos/{id}/accept/';
  static const String cargoStatusPath = '/cargos/{id}/status/';
  static const String estimatePricePath = '/cargos/estimate-price/';
  static const String driversPath = '/drivers/';
  static const String nearbyDriversPath = '/drivers/nearby/';
  static const String reportLocationPath = '/drivers/location/';
}

/// Legacy getter used by Neshan backend proxy helpers.
String get apiBaseUrl => ApiConfig.apiBaseUrl;
