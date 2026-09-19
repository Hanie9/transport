import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legestic/services/api_client.dart';
import 'package:legestic/services/cargo_service.dart';

import 'support/fake_token_storage.dart';

void main() {
  test(
    'create sends weight and retries only when an old API rejects the field',
    () async {
      final bodies = <Map<String, dynamic>>[];
      final service = CargoService.withClient(
        ApiClient(
          tokenStorage: FakeTokenStorage(),
          client: MockClient((request) async {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            bodies.add(body);
            if (bodies.length == 1) {
              return http.Response(
                '{"weight":["Unknown field."]}',
                400,
                headers: {'content-type': 'application/json'},
              );
            }
            return http.Response(
              jsonEncode({...body, 'id': 1, 'status': 'open'}),
              201,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
      );

      final cargo = await service.createCargo(
        title: 'بار',
        description: 'توضیحات',
        origin: 'تهران',
        destination: 'شیراز',
        cargoType: 'کفی',
        goodsType: 'تیرآهن',
        weightTons: 12.5,
        estimatedPrice: 100,
      );

      expect(bodies, hasLength(2));
      expect(bodies.first['weight'], 12.5);
      expect(bodies.last.containsKey('weight'), isFalse);
      expect(bodies.last['description'], contains('وزن: 12.5 تن'));
      expect(cargo.weightTons, 12.5);
    },
  );
}
