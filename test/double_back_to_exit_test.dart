import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legestic/core/widgets/double_back_to_exit.dart';
import 'package:legestic/l10n/app_localizations.dart';

void main() {
  Future<GlobalKey<NavigatorState>> pumpExitApp(
    WidgetTester tester, {
    required Locale locale,
    required void Function() onExit,
  }) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: DoubleBackToExit(
          exitApp: () async => onExit(),
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return navigatorKey;
  }

  testWidgets('shows Persian exit hint and exits on second back', (
    tester,
  ) async {
    var exits = 0;
    final navigatorKey = await pumpExitApp(
      tester,
      locale: const Locale('fa', 'IR'),
      onExit: () => exits++,
    );

    await navigatorKey.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('برای خروج، دوباره دکمه بازگشت را بزنید'), findsOneWidget);
    expect(exits, 0);

    await navigatorKey.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(exits, 1);
  });

  testWidgets('shows English exit hint', (tester) async {
    final navigatorKey = await pumpExitApp(
      tester,
      locale: const Locale('en', 'US'),
      onExit: () {},
    );

    await navigatorKey.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Press back again to exit'), findsOneWidget);
  });
}
