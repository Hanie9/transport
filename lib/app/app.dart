import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import 'router.dart';

class LegesticApp extends StatelessWidget {
  LegesticApp({super.key});

  final AuthService _authService = AuthService();
  final SettingsService _settingsService = SettingsService();

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.create(_authService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authService),
        ChangeNotifierProvider.value(value: _settingsService),
      ],
      child: Consumer<SettingsService>(
        builder: (context, settings, _) {
          final useVazirmatn = !settings.isEnglish;

          return MaterialApp.router(
            title: settings.isEnglish ? 'Legestic' : 'لجستیک',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(useVazirmatn: useVazirmatn),
            darkTheme: AppTheme.dark(useVazirmatn: useVazirmatn),
            themeMode: settings.themeMode,
            locale: settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: router,
            builder: (context, child) {
              return Directionality(
                textDirection: settings.isEnglish ? TextDirection.ltr : TextDirection.rtl,
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
