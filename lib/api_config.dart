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

  // ── Accounts (no trailing slash) ───────────────────────────────────────────
  static const String loginPath = '/accounts/login';
  static const String logoutPath = '/accounts/logout';
  static const String profilePath = '/accounts/profile';

  // ── Operator (coordinator) bars ────────────────────────────────────────────
  static const String operatorBarsPath = '/operator/bars/';
  static const String operatorBarCreatePath = '/operator/bars/create/';

  static String operatorBarDetailPath(String id) => '/operator/bars/$id/';

  static String operatorBarUpdatePath(String id) => '/operator/bars/$id/update/';

  static String operatorBarDeletePath(String id) => '/operator/bars/$id/delete/';

  // ── Driver bars ────────────────────────────────────────────────────────────
  static const String driverBarsPath = '/driver/bars/';

  static String driverBarAcceptPath(String id) => '/driver/bars/$id/accept/';

  // ── Reference data ─────────────────────────────────────────────────────────
  static const String productsPath = '/products/';
  static const String machinesPath = '/machines/';
  static const String ostansPath = '/ostans/';

  // ── Neshan proxy (optional — not in Transport OpenAPI) ───────────────────
  static const String neshanGeocodePath = '/transport/neshan/geocode';
  static const String neshanSearchPath = '/transport/neshan/search';
  static const String neshanRoutePath = '/transport/neshan/route';
}

/// Legacy getter used by Neshan backend proxy helpers.
String get apiBaseUrl => ApiConfig.apiBaseUrl;
