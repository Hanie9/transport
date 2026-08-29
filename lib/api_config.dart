/// Backend / API configuration.
///
/// Defaults to the production Liara host. Override at build time:
/// ```bash
/// flutter run \
///   --dart-define=API_BASE_URL=https://transport.liara.run/api \
///   --dart-define=USE_MOCK_API=false
/// ```
class ApiConfig {
  ApiConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://transport.liara.run/api',
  );

  static const bool useMockApi = bool.fromEnvironment(
    'USE_MOCK_API',
    defaultValue: false,
  );

  static bool get hasApiBaseUrl => apiBaseUrl.trim().isNotEmpty;

  /// When false and base URL is set, remote repositories are used.
  static bool get shouldUseMock => useMockApi || !hasApiBaseUrl;

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String loginPath = '/auth/login/';
  static const String signupPath = '/auth/register/';
  static const String refreshTokenPath = '/auth/refresh/';
  static const String mePath = '/auth/me/';
  static const String changePasswordPath = '/auth/change-password/';
  static const String logoutPath = '/auth/logout/';

  // ── Drivers ───────────────────────────────────────────────────────────────
  static const String vehiclePath = '/drivers/vehicle/';
  static const String driversPath = '/drivers/';
  static const String nearbyDriversPath = '/drivers/nearby/';
  static const String reportLocationPath = '/drivers/location/';
  static const String driverMissionsPath = '/drivers/missions/';

  // ── Cargos ────────────────────────────────────────────────────────────────
  static const String cargosPath = '/cargos/';
  static const String nearbyCargosPath = '/cargos/nearby/';
  static const String estimatePricePath = '/cargos/estimate-price/';

  static String cargoDetailPath(String id) => '/cargos/$id/';

  static String acceptCargoPathFor(String id) => '/cargos/$id/accept/';

  static String cargoStatusPathFor(String id) => '/cargos/$id/status/';

  // Legacy placeholders (prefer helpers above).
  static const String acceptCargoPath = '/cargos/{id}/accept/';
  static const String cargoStatusPath = '/cargos/{id}/status/';

  // ── Push / devices ────────────────────────────────────────────────────────
  static const String devicesPath = '/devices/';

  // ── Neshan proxy (same backend) ───────────────────────────────────────────
  static const String neshanGeocodePath = '/transport/neshan/geocode';
  static const String neshanSearchPath = '/transport/neshan/search';
  static const String neshanRoutePath = '/transport/neshan/route';
}

/// Legacy getter used by Neshan backend proxy helpers.
String get apiBaseUrl => ApiConfig.apiBaseUrl;
