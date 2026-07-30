import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/dark_mode_toggle.dart';
import '../../l10n/app_localizations.dart';
import '../../services/settings_service.dart';

class ProfileSettingsSection extends StatelessWidget {
  const ProfileSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.watch<SettingsService>();
    final palette = context.palette;
    final isDark = settings.themeMode == ThemeMode.dark;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Text(
              l10n.settings,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: palette.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDark
                        ? AppTheme.primaryLight.withValues(alpha: 0.16)
                        : AppTheme.warning.withValues(alpha: 0.14),
                  ),
                  child: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: isDark ? AppTheme.primaryLight : AppTheme.warning,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.darkMode,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.darkModeSubtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                DarkModeToggle(
                  value: isDark,
                  onChanged: settings.toggleDarkMode,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: palette.divider),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(Icons.language_outlined, color: AppTheme.primaryLight),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.language,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const ProfileLanguageDropdown(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileLanguageDropdown extends StatelessWidget {
  const ProfileLanguageDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.watch<SettingsService>();

    return _LanguageDropdown(
      value: settings.isEnglish ? 'en' : 'fa',
      options: {
        'fa': l10n.languagePersian,
        'en': l10n.languageEnglish,
      },
      onChanged: (value) {
        settings.setLocale(
          value == 'en' ? const Locale('en', 'US') : const Locale('fa', 'IR'),
        );
      },
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  static const _radius = 12.0;

  Future<void> _openMenu(BuildContext context) async {
    final palette = context.palette;
    final box = context.findRenderObject()! as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    final selected = await showMenu<String>(
      context: context,
      color: palette.cardBg,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
        side: BorderSide(color: palette.divider),
      ),
      constraints: BoxConstraints.tightFor(width: size.width),
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height,
        offset.dx + size.width,
        offset.dy + size.height,
      ),
      items: options.entries.map((entry) {
        final isSelected = entry.key == value;
        return PopupMenuItem<String>(
          value: entry.key,
          height: size.height,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.primaryLight
                            : AppTheme.primary)
                        : palette.textPrimary,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.primaryLight
                      : AppTheme.primary,
                ),
            ],
          ),
        );
      }).toList(),
    );

    if (selected != null && selected != value) {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.primaryLight : AppTheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openMenu(context),
        borderRadius: BorderRadius.circular(_radius),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.55) : palette.surface,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(
              color: isDark ? const Color(0xFF475569) : palette.divider,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    options[value] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
