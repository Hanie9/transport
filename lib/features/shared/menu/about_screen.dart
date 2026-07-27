import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import 'widgets/menu_page_layout.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;

    return MenuPageLayout(
      title: l10n.aboutUs,
      subtitle: l10n.appTagline,
      icon: Icons.info_outline_rounded,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.28),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_shipping_rounded, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.appName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.versionLabel('1.0.0'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          MenuSectionCard(
            child: Text(
              l10n.aboutDescription,
              style: TextStyle(color: palette.textSecondary, height: 1.65, fontSize: 14),
            ),
          ),
          const SizedBox(height: 14),
          MenuSectionCard(
            title: l10n.appName,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FeatureChip(icon: Icons.local_shipping_outlined, label: l10n.cargos),
                _FeatureChip(icon: Icons.gps_fixed, label: 'GPS'),
                _FeatureChip(icon: Icons.people_outline, label: l10n.drivers),
                _FeatureChip(icon: Icons.route_outlined, label: l10n.navigation),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
