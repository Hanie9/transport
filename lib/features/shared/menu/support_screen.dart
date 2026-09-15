import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.headset_mic_outlined,
                        color: AppTheme.success,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.supportTitle,
                            style: TextStyle(
                              color: context.palette.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.supportQuickHelp,
                            style: TextStyle(
                              color: context.palette.textSecondary,
                              height: 1.5,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    l10n.supportBeforeContact,
                    style: TextStyle(
                      color: context.palette.textSecondary,
                      fontSize: 12,
                      height: 1.5,
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
            onTap: () => _copy(context, '021-12345678'),
          ),
          const SizedBox(height: 12),
          MenuContactTile(
            icon: Icons.mail_outline_rounded,
            label: l10n.email,
            value: 'support@logistics.ir',
            iconColor: AppTheme.accent,
            onTap: () => _copy(context, 'support@logistics.ir'),
          ),
          const SizedBox(height: 12),
          MenuContactTile(
            icon: Icons.schedule_rounded,
            label: l10n.supportHours,
            value: l10n.supportHoursValue,
            iconColor: AppTheme.success,
          ),
          const SizedBox(height: 20),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l10n.commonQuestions,
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _FaqTile(
            icon: Icons.inventory_2_outlined,
            title: l10n.faqCargoIssueTitle,
            body: l10n.faqCargoIssueBody,
          ),
          const SizedBox(height: 10),
          _FaqTile(
            icon: Icons.lock_clock_outlined,
            title: l10n.faqAccountIssueTitle,
            body: l10n.faqAccountIssueBody,
          ),
          const SizedBox(height: 10),
          _FaqTile(
            icon: Icons.gps_off_rounded,
            title: l10n.faqNavigationIssueTitle,
            body: l10n.faqNavigationIssueBody,
          ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.copiedToClipboard)));
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.cardBg,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        children: [
          Text(
            body,
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
