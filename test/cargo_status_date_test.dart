import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legestic/core/widgets/common_widgets.dart';
import 'package:legestic/core/theme/app_theme.dart';
import 'package:legestic/l10n/app_localizations.dart';

void main() {
  for (final language in ['fa', 'en']) {
    testWidgets('cargo status and Jalali date in $language', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(language),
          theme: AppTheme.light(),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: StatusChip(
              status: 'تخصیص یافته',
              date: DateTime(2026, 3, 21),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(language == 'fa' ? '۱۴۰۵/۰۱/۰۱' : '1405/01/01'),
        findsOneWidget,
      );
      expect(
        find.text(language == 'fa' ? 'تخصیص یافته' : 'Assigned'),
        findsOneWidget,
      );
    });
  }
}
