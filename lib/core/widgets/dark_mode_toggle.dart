import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Animated sun/moon toggle for light and dark themes.
class DarkModeToggle extends StatelessWidget {
  const DarkModeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: value ? 'Dark mode' : 'Light mode',
      toggled: value,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          width: 64,
          height: 36,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: value
                ? LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF1E293B), Color(0xFF0F766E)]
                        : [AppTheme.primaryDark, AppTheme.primary],
                  )
                : null,
            color: value
                ? null
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            boxShadow: value
                ? [
                    BoxShadow(
                      color: (isDark ? AppTheme.primaryLight : AppTheme.primary)
                          .withValues(alpha: isDark ? 0.45 : 0.28),
                      blurRadius: isDark ? 14 : 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
            border: Border.all(
              color: value
                  ? (isDark ? AppTheme.primaryLight.withValues(alpha: 0.55) : Colors.transparent)
                  : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
              width: value && isDark ? 1.2 : 1,
            ),
          ),
          child: Stack(
            children: [
              // Soft glow when dark mode is on
              if (value)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: RadialGradient(
                        center: Alignment.centerRight,
                        radius: 0.9,
                        colors: [
                          Colors.white.withValues(alpha: isDark ? 0.14 : 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              AnimatedAlign(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: value
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? const [Color(0xFFF8FAFC), Color(0xFFE2E8F0)]
                                : const [Colors.white, Color(0xFFF8FAFC)],
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: value
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.55)
                            : Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                        blurRadius: value ? 10 : 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: Icon(
                      value ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      key: ValueKey(value),
                      size: 16,
                      color: value ? const Color(0xFF0F172A) : AppTheme.warning,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
