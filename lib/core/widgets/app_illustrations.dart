import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Decorative logistics motif for hero sections.
class LogisticsHeroArt extends StatelessWidget {
  const LogisticsHeroArt({super.key, this.size = 110});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 0,
            bottom: 8,
            child: _Orb(color: Colors.white.withValues(alpha: 0.14), size: size * 0.55),
          ),
          Positioned(
            left: 4,
            top: 6,
            child: _Orb(color: Colors.white.withValues(alpha: 0.1), size: size * 0.35),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: size * 0.62,
              height: size * 0.62,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: Icon(
                Icons.local_shipping_rounded,
                size: size * 0.34,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyCargoIllustration extends StatelessWidget {
  const EmptyCargoIllustration({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: isDark ? 0.22 : 0.14),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Container(
            width: size * 0.72,
            height: size * 0.72,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.18)),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              size: size * 0.36,
              color: AppTheme.primary.withValues(alpha: 0.65),
            ),
          ),
          Positioned(
            right: size * 0.08,
            top: size * 0.1,
            child: _Orb(color: AppTheme.accent.withValues(alpha: 0.35), size: 14),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
