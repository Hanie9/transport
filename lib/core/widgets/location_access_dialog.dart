import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/location_service.dart';
import '../theme/app_theme.dart';

/// Asks for location using system permission / device-location dialogs only.
///
/// Does not open the Settings app unless permission is permanently denied and
/// the user explicitly chooses to open app settings.
Future<bool> requestLocationAccessWithDialog(
  BuildContext context, {
  required String title,
  required String message,
  bool showRationaleFirst = false,
}) async {
  final location = LocationService();
  if (await location.isGpsReady()) {
    final pos = await location.getCurrentPosition(requestIfNeeded: false);
    if (pos != null) return true;
  }

  final l10n = context.l10n;

  if (showRationaleFirst) {
    if (!context.mounted) return false;
    final proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 32),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.locationEnableAction),
            ),
          ],
        );
      },
    );
    if (proceed != true || !context.mounted) return false;
  }

  final result = await location.requestGpsAccess();
  if (!context.mounted) return false;

  switch (result.status) {
    case GpsAccessStatus.ready:
      return true;
    case GpsAccessStatus.permissionDeniedForever:
      return _promptOpenAppSettings(context, title: title, message: l10n.locationPermissionDeniedForever);
    case GpsAccessStatus.permissionDenied:
    case GpsAccessStatus.serviceDisabled:
    case GpsAccessStatus.unavailable:
      return false;
  }
}

Future<bool> _promptOpenAppSettings(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final l10n = context.l10n;
  final open = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.settings_outlined, color: AppTheme.warning, size: 32),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.openAppSettings),
          ),
        ],
      );
    },
  );
  if (open != true) return false;

  await LocationService().openAppPermissionSettings();
  if (!context.mounted) return false;
  await Future<void>.delayed(const Duration(milliseconds: 400));
  return LocationService().isGpsReady();
}

/// Explains that nearby GPS was turned off in the app.
Future<void> showNearbyGpsDisabledDialog(BuildContext context) async {
  final l10n = context.l10n;
  final openSettings = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.gps_off_rounded, color: AppTheme.warning, size: 32),
        title: Text(l10n.gpsDisableTitle),
        content: Text(l10n.gpsDisableMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.gpsDisableConfirm),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.openLocationSettings),
          ),
        ],
      );
    },
  );

  if (openSettings == true) {
    await LocationService().openSystemLocationSettings();
  }
}
