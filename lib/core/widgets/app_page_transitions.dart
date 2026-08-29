import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared route transitions for a cohesive, modern navigation feel.
abstract final class AppPageTransitions {
  static const Duration forward = Duration(milliseconds: 320);
  static const Duration reverse = Duration(milliseconds: 260);

  static CustomTransitionPage<T> fadeSlide<T>({
    required LocalKey key,
    required Widget child,
    Offset beginOffset = const Offset(0, 0.04),
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: forward,
      reverseTransitionDuration: reverse,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  static CustomTransitionPage<T> sharedAxisHorizontal<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: forward,
      reverseTransitionDuration: reverse,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final offset = Tween<Offset>(
          begin: const Offset(0.06, 0),
          end: Offset.zero,
        ).animate(curved);
        return SlideTransition(
          position: offset,
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  static CustomTransitionPage<T> fade<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }
}
