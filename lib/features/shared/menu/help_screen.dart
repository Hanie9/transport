import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import 'widgets/menu_page_layout.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = role == 'driver'
        ? _driverItems(l10n)
        : _coordinatorItems(l10n);

    return MenuPageLayout(
      title: l10n.help,
      subtitle: l10n.helpRoleSubtitle(role),
      icon: Icons.help_outline_rounded,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.warning.withValues(alpha: 0.16),
                  AppTheme.accent.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.warning.withValues(alpha: 0.24),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.health_and_safety_rounded,
                  color: AppTheme.warning,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.transportSafetyTitle,
                        style: TextStyle(
                          color: context.palette.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        l10n.transportSafetyBody,
                        style: TextStyle(
                          color: context.palette.textSecondary,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < items.length - 1 ? 10 : 0,
              ),
              child: _HelpSectionCard(item: entry.value, index: index + 1),
            );
          }),
        ],
      ),
    );
  }

  static List<_HelpItemData> _driverItems(AppLocalizations l10n) => [
    _HelpItemData(
      icon: Icons.home_outlined,
      color: AppTheme.primary,
      title: l10n.helpDriverHomeTitle,
      body: l10n.helpDriverHomeBody,
    ),
    _HelpItemData(
      icon: Icons.inventory_2_outlined,
      color: AppTheme.primaryLight,
      title: l10n.helpDriverCargosTitle,
      body: l10n.helpDriverCargosBody,
    ),
    _HelpItemData(
      icon: Icons.gps_fixed,
      color: AppTheme.accent,
      title: l10n.helpDriverGpsTitle,
      body: l10n.helpDriverGpsBody,
    ),
    _HelpItemData(
      icon: Icons.check_circle_outline_rounded,
      color: AppTheme.success,
      title: l10n.helpDriverAcceptTitle,
      body: l10n.helpDriverAcceptBody,
    ),
    _HelpItemData(
      icon: Icons.assignment_outlined,
      color: AppTheme.primaryLight,
      title: l10n.helpDriverMissionsTitle,
      body: l10n.helpDriverMissionsBody,
    ),
    _HelpItemData(
      icon: Icons.navigation_outlined,
      color: AppTheme.warning,
      title: l10n.helpDriverNavigationTitle,
      body: l10n.helpDriverNavigationBody,
    ),
    _HelpItemData(
      icon: Icons.person_outline,
      color: AppTheme.primary,
      title: l10n.helpDriverProfileTitle,
      body: l10n.helpDriverProfileBody,
    ),
    _HelpItemData(
      icon: Icons.menu_rounded,
      color: AppTheme.textSecondary,
      title: l10n.helpDriverMenuTitle,
      body: l10n.helpDriverMenuBody,
    ),
  ];

  static List<_HelpItemData> _coordinatorItems(AppLocalizations l10n) => [
    _HelpItemData(
      icon: Icons.home_outlined,
      color: AppTheme.primary,
      title: l10n.helpCoordinatorHomeTitle,
      body: l10n.helpCoordinatorHomeBody,
    ),
    _HelpItemData(
      icon: Icons.list_alt_outlined,
      color: AppTheme.primaryLight,
      title: l10n.helpCoordinatorCargosTitle,
      body: l10n.helpCoordinatorCargosBody,
    ),
    _HelpItemData(
      icon: Icons.add_box_outlined,
      color: AppTheme.accent,
      title: l10n.helpCoordinatorAddCargoTitle,
      body: l10n.helpCoordinatorAddCargoBody,
    ),
    _HelpItemData(
      icon: Icons.info_outline_rounded,
      color: AppTheme.success,
      title: l10n.helpCoordinatorCargoDetailTitle,
      body: l10n.helpCoordinatorCargoDetailBody,
    ),
    _HelpItemData(
      icon: Icons.edit_note_rounded,
      color: AppTheme.primaryLight,
      title: l10n.helpCoordinatorEditTitle,
      body: l10n.helpCoordinatorEditBody,
    ),
    _HelpItemData(
      icon: Icons.admin_panel_settings_rounded,
      color: AppTheme.warning,
      title: l10n.helpCoordinatorSecurityTitle,
      body: l10n.helpCoordinatorSecurityBody,
    ),
    _HelpItemData(
      icon: Icons.person_outline,
      color: AppTheme.primary,
      title: l10n.helpCoordinatorProfileTitle,
      body: l10n.helpCoordinatorProfileBody,
    ),
    _HelpItemData(
      icon: Icons.menu_rounded,
      color: AppTheme.textSecondary,
      title: l10n.helpCoordinatorMenuTitle,
      body: l10n.helpCoordinatorMenuBody,
    ),
  ];
}

class _HelpItemData {
  const _HelpItemData({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
}

class _HelpSectionCard extends StatelessWidget {
  const _HelpSectionCard({required this.item, required this.index});

  final _HelpItemData item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: palette.cardBg,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: index == 1,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: item.color,
        collapsedIconColor: palette.textSecondary,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(item.icon, color: item.color, size: 22),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: palette.textPrimary,
          ),
        ),
        subtitle: Text(
          '${index.toString().padLeft(2, '0')}  •  ${context.l10n.help}',
          style: TextStyle(color: palette.textSecondary, fontSize: 10),
        ),
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              item.body,
              style: TextStyle(
                color: palette.textSecondary,
                height: 1.7,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
