import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import 'app_drawer.dart';
import 'shell_scope.dart';

class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ModernAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
  });

  final String title;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shell = ShellScope.maybeOf(context);
    final location = GoRouterState.of(context).uri.toString();
    final isMenuPage = AppDrawer.isMenuRoute(location);

    final Widget? effectiveLeading =
        leading ??
        (isMenuPage
            ? BackButton(onPressed: () => context.pop())
            : shell != null
            ? _ModernMenuButton(onPressed: shell.openDrawer)
            : null);

    return AppBar(
      title: Text(title),
      leading: effectiveLeading,
      automaticallyImplyLeading: effectiveLeading != null,
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: palette.divider),
      ),
    );
  }
}

class _ModernMenuButton extends StatelessWidget {
  const _ModernMenuButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Tooltip(
        message: MaterialLocalizations.of(context).openAppDrawerTooltip,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.14),
                  color.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: color.withValues(alpha: 0.12)),
            ),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(13),
              child: Center(
                child: SizedBox(
                  width: 21,
                  height: 17,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MenuLine(width: 21, color: color),
                      _MenuLine(width: 14, color: color),
                      _MenuLine(width: 18, color: color),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuLine extends StatelessWidget {
  const _MenuLine({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 2.5,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(4),
    ),
  );
}

class GradientHeaderCard extends StatelessWidget {
  const GradientHeaderCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.waving_hand_rounded,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
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
