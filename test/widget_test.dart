import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:legestic/app/app.dart';
import 'package:legestic/services/settings_service.dart';

void main() {
  testWidgets('App launches splash screen', (WidgetTester tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    await SettingsService().init();

    await tester.pumpWidget(LogisticsApp());
    await tester.pump();

    expect(find.text('لجستیک'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
