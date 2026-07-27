import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
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

    return MenuPageLayout(
      title: l10n.settings,
      subtitle: l10n.settingsSubtitle,
      icon: Icons.tune_rounded,
      child: Column(
        children: [
          MenuSectionCard(
            title: l10n.appearance,
            child: MenuSettingTile(
              icon: Icons.dark_mode_outlined,
              title: l10n.darkMode,
              subtitle: l10n.darkModeSubtitle,
              iconColor: AppTheme.accent,
              trailing: Switch.adaptive(
                value: settings.themeMode == ThemeMode.dark,
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
                      child: const Icon(Icons.language_outlined, color: AppTheme.primaryLight, size: 22),
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
