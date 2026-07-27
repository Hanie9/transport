import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/modern_app_bar.dart';
import '../../l10n/app_localizations.dart';
import '../../models/driver_profile.dart';
import '../../services/cargo_service.dart';

class NearbyDriversScreen extends StatefulWidget {
  const NearbyDriversScreen({super.key});

  @override
  State<NearbyDriversScreen> createState() => _NearbyDriversScreenState();
}

class _NearbyDriversScreenState extends State<NearbyDriversScreen> {
  final _cargoService = CargoService();
  List<DriverProfile> _drivers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDrivers(showLoader: true);
  }

  Future<void> _loadDrivers({bool showLoader = false}) async {
    if (showLoader) setState(() => _loading = true);
    final drivers = await _cargoService.getNearbyDrivers();
    if (mounted) {
      setState(() {
        _drivers = drivers;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: ModernAppBar(title: l10n.nearbyDrivers),
      body: AppRefreshIndicator(
        onRefresh: () => _loadDrivers(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.nearbyDriversHint,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            SliverFillRemaining(child: LoadingOverlay(message: l10n.searchingNearbyDrivers))
          else if (_drivers.isEmpty)
            SliverFillRemaining(
              child: EmptyState(icon: Icons.person_search, title: l10n.noNearbyDrivers),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final driver = _drivers[index];
                    final l10n = context.l10n;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.near_me, size: 14, color: AppTheme.accent),
                                      const SizedBox(width: 4),
                                      Text(
                                        l10n.kmDistance(driver.distanceKm ?? 0),
                                        style: const TextStyle(
                                          color: AppTheme.accent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.star, size: 16, color: AppTheme.warning),
                                Text(
                                  ' ${driver.rating}',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                                  child: Text(
                                    driver.fullName.substring(0, 1),
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        driver.fullName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        driver.phone,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary,
                                        ),
                                        textDirection: TextDirection.ltr,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    driver.cargoType,
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (driver.currentLocation != null)
                                  Expanded(
                                    child: Text(
                                      driver.currentLocation!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _drivers.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
