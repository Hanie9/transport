import 'package:flutter_test/flutter_test.dart';

import 'package:legestic/services/neshan_models.dart';
import 'package:legestic/services/neshan_service.dart';
import 'package:legestic/utils/address_geocode_hints.dart';

void main() {
  test('parses Geocoding Plus latitude/longitude', () {
    final point = parseNeshanMapLocation({
      'latitude': 35.719934,
      'longitude': 51.340742,
    });
    expect(point?.latitude, closeTo(35.719934, 0.000001));
    expect(point?.longitude, closeTo(51.340742, 0.000001));
  });

  test('parses Search/v6 x=lng y=lat', () {
    final point = parseNeshanMapLocation({
      'x': 51.340742,
      'y': 35.719934,
    });
    expect(point?.latitude, closeTo(35.719934, 0.000001));
    expect(point?.longitude, closeTo(51.340742, 0.000001));
  });

  test('swaps reversed coordinates that fall outside Iran', () {
    final point = parseNeshanMapLocation({
      'latitude': 51.340742,
      'longitude': 35.719934,
    });
    expect(point?.latitude, closeTo(35.719934, 0.000001));
    expect(point?.longitude, closeTo(51.340742, 0.000001));
  });

  test('cargo geocoding sends city filters without downtown bias', () {
    final hints = extractGeocodeHints('تهران، شهرک صنعتی خاوران');
    final params = buildCargoGeocodeParams(
      address: 'تهران، شهرک صنعتی خاوران',
      hints: hints,
    );
    expect(params.city, 'تهران');
    expect(params.searchCenter, isNull);
    expect(params.searchExtent, isNull);
  });

  test('downtown pin is rejected for a specific cargo address', () {
    const address = 'تهران، شهرک صنعتی خاوران';
    final result = NeshanGeocodingResult(
      location: iranCityCentroids['تهران']!,
      city: 'تهران',
      province: 'تهران',
    );
    expect(isLikelyCityCentroidPoint(result.location, address), isTrue);
    expect(isHardRejectGeocodingResult(result, address), isTrue);
  });
}
