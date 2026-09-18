/// Backend / API configuration.
///
/// Defaults to the production Liara host. Override at build time:
/// ```bash
/// flutter run \
///   --dart-define=API_BASE_URL=https://tran-develoop.liara.run \
///   --dart-define=USE_MOCK_API=false
/// ```
class ApiConfig {
  ApiConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://tran-develoop.liara.run',
  );

  static const bool useMockApi = bool.fromEnvironment(
    'USE_MOCK_API',
    defaultValue: false,
  );

  static bool get hasApiBaseUrl => apiBaseUrl.trim().isNotEmpty;

  /// When false and base URL is set, remote repositories are used.
  static bool get shouldUseMock => useMockApi || !hasApiBaseUrl;

  // ── Accounts ───────────────────────────────────────────────────────────────
  static const String loginPath = '/api/accounts/login';
  static const String logoutPath = '/api/accounts/logout';
  static const String profilePath = '/api/accounts/profile/';
  static const String registerPath = '/api/accounts/register/';
  static const String changePasswordPath = '/api/accounts/change-password/';

  // ── Operator (coordinator) bars ────────────────────────────────────────────
  static const String operatorBarsPath = '/api/operator/bars/';
  static const String operatorBarCreatePath = '/api/operator/bars/create/';

  static String operatorBarDetailPath(String id) => '/api/operator/bars/$id/';

  static String operatorBarUpdatePath(String id) =>
      '/api/operator/bars/$id/update/';

  static String operatorBarDeletePath(String id) =>
      '/api/operator/bars/$id/delete/';

  // ── Driver bars ────────────────────────────────────────────────────────────
  static const String driverBarsPath = '/api/driver/bars/';
  static const String driverAssignedBarsPath = '/api/driver/bars/assigned/';
  static String driverBarCompletePath(String id) =>
      '/api/driver/bars/$id/complete/';
  static String operatorBarCompletePath(String id) =>
      '/api/operator/bars/$id/complete/';

  static String driverBarAcceptPath(String id) =>
      '/api/driver/bars/$id/accept/';

  // ── Reference data ─────────────────────────────────────────────────────────
  static const String productsPath = '/api/products/';
  static const String machinesPath = '/api/machines/';
  static const String ostansPath = '/api/ostans/';

  // ── Neshan proxy (optional — not in Transport OpenAPI) ───────────────────
  static const String neshanGeocodePath = '/transport/neshan/geocode';
  static const String neshanSearchPath = '/transport/neshan/search';
  static const String neshanRoutePath = '/transport/neshan/route';
}

/// Legacy getter used by Neshan backend proxy helpers.
String get apiBaseUrl => ApiConfig.apiBaseUrl;
