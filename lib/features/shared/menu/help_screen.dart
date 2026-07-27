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
    final items = role == 'driver' ? _driverItems(l10n) : _coordinatorItems(l10n);

    return MenuPageLayout(
      title: l10n.help,
      subtitle: l10n.helpRoleSubtitle(role),
      icon: Icons.help_outline_rounded,
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: index < items.length - 1 ? 12 : 0),
            child: _HelpSectionCard(item: item, index: index + 1),
          );
        }).toList(),
      ),
    );
  }

  static List<_HelpItemData> _driverItems(AppLocalizations l10n) => [
        _HelpItemData(
          icon: Icons.inventory_2_outlined,
          color: AppTheme.primary,
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
          icon: Icons.list_alt_outlined,
          color: AppTheme.primary,
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
          icon: Icons.people_outline,
          color: AppTheme.primaryLight,
          title: l10n.helpCoordinatorDriversTitle,
          body: l10n.helpCoordinatorDriversBody,
        ),
        _HelpItemData(
          icon: Icons.near_me_outlined,
          color: AppTheme.warning,
          title: l10n.helpCoordinatorNearbyTitle,
          body: l10n.helpCoordinatorNearbyBody,
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

    return Container(
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: palette.cardShadow,
        border: Border.all(color: item.color.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: item.color,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.body,
            style: TextStyle(
              color: palette.textSecondary,
              height: 1.6,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
