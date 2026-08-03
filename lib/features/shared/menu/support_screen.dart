import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import 'widgets/menu_page_layout.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return MenuPageLayout(
      title: l10n.support,
      subtitle: l10n.supportSubtitle,
      icon: Icons.support_agent_rounded,
      child: Column(
        children: [
          MenuSectionCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.headset_mic_outlined, color: AppTheme.success, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l10n.supportSubtitle,
                    style: TextStyle(
                      color: context.palette.textSecondary,
                      height: 1.5,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          MenuContactTile(
            icon: Icons.phone_in_talk_outlined,
            label: l10n.supportPhone,
            value: '021-12345678',
            iconColor: AppTheme.primary,
          ),
          const SizedBox(height: 12),
          MenuContactTile(
            icon: Icons.mail_outline_rounded,
            label: l10n.email,
            value: 'support@logistics.ir',
            iconColor: AppTheme.accent,
          ),
          const SizedBox(height: 12),
          MenuContactTile(
            icon: Icons.schedule_rounded,
            label: l10n.supportHours,
            value: l10n.supportHoursValue,
            iconColor: AppTheme.success,
          ),
        ],
      ),
    );
  }
}
