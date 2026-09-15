import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legestic/core/theme/app_theme.dart';
import 'package:legestic/core/widgets/modern_dropdown.dart';

void main() {
  testWidgets('modern dropdown opens and selects an item', (tester) async {
    int? selected;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Padding(
              padding: const EdgeInsets.all(24),
              child: ModernDropdownField<int>(
                label: 'نوع ماشین',
                prefixIcon: Icons.local_shipping_rounded,
                value: selected,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('کفی')),
                  DropdownMenuItem(value: 2, child: Text('تریلی')),
                ],
                onChanged: (value) => setState(() => selected = value),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('نوع ماشین'));
    await tester.pumpAndSettle();
    expect(find.text('تریلی'), findsOneWidget);

    await tester.tap(find.text('تریلی'));
    await tester.pumpAndSettle();
    expect(selected, 2);
    expect(find.text('تریلی'), findsOneWidget);
  });
}
