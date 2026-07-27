import 'package:flutter/material.dart';

class ShellScope extends InheritedWidget {
  const ShellScope({
    super.key,
    required this.openDrawer,
    required super.child,
  });

  final VoidCallback openDrawer;

  static ShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShellScope>();
  }

  static ShellScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'ShellScope not found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(ShellScope oldWidget) => openDrawer != oldWidget.openDrawer;
}
