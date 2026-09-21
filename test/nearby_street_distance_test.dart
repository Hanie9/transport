import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:legestic/models/cargo.dart';
import 'package:legestic/services/api_client.dart';
import 'package:legestic/services/cargo_service.dart';
import 'package:legestic/services/neshan_models.dart';

import 'support/fake_token_storage.dart';

Cargo _cargo({
  required String id,
  String origin = 'تهران، خیابان ولیعصر',
  double? originLat,
  double? originLng,
}) {
  return Cargo(
    id: id,
    title: 'بار $id',
    origin: origin,
    destination: 'کرج',
    cargoType: 'کفی',
    goodsType: 'مصالح',
    weightTons: 10,
    estimatedPrice: 1000000,
    status: 'در انتظار راننده',
    coordinatorName: 'هماهنگ‌کننده',
    originLat: originLat,
    originLng: originLng,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  CargoService serviceWithStreetKm(double km) {
    return CargoService.withClient(
      ApiClient(
        client: MockClient((_) async => http.Response('[]', 200)),
        tokenStorage: FakeTokenStorage(),
      ),
      drivingDistanceKm: (from, to) async => km,
    );
  }

  test('distance tags use Neshan street distance, not crow-flies', () async {
    const driver = LatLng(35.6892, 51.3890);
    const origin = LatLng(35.7219, 51.3347);
    final straightKm = const Distance().as(LengthUnit.Kilometer, driver, origin);
    expect(straightKm, lessThan(10));

    final service = serviceWithStreetKm(18.6);
    final result = await service.withDistanceFromDriver(
      [
        _cargo(
          id: '1',
          originLat: origin.latitude,
          originLng: origin.longitude,
        ),
      ],
      driver,
    );

    expect(result.single.nearbyDistanceKm, 18.6);
    expect(result.single.isNearby, isTrue);
    expect(result.single.nearbyDistanceKm, isNot(closeTo(straightKm, 0.2)));
  });

  test('nearby flag follows street distance over the 40km radius', () async {
    final service = serviceWithStreetKm(41.2);
    final result = await service.withDistanceFromDriver(
      [_cargo(id: 'far', originLat: 35.7219, originLng: 51.3347)],
      const LatLng(35.6892, 51.3890),
    );

    expect(result.single.nearbyDistanceKm, 41.2);
    expect(result.single.isNearby, isFalse);
  });

  test('NeshanRoute.totalDistanceMeters sums street legs', () {
    const route = NeshanRoute(
      legs: [
        NeshanRouteLeg(
          summary: 'a',
          distanceText: '12.4 کیلومتر',
          distanceMeters: 12400,
          durationText: '',
          durationSeconds: 0,
          steps: [],
        ),
      ],
    );
    expect(route.totalDistanceMeters, 12400);
  });
}
