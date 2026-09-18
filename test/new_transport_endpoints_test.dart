import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legestic/models/user.dart';
import 'package:legestic/services/api_client.dart';
import 'package:legestic/services/auth_service.dart';
import 'package:legestic/services/cargo_service.dart';
import 'package:legestic/services/transport_api_mapper.dart';
import 'support/fake_token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'assigned missions come from authenticated server across all pages',
    () async {
      final pages = <String>[];
      final tokens = FakeTokenStorage();
      await tokens.saveTokens(access: 'test-token');
      final service = CargoService.withClient(
        ApiClient(
          tokenStorage: tokens,
          client: MockClient((request) async {
            expect(request.url.path, '/api/driver/bars/assigned/');
            expect(request.headers['Authorization'], 'Bearer test-token');
            final page = request.url.queryParameters['page']!;
            pages.add(page);
            return http.Response(
              jsonEncode({
                'current_page': int.parse(page),
                'total_pages': 2,
                'next': page == '1' ? 'next' : null,
                'results': [
                  {
                    'id': page,
                    'status': page == '1' ? 'assign' : 'done',
                    'assign_info': {
                      'confirm_driver': true,
                      'confirm_operator': page == '2',
                    },
                  },
                ],
              }),
              200,
            );
          }),
        ),
      );
      final missions = await service.getDriverMissions();
      expect(pages, ['1', '2']);
      expect(missions.length, 2);
      expect(missions.first.confirmDriver, isTrue);
      expect(missions.last.confirmOperator, isTrue);
    },
  );
  test(
    'both completion roles POST without body, never PATCH status done',
    () async {
      final paths = <String>[];
      final service = CargoService.withClient(
        ApiClient(
          tokenStorage: FakeTokenStorage(),
          client: MockClient((request) async {
            expect(request.method, 'POST');
            expect(request.body, isEmpty);
            paths.add(request.url.path);
            return http.Response(
              '{"message":"ok","bar_status":"assign","assign_info":{"confirm_driver":true,"confirm_operator":false}}',
              200,
            );
          }),
        ),
      );
      expect(await service.completeCargo('18', asDriver: true), isTrue);
      expect(await service.updateCargoStatus('18', 'تحویل شده'), isTrue);
      expect(paths, [
        '/api/driver/bars/18/complete/',
        '/api/operator/bars/18/complete/',
      ]);
      final cargo = TransportApiMapper.cargoFromBar({
        'status': 'assign',
        'assign_info': {'confirm_driver': true, 'confirm_operator': false},
      });
      expect(cargo.status, 'تخصیص یافته');
      expect(cargo.confirmDriver, isTrue);
      expect(cargo.confirmOperator, isFalse);
    },
  );
  test('profile refresh and vehicle edit use remote pelak and model', () async {
    final tokens = FakeTokenStorage();
    await tokens.saveTokens(access: 'test-token');
    final auth = AuthService(
      tokenStorage: tokens,
      apiClient: ApiClient(
        tokenStorage: tokens,
        client: MockClient((request) async {
          expect(request.url.path, '/api/accounts/profile/');
          if (request.method == 'PUT') {
            final body = jsonDecode(request.body) as Map;
            if (body.containsKey('pelak')) {
              expect(body['pelak'], '12ب34566');
              expect(body['model'], 'Volvo');
            } else {
              expect(body['first_name'], 'Ali');
              expect(body['last_name'], 'Mohammadi');
              expect(body['national_code'], '1234567890');
            }
            expect(body.containsKey('phone_number'), isFalse);
          }
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'id': 7,
                'phone_number': '09121234567',
                'first_name': 'Driver',
                'is_driver': true,
                'driver_info': {
                  'machine_id': 2,
                  'machine_name': 'Truck',
                  'pelak': '12ب34566',
                  'model': 'Volvo',
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );
    await auth.restoreSession();
    expect(auth.lastError, isNull);
    expect(auth.currentUser?.vehicleInfo?.plateNumber, '12ب34566');
    expect(auth.currentUser?.vehicleInfo?.vehicleModel, 'Volvo');
    expect(
      await auth.updateVehicleInfo(
        const VehicleInfo(
          plateNumber: '۱۲ ب ۳۴۵ ایران ۶۶',
          cargoType: 'Truck',
          vehicleModel: 'Volvo',
          machineId: 2,
        ),
      ),
      isTrue,
    );
    expect(
      await auth.updateProfile(
        fullName: 'Ali Mohammadi',
        nationalCode: '1234567890',
      ),
      isTrue,
    );
  });
}
