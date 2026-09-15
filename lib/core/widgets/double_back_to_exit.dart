import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';

typedef ExitAppCallback = Future<void> Function();

/// Requires two back presses within [interval] before closing the app.
class DoubleBackToExit extends StatefulWidget {
  const DoubleBackToExit({
    super.key,
    required this.child,
    this.enabled = true,
    this.interval = const Duration(seconds: 2),
    this.exitApp,
  });

  final Widget child;
  final bool enabled;
  final Duration interval;
  final ExitAppCallback? exitApp;

  @override
  State<DoubleBackToExit> createState() => _DoubleBackToExitState();
}

class _DoubleBackToExitState extends State<DoubleBackToExit> {
  DateTime? _lastBackPressedAt;

  Future<void> _handleBack(bool didPop, Object? result) async {
    if (didPop || !widget.enabled) return;

    final now = DateTime.now();
    final lastPress = _lastBackPressedAt;
    if (lastPress != null && now.difference(lastPress) <= widget.interval) {
      _lastBackPressedAt = null;
      await (widget.exitApp ?? SystemNavigator.pop)();
      return;
    }

    _lastBackPressedAt = now;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.l10n.pressBackAgainToExit),
          duration: widget.interval,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: !widget.enabled,
    onPopInvokedWithResult: _handleBack,
    child: widget.child,
  );
}
