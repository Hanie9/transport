/// Live login/bar tests are run via `./scripts/test_transport_api.sh` because
/// `flutter test` mocks HTTP POST with status 400.
@Skip('Run ./scripts/test_transport_api.sh for live Transport API verification')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://tran-develoop.liara.run',
);

void main() {
  test('docs endpoint is reachable', () async {
    final res = await http
        .get(Uri.parse('$_baseUrl/api/docs/'))
        .timeout(const Duration(seconds: 20));
    expect(res.statusCode, lessThan(500));
    expect(res.body.contains('Application Error'), isFalse);
  });
}
