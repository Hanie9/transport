import 'package:flutter_test/flutter_test.dart';
import 'package:legestic/models/user_role.dart';
import 'package:legestic/services/api_client.dart';
import 'package:legestic/services/auth_service.dart';
import 'package:legestic/services/cargo_service.dart';
import 'package:legestic/utils/phone_utils.dart';
import 'package:http/http.dart' as http;

import 'support/fake_token_storage.dart';

const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://transport.liara.run/api',
);
const _useMock = bool.fromEnvironment('USE_MOCK_API', defaultValue: false);

const _coordPhone = '09355191018';
const _driverPhone = '09121111111';
const _password = 'Ab123456#';

Future<void> _requireLiveServer() async {
  if (_useMock) return;
  final res = await http
      .get(Uri.parse('$_baseUrl/docs/'))
      .timeout(const Duration(seconds: 20));
  if (res.statusCode >= 500 || res.body.contains('Application Error')) {
    fail(
      'سرور transport.liara.run خاموش است (${res.statusCode}). '
      'اپ را در پنل Liara روشن کنید، سپس:\n'
      '  ./scripts/test_transport_api.sh',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('transport.liara.run live API', () {
    late FakeTokenStorage tokens;

    setUp(() async {
      tokens = FakeTokenStorage();
      await tokens.clear();
    });

    test('server is up', _requireLiveServer);

    test('coordinator login + cargos + drivers', () async {
      await _requireLiveServer();
      final api = ApiClient(tokenStorage: tokens);
      final auth = AuthService(tokenStorage: tokens, apiClient: api);

      final ok = await auth.login(
        phone: normalizeIranPhone(_coordPhone),
        password: _password,
        role: UserRole.coordinator,
      );
      expect(ok, isTrue, reason: auth.lastError ?? 'login failed');
      expect(auth.currentUser?.role, UserRole.coordinator);

      final cargo = CargoService.withClient(api);
      final cargos = await cargo.getCoordinatorCargos();
      expect(cargos, isA<List>());

      final drivers = await cargo.getActiveDrivers();
      expect(drivers, isA<List>());
    });

    test('driver login + missions + location', () async {
      await _requireLiveServer();
      final api = ApiClient(tokenStorage: tokens);
      final auth = AuthService(tokenStorage: tokens, apiClient: api);

      final ok = await auth.login(
        phone: normalizeIranPhone(_driverPhone),
        password: _password,
        role: UserRole.driver,
      );
      expect(ok, isTrue, reason: auth.lastError ?? 'login failed');

      final cargo = CargoService.withClient(api);
      final missions = await cargo.getDriverMissions(
        driverPhone: normalizeIranPhone(_driverPhone),
        driverName: auth.currentUser?.fullName,
      );
      expect(missions, isA<List>());

      await cargo.reportDriverLocation(lat: 35.6892, lng: 51.3890);
    });

    test('estimate price', () async {
      await _requireLiveServer();
      final api = ApiClient(tokenStorage: tokens);
      final auth = AuthService(tokenStorage: tokens, apiClient: api);
      await auth.login(
        phone: normalizeIranPhone(_coordPhone),
        password: _password,
        role: UserRole.coordinator,
      );

      final cargo = CargoService.withClient(api);
      final price = await cargo.estimatePrice(
        origin: 'تهران، آزادی',
        destination: 'اصفهان',
        cargoType: 'کفی',
        goodsType: 'مصالح ساختمانی',
        weightTons: 12,
      );
      expect(price, greaterThan(0));
    });
  });
}
