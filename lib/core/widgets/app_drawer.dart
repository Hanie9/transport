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
    return _menuSegments.any((segment) => location.startsWith('$basePath/$segment'));
  }

  static bool isMenuRoute(String location) {
    return hidesBottomNav(location, 'driver') || hidesBottomNav(location, 'coordinator');
  }

  String get _basePath => role == 'driver' ? '/driver' : '/coordinator';

  void _navigate(BuildContext context, String path) {
    Navigator.of(context).pop();
    context.push(path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final user = context.watch<AuthService>().currentUser;

    return Drawer(
      backgroundColor: palette.surface,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.paddingOf(context).top + 24,
                20,
                20,
              ),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      user?.fullName.substring(0, 1) ?? '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.fullName ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.roleLabel(role),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerTile(
                    icon: Icons.settings_outlined,
                    title: l10n.settings,
                    onTap: () => _navigate(context, '$_basePath/settings'),
                  ),
                  _DrawerTile(
                    icon: Icons.lock_outline,
                    title: l10n.changePassword,
                    onTap: () => _navigate(context, '$_basePath/change-password'),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _DrawerTile(
                    icon: Icons.help_outline,
                    title: l10n.help,
                    onTap: () => _navigate(context, '$_basePath/help'),
                  ),
                  _DrawerTile(
                    icon: Icons.support_agent_outlined,
                    title: l10n.support,
                    onTap: () => _navigate(context, '$_basePath/support'),
                  ),
                  _DrawerTile(
                    icon: Icons.info_outline,
                    title: l10n.aboutUs,
                    onTap: () => _navigate(context, '$_basePath/about'),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _DrawerTile(
                    icon: Icons.logout_rounded,
                    title: l10n.logout,
                    iconColor: AppTheme.error,
                    titleColor: AppTheme.error,
                    onTap: () => confirmLogout(context),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.appName,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: palette.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppTheme.primaryLight),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: titleColor ?? palette.textPrimary,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}
