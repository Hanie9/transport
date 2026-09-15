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
      width: 328,
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
        child: Column(
          children: [
            _DrawerHeader(
              initial: initial,
              name: fullName,
              phone: user?.phone ?? '',
              roleLabel: l10n.roleLabel(role),
              onlineLabel: l10n.accountActive,
              onProfileTap: () => _navigate(context, '$_basePath/profile'),
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 20),
                children: [
                  _DrawerSectionLabel(l10n.drawerOperations),
                  ...mainNavigationItems.map(
                    (item) => _DrawerTile(
                      icon: item.icon,
                      title: item.title,
                      selected: location == item.path,
                      onTap: () => _navigate(context, item.path),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DrawerSectionLabel(l10n.homeQuickActions),
                  _DrawerTile(
                    icon: quickAction.icon,
                    title: quickAction.title,
                    selected: location == quickAction.path,
                    onTap: () => _navigate(context, quickAction.path),
                  ),
                  const SizedBox(height: 12),
                  _DrawerSectionLabel(l10n.drawerAccount),
                  _DrawerTile(
                    icon: Icons.tune_rounded,
                    title: l10n.settings,
                    selected: location == '$_basePath/settings',
                    onTap: () => _navigate(context, '$_basePath/settings'),
                  ),
                  _DrawerTile(
                    icon: Icons.shield_rounded,
                    title: l10n.changePassword,
                    selected: location == '$_basePath/change-password',
                    onTap: () =>
                        _navigate(context, '$_basePath/change-password'),
                  ),
                  const SizedBox(height: 12),
                  _DrawerSectionLabel(l10n.drawerAssistance),
                  _DrawerTile(
                    icon: Icons.menu_book_rounded,
                    title: l10n.help,
                    selected: location == '$_basePath/help',
                    onTap: () => _navigate(context, '$_basePath/help'),
                  ),
                  _DrawerTile(
                    icon: Icons.support_agent_rounded,
                    title: l10n.support,
                    selected: location == '$_basePath/support',
                    onTap: () => _navigate(context, '$_basePath/support'),
                  ),
                  _DrawerTile(
                    icon: Icons.info_rounded,
                    title: l10n.aboutUs,
                    selected: location == '$_basePath/about',
                    onTap: () => _navigate(context, '$_basePath/about'),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DrawerTile(
                      icon: Icons.logout_rounded,
                      title: l10n.logout,
                      danger: true,
                      showChevron: false,
                      onTap: () => confirmLogout(context),
                    ),
                    const SizedBox(height: 10),
                    Row(
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
                  ],
                ),
              ),
            ),
          ],
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
    required this.onProfileTap,
    required this.onClose,
  });

  final String initial;
  final String name;
  final String phone;
  final String roleLabel;
  final String onlineLabel;
  final VoidCallback onProfileTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onProfileTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.paddingOf(context).top + 12,
          20,
          22,
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
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            phone,
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 12,
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
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeaderBadge(icon: Icons.badge_outlined, label: roleLabel),
                    _HeaderBadge(
                      icon: Icons.verified_rounded,
                      label: onlineLabel,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 12, 8),
    child: Text(
      label,
      style: TextStyle(
        color: context.palette.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
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
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool selected;
  final bool danger;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = danger
        ? AppTheme.error
        : selected
        ? Theme.of(context).colorScheme.primary
        : palette.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? color.withValues(alpha: 0.11) : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: ListTile(
          minTileHeight: 50,
          leading: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: selected ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: danger || selected ? color : palette.textPrimary,
            ),
          ),
          trailing: showChevron
              ? Icon(Icons.chevron_right_rounded, size: 18, color: color)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          onTap: onTap,
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
