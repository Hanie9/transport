import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:legestic/core/theme/app_theme.dart';
import 'package:legestic/core/widgets/app_drawer.dart';
import 'package:legestic/l10n/app_localizations.dart';
import 'package:legestic/services/auth_service.dart';

void main() {
  Future<void> pumpDrawer(
    WidgetTester tester, {
    required String role,
    required Size size,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final router = GoRouter(
      initialLocation: '/$role',
      routes: [
        GoRoute(
          path: '/$role',
          builder: (context, state) => Scaffold(body: AppDrawer(role: role)),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthService(),
        child: MaterialApp.router(
          locale: const Locale('fa'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final role in ['driver', 'coordinator']) {
    testWidgets('$role drawer fits a short 320x480 phone without scrolling', (
      tester,
    ) async {
      await pumpDrawer(tester, role: role, size: const Size(320, 480));

      expect(tester.takeException(), isNull);
      expect(find.byType(Scrollable), findsNothing);
      expect(find.text('خروج از حساب'), findsOneWidget);
    });
  }
}
