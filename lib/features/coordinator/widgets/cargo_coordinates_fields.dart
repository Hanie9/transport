import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Optional API coordinate fields for bar create/update payloads.
class CargoCoordinatesFields extends StatelessWidget {
  const CargoCoordinatesFields({
    super.key,
    required this.originLatController,
    required this.originLngController,
    required this.destinationLatController,
    required this.destinationLngController,
  });

  final TextEditingController originLatController;
  final TextEditingController originLngController;
  final TextEditingController destinationLatController;
  final TextEditingController destinationLngController;

  static double? parseCoordinate(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return double.tryParse(trimmed.replaceAll(',', '.'));
  }

  static String? validateCoordinate(String? value, AppLocalizations l10n) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final parsed = double.tryParse(trimmed.replaceAll(',', '.'));
    if (parsed == null) return l10n.invalidCoordinate;
    if (parsed < -180 || parsed > 180) return l10n.invalidCoordinate;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.coordinatesSection,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.coordinatesOptional,
          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: originLatController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.originLatitude,
                  prefixIcon: const Icon(Icons.my_location_outlined),
                  hintText: '35.6892',
                ),
                validator: (v) => validateCoordinate(v, l10n),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: originLngController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.originLongitude,
                  prefixIcon: const Icon(Icons.explore_outlined),
                  hintText: '51.3890',
                ),
                validator: (v) => validateCoordinate(v, l10n),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: destinationLatController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.destinationLatitude,
                  prefixIcon: const Icon(Icons.place_outlined),
                  hintText: '32.6539',
                ),
                validator: (v) => validateCoordinate(v, l10n),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: destinationLngController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.destinationLongitude,
                  prefixIcon: const Icon(Icons.explore_outlined),
                  hintText: '51.6660',
                ),
                validator: (v) => validateCoordinate(v, l10n),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
