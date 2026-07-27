import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../services/settings_service.dart';

class ProfileSettingsSection extends StatelessWidget {
  const ProfileSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.watch<SettingsService>();
    final palette = context.palette;

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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(Icons.dark_mode_outlined, color: AppTheme.primaryLight),
            title: Text(l10n.darkMode, style: TextStyle(color: palette.textPrimary)),
            subtitle: Text(l10n.darkModeSubtitle, style: TextStyle(color: palette.textSecondary)),
            value: settings.themeMode == ThemeMode.dark,
            onChanged: settings.toggleDarkMode,
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
                      ProfileLanguageDropdown(),
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
                    color: isSelected ? AppTheme.primary : palette.textPrimary,
                  ),
                ),
              ),
              if (isSelected) const Icon(Icons.check_rounded, size: 18, color: AppTheme.primary),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openMenu(context),
        borderRadius: BorderRadius.circular(_radius),
        child: Ink(
          decoration: BoxDecoration(
            color: palette.cardBg,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: palette.divider),
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
                Icon(Icons.keyboard_arrow_down_rounded, color: palette.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
