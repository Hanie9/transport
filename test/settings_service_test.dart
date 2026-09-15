import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:legestic/models/user_role.dart';
import 'package:legestic/services/settings_service.dart';

void main() {
  test('persists the last successfully used user role', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService();
    await settings.init();

    expect(settings.preferredRole, UserRole.driver);

    await settings.setPreferredRole(UserRole.coordinator);
    await settings.init();

    expect(settings.preferredRole, UserRole.coordinator);
  });
}
