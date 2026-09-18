import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legestic/services/api_client.dart';
import 'package:legestic/services/cargo_service.dart';
import 'package:legestic/services/transport_api_mapper.dart';
import 'support/fake_token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'operator PATCH sends changes, PUT saves full details, DELETE uses documented path',
    () async {
      final requests = <http.Request>[];
      final service = CargoService.withClient(
        ApiClient(
          client: MockClient((request) async {
            requests.add(request);
            return http.Response('{"message":"ok","data":{}}', 200);
          }),
          tokenStorage: FakeTokenStorage(),
        ),
      );
      final original = TransportApiMapper.cargoFromBar({
        'id': 18,
        'title': 'Cargo',
        'description': 'Details',
        'price': 100,
        'status': 'open',
        'address_mabda': 'Tehran',
      });
      expect(
        await service.updateCargo(
          cargoId: '18',
          title: 'Cargo',
          description: 'Details',
          price: 200,
          originalCargo: original,
        ),
        isTrue,
      );
      expect(requests.last.method, 'PATCH');
      expect(requests.last.url.path, '/api/operator/bars/18/update/');
      expect(jsonDecode(requests.last.body), {'price': 200});
      expect(
        await service.updateCargo(
          cargoId: '18',
          title: 'Cargo',
          description: 'Details',
          price: 100,
          fullReplace: true,
          originalCargo: original,
        ),
        isTrue,
      );
      expect(requests.last.method, 'PUT');
      expect(jsonDecode(requests.last.body), {
        'title': 'Cargo',
        'description': 'Details',
        'price': 100,
      });
      expect(await service.deleteCargo('18'), isTrue);
      expect(requests.last.method, 'DELETE');
      expect(requests.last.url.path, '/api/operator/bars/18/delete/');
      final count = requests.length;
      expect(
        await service.updateCargo(
          cargoId: '18',
          title: 'Cargo',
          originalCargo: original,
        ),
        isTrue,
      );
      expect(requests.length, count);
    },
  );
}
