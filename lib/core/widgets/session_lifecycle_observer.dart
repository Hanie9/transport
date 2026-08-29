import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/session_service.dart';

/// Expires the auth session after the app stays in the background too long.
class SessionLifecycleObserver extends StatefulWidget {
  const SessionLifecycleObserver({
    super.key,
    required this.auth,
    required this.child,
  });

  final AuthService auth;
  final Widget child;

  @override
  State<SessionLifecycleObserver> createState() => _SessionLifecycleObserverState();
}

class _SessionLifecycleObserverState extends State<SessionLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.auth.isAuthenticated) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(SessionService().markBackgrounded());
      case AppLifecycleState.resumed:
        unawaited(_handleResume());
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _handleResume() async {
    if (!widget.auth.isAuthenticated) return;
    if (await SessionService().shouldRequireLogin()) {
      await widget.auth.expireSession();
      return;
    }
    await SessionService().clearBackgroundMarker();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
