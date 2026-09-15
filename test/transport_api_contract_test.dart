import 'package:flutter_test/flutter_test.dart';
import 'package:legestic/api_config.dart';
import 'package:legestic/models/user.dart';
import 'package:legestic/models/user_role.dart';

void main() {
  group('Transport OpenAPI contract', () {
    test('uses the develoop host and documented API paths', () {
      expect(ApiConfig.apiBaseUrl, 'https://tran-develoop.liara.run');
      expect(ApiConfig.loginPath, '/api/accounts/login');
      expect(ApiConfig.registerPath, '/api/accounts/register/');
      expect(ApiConfig.profilePath, '/api/accounts/profile/');
      expect(ApiConfig.changePasswordPath, '/api/accounts/change-password/');
      expect(ApiConfig.operatorBarsPath, '/api/operator/bars/');
      expect(ApiConfig.driverBarsPath, '/api/driver/bars/');
    });

    test('maps the documented profile response fields', () {
      final user = User.fromJson({
        'id': 12,
        'first_name': 'علی',
        'last_name': 'محمدی',
        'national_code': '1234567890',
        'phone_number': '09123456789',
        'is_driver': true,
        'is_operator': false,
        'driver_info': {
          'machine_id': 2,
          'machine_name': 'کفی',
          'ostan_id': 3,
          'ostan_name': 'تهران',
        },
      });

      expect(user.fullName, 'علی محمدی');
      expect(user.role, UserRole.driver);
      expect(user.nationalCode, '1234567890');
      expect(user.vehicleInfo?.machineId, 2);
      expect(user.vehicleInfo?.cargoType, 'کفی');
      expect(user.vehicleInfo?.ostanId, 3);
      expect(user.vehicleInfo?.ostanName, 'تهران');
    });
  });
}
