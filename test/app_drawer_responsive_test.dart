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
    required Locale locale,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetPadding);

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
          locale: locale,
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
    for (final locale in [const Locale('fa'), const Locale('en')]) {
      for (final size in [
        const Size(320, 480),
        const Size(360, 640),
        const Size(390, 844),
        const Size(430, 932),
      ]) {
        testWidgets('$role $locale drawer fits $size without scrolling', (
          tester,
        ) async {
          await pumpDrawer(tester, role: role, size: size, locale: locale);

          expect(tester.takeException(), isNull);
          expect(find.byType(Scrollable), findsNothing);
          expect(
            tester.getSize(find.byType(Drawer)).width,
            closeTo((size.width * 0.82).clamp(0.0, 304.0), 0.01),
          );
          final context = tester.element(find.byType(AppDrawer));
          final l10n = AppLocalizations.of(context);
          for (final label in [
            l10n.logout,
            l10n.drawerOperations,
            l10n.homeQuickActions,
            l10n.drawerAccount,
            l10n.drawerAssistance,
          ]) {
            expect(find.text(label), findsOneWidget);
            final rect = tester.getRect(find.text(label));
            expect(rect.top, greaterThanOrEqualTo(0));
            expect(rect.bottom, lessThanOrEqualTo(size.height));
          }
        });
      }
    }
  }
}
