import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:legestic/core/theme/app_theme.dart';
import 'package:legestic/features/auth/login_screen.dart';
import 'package:legestic/features/auth/signup_screen.dart';
import 'package:legestic/l10n/app_localizations.dart';
import 'package:legestic/services/auth_service.dart';
import 'package:legestic/services/settings_service.dart';

void main() {
  for (final signup in [false, true]) {
    for (final locale in [const Locale('fa'), const Locale('en')]) {
      for (final size in [
        const Size(320, 480),
        const Size(360, 640),
        const Size(390, 844),
        const Size(430, 932),
        const Size(844, 390),
      ]) {
        testWidgets(
          '${signup ? 'signup' : 'login'} $locale $size fits with keyboard and large text',
          (tester) async {
            SharedPreferences.setMockInitialValues({});
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = size;
            tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetPadding);
            addTearDown(tester.view.resetViewInsets);
            final router = GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, _) =>
                      signup ? const SignupScreen() : const LoginScreen(),
                ),
              ],
            );
            addTearDown(router.dispose);
            await tester.pumpWidget(
              MultiProvider(
                providers: [
                  ChangeNotifierProvider(create: (_) => AuthService()),
                  ChangeNotifierProvider.value(value: SettingsService()),
                ],
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
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(1.6)),
                    child: child!,
                  ),
                  routerConfig: router,
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final lastInput = find.byType(TextFormField).last;
            await tester.ensureVisible(lastInput);
            await tester.tap(lastInput);
            tester.view.viewInsets = FakeViewPadding(
              bottom: size.height < 500 ? 180 : 280,
            );
            await tester.pumpAndSettle();
            await tester.ensureVisible(lastInput);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(
              tester.getRect(lastInput).bottom,
              lessThanOrEqualTo(
                size.height - tester.view.viewInsets.bottom + 1,
              ),
            );
            await tester.ensureVisible(find.byType(ElevatedButton));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(
              tester.getRect(find.byType(ElevatedButton)).bottom,
              lessThanOrEqualTo(
                size.height - tester.view.viewInsets.bottom + 1,
              ),
            );
          },
        );
      }
    }
  }
}
