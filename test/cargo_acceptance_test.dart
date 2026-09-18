import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:legestic/services/api_client.dart';
import 'package:legestic/services/cargo_service.dart';
import 'package:legestic/services/reference_data_service.dart';

import 'support/fake_token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('first acceptance succeeds and persists assignment and date', () async {
    var posts = 0;
    final client = MockClient((request) async {
      if (request.method == 'POST') {
        posts++;
        expect(request.url.path, '/api/driver/bars/18/accept/');
        expect(request.body, isEmpty);
        return http.Response(
          jsonEncode({
            'message': 'accepted',
            'assign_info': {
              'id': 1,
              'driver': 7,
              'driver_name': 'Driver',
              'driver_phone': '09121234567',
              'driver_machine': 'Truck',
              'confirm_driver': true,
              'confirm_operator': false,
              'created_at': '2026-09-18T19:16:13.109Z',
            },
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'id': 18,
          'title': 'Cargo',
          'status': 'open',
          'machine': 2,
          'price': 100,
        }),
        200,
      );
    });
    final service = CargoService.withClient(
      ApiClient(client: client, tokenStorage: FakeTokenStorage()),
    );

    expect(await service.acceptCargo('18', 'Driver', '09121234567'), isTrue);
    expect(service.lastError, isNull);
    expect(posts, 1);
    final mission = await DriverMissionStore.instance.findById('18');
    expect(mission?.status, 'تخصیص یافته');
    expect(mission?.createdAt, DateTime.parse('2026-09-18T19:16:13.109Z'));
    expect(mission?.assignedDriverPhone, '09121234567');
  });

  test('empty mission store can be removed from and updated safely', () async {
    await DriverMissionStore.instance.remove('missing');
    await DriverMissionStore.instance.updateStatus('missing', 'تحویل شده');
    expect(await DriverMissionStore.instance.load(), isEmpty);
  });
}
