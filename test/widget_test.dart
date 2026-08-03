import 'package:flutter_test/flutter_test.dart';

import 'package:legestic/app/app.dart';
import 'package:legestic/services/settings_service.dart';

void main() {
  testWidgets('App launches splash screen', (WidgetTester tester) async {
    await SettingsService().init();

    await tester.pumpWidget(LogisticsApp());
    await tester.pump();

    expect(find.text('لجستیک'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
  });
}
