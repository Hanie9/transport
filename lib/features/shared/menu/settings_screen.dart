import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dark_mode_toggle.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/settings_service.dart';
import '../profile_settings_section.dart';
import 'widgets/menu_page_layout.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.watch<SettingsService>();
    final palette = context.palette;
    final isDark = settings.themeMode == ThemeMode.dark;

    return MenuPageLayout(
      title: l10n.settings,
      subtitle: l10n.settingsSubtitle,
      icon: Icons.tune_rounded,
      child: Column(
        children: [
          MenuSectionCard(
            title: l10n.appearance,
            child: _AppearanceTile(
              isDark: isDark,
              title: l10n.darkMode,
              subtitle: l10n.darkModeSubtitle,
              trailing: DarkModeToggle(
                value: isDark,
                onChanged: settings.toggleDarkMode,
              ),
            ),
          ),
          const SizedBox(height: 14),
          MenuSectionCard(
            title: l10n.localization,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.language_outlined,
                        color: AppTheme.primaryLight,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        l10n.language,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const ProfileLanguageDropdown(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppearanceTile extends StatelessWidget {
  const _AppearanceTile({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final bool isDark;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primary.withValues(alpha: 0.22),
                  AppTheme.primaryLight.withValues(alpha: 0.08),
                  palette.cardBg,
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.warning.withValues(alpha: 0.1),
                  AppTheme.accent.withValues(alpha: 0.05),
                  palette.cardBg,
                ],
              ),
        border: Border.all(
          color: isDark
              ? AppTheme.primaryLight.withValues(alpha: 0.28)
              : AppTheme.warning.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: isDark
                  ? const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                    ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppTheme.primaryLight : AppTheme.warning)
                      .withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: palette.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}
