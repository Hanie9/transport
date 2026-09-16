import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'logout_dialog.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.role});

  final String role;

  static const _menuSegments = [
    'settings',
    'about',
    'help',
    'support',
    'change-password',
  ];

  static bool hidesBottomNav(String location, String role) {
    final basePath = role == 'driver' ? '/driver' : '/coordinator';
    return _menuSegments.any(
      (segment) => location.startsWith('$basePath/$segment'),
    );
  }

  static bool isMenuRoute(String location) =>
      hidesBottomNav(location, 'driver') ||
      hidesBottomNav(location, 'coordinator');

  String get _basePath => role == 'driver' ? '/driver' : '/coordinator';

  void _navigate(BuildContext context, String path) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final user = context.watch<AuthService>().currentUser;
    final location = GoRouterState.of(context).uri.path;
    final fullName = user?.fullName.trim() ?? '';
    final initial = fullName.isEmpty ? '?' : fullName.characters.first;
    final viewportWidth = MediaQuery.sizeOf(context).width;

    final mainNavigationItems = role == 'driver'
        ? [
            _DrawerDestination(Icons.home_rounded, l10n.home, _basePath),
            _DrawerDestination(
              Icons.inventory_2_rounded,
              l10n.cargos,
              '$_basePath/cargos',
            ),
            _DrawerDestination(
              Icons.route_rounded,
              l10n.missions,
              '$_basePath/missions',
            ),
            _DrawerDestination(
              Icons.person_rounded,
              l10n.profile,
              '$_basePath/profile',
            ),
          ]
        : [
            _DrawerDestination(Icons.home_rounded, l10n.home, _basePath),
            _DrawerDestination(
              Icons.inventory_2_rounded,
              l10n.cargos,
              '$_basePath/cargos',
            ),
            _DrawerDestination(
              Icons.person_rounded,
              l10n.profile,
              '$_basePath/profile',
            ),
          ];

    final quickAction = role == 'driver'
        ? _DrawerDestination(
            Icons.near_me_rounded,
            l10n.nearbyCargos,
            '$_basePath/nearby',
          )
        : _DrawerDestination(
            Icons.add_box_rounded,
            l10n.addCargo,
            '$_basePath/add-cargo',
          );

    return Drawer(
      width: (viewportWidth * 0.82).clamp(0.0, 304.0),
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.horizontal(
          end: Radius.circular(28),
        ),
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Keep the reference design at every size; distribute vertical
            // space instead of switching to a different, incomplete menu.
            const compact = false;

            Widget menuTile(_DrawerDestination item) => Expanded(
              flex: 3,
              child: _DrawerTile(
                icon: item.icon,
                title: item.title,
                selected: location == item.path,
                compact: compact,
                onTap: () => _navigate(context, item.path),
              ),
            );

            Widget directTile({
              required IconData icon,
              required String title,
              required VoidCallback onTap,
              bool selected = false,
              bool danger = false,
              bool showChevron = true,
            }) => Expanded(
              flex: 3,
              child: _DrawerTile(
                icon: icon,
                title: title,
                selected: selected,
                danger: danger,
                showChevron: showChevron,
                compact: compact,
                onTap: onTap,
              ),
            );

            return Column(
              children: [
                _DrawerHeader(
                  initial: initial,
                  name: fullName,
                  phone: user?.phone ?? '',
                  roleLabel: l10n.roleLabel(role),
                  onlineLabel: l10n.accountActive,
                  compact: compact,
                  showBadges: true,
                  onProfileTap: () => _navigate(context, '$_basePath/profile'),
                ),
                Expanded(
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Column(
                        children: [
                          if (!compact)
                            _DrawerSectionLabel(l10n.drawerOperations),
                          ...mainNavigationItems.map(menuTile),
                          const Spacer(),
                          if (!compact)
                            _DrawerSectionLabel(l10n.homeQuickActions),
                          menuTile(quickAction),
                          const Spacer(),
                          if (!compact) _DrawerSectionLabel(l10n.drawerAccount),
                          directTile(
                            icon: Icons.tune_rounded,
                            title: l10n.settings,
                            selected: location == '$_basePath/settings',
                            onTap: () =>
                                _navigate(context, '$_basePath/settings'),
                          ),
                          directTile(
                            icon: Icons.shield_rounded,
                            title: l10n.changePassword,
                            selected: location == '$_basePath/change-password',
                            onTap: () => _navigate(
                              context,
                              '$_basePath/change-password',
                            ),
                          ),
                          const Spacer(),
                          if (!compact)
                            _DrawerSectionLabel(l10n.drawerAssistance),
                          directTile(
                            icon: Icons.menu_book_rounded,
                            title: l10n.help,
                            selected: location == '$_basePath/help',
                            onTap: () => _navigate(context, '$_basePath/help'),
                          ),
                          directTile(
                            icon: Icons.support_agent_rounded,
                            title: l10n.support,
                            selected: location == '$_basePath/support',
                            onTap: () =>
                                _navigate(context, '$_basePath/support'),
                          ),
                          directTile(
                            icon: Icons.info_rounded,
                            title: l10n.aboutUs,
                            selected: location == '$_basePath/about',
                            onTap: () => _navigate(context, '$_basePath/about'),
                          ),
                          const Spacer(),
                          directTile(
                            icon: Icons.logout_rounded,
                            title: l10n.logout,
                            danger: true,
                            showChevron: false,
                            onTap: () => confirmLogout(context),
                          ),
                          if (!compact) ...[
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.local_shipping_rounded,
                                    size: 16,
                                    color: AppTheme.primaryLight,
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    '${l10n.appName} • ${l10n.versionLabel('1.0.0')}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: palette.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.initial,
    required this.name,
    required this.phone,
    required this.roleLabel,
    required this.onlineLabel,
    required this.compact,
    required this.showBadges,
    required this.onProfileTap,
  });

  final String initial;
  final String name;
  final String phone;
  final String roleLabel;
  final String onlineLabel;
  final bool compact;
  final bool showBadges;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onProfileTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          compact ? 14 : 20,
          MediaQuery.paddingOf(context).top + (compact ? 8 : 14),
          compact ? 14 : 20,
          compact ? 8 : 16,
        ),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: const BorderRadiusDirectional.only(
            bottomEnd: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              end: -28,
              bottom: -44,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: compact ? 44 : 62,
                      height: compact ? 44 : 62,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.38),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 18 : 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(width: compact ? 10 : 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compact ? 14 : 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            phone,
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: compact ? 10 : 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white70,
                    ),
                  ],
                ),
                if (showBadges) ...[
                  SizedBox(height: compact ? 8 : 14),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Row(
                      children: [
                        _HeaderBadge(
                          icon: Icons.badge_outlined,
                          label: roleLabel,
                          compact: compact,
                        ),
                        const SizedBox(width: 8),
                        _HeaderBadge(
                          icon: Icons.verified_rounded,
                          label: onlineLabel,
                          compact: compact,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({
    required this.icon,
    required this.label,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 7 : 10,
      vertical: compact ? 4 : 6,
    ),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: compact ? 12 : 14, color: Colors.white),
        SizedBox(width: compact ? 3 : 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 9 : 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _DrawerSectionLabel extends StatelessWidget {
  const _DrawerSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.start,
            style: TextStyle(
              color: context.palette.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    ),
  );
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
    this.danger = false,
    this.showChevron = true,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool selected;
  final bool danger;
  final bool showChevron;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = danger
        ? AppTheme.error
        : selected
        ? Theme.of(context).colorScheme.primary
        : palette.textSecondary;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 54),
        child: Material(
          color: selected ? color.withValues(alpha: 0.11) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Row(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      width: compact ? 28 : 34,
                      height: compact ? 28 : 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: selected ? 0.14 : 0.08),
                        borderRadius: BorderRadius.circular(compact ? 9 : 11),
                      ),
                      child: Icon(icon, color: color, size: compact ? 17 : 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 11.5 : 14,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: danger || selected ? color : palette.textPrimary,
                      ),
                    ),
                  ),
                  if (showChevron)
                    Icon(
                      Icons.chevron_right_rounded,
                      size: compact ? 15 : 18,
                      color: color,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerDestination {
  const _DrawerDestination(this.icon, this.title, this.path);

  final IconData icon;
  final String title;
  final String path;
}
