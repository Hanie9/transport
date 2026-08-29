import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/iranian_plate_widget.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/modern_app_bar.dart';
import '../../l10n/app_localizations.dart';
import '../../models/driver_profile.dart';
import '../../services/cargo_service.dart';

class ActiveDriversScreen extends StatefulWidget {
  const ActiveDriversScreen({super.key});

  @override
  State<ActiveDriversScreen> createState() => _ActiveDriversScreenState();
}

class _ActiveDriversScreenState extends State<ActiveDriversScreen> {
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
    final drivers = await _cargoService.getActiveDrivers();
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
      appBar: ModernAppBar(title: l10n.activeDrivers),
      body: AppRefreshIndicator(
        onRefresh: () => _loadDrivers(),
        slivers: [
          SliverToBoxAdapter(
            child: FadeSlideIn(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: GradientHeaderCard(
                  title: l10n.activeDrivers,
                  subtitle: l10n.homeStatActiveDrivers,
                  icon: Icons.people_rounded,
                ),
              ),
            ),
          ),
          if (_loading)
            SliverFillRemaining(child: LoadingOverlay(message: l10n.loadingDrivers))
          else if (_drivers.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.people_outline,
                useIllustration: true,
                title: l10n.noActiveDrivers,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: StaggeredItem(
                      index: index,
                      child: _DriverCard(driver: _drivers[index]),
                    ),
                  ),
                  childCount: _drivers.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.driver});

  final DriverProfile driver;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                child: Text(
                  driver.fullName.substring(0, 1),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
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
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                    ),
                    Text(
                      driver.phone,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  l10n.active,
                  style: const TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(icon: Icons.local_shipping, label: driver.cargoType),
              if (driver.rating != null) _InfoChip(icon: Icons.star, label: '${driver.rating}'),
              if (driver.completedTrips != null)
                _InfoChip(icon: Icons.check_circle_outline, label: l10n.tripsCount(driver.completedTrips!)),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: IranianPlateDisplay(plateNumber: driver.plateNumber, height: 40, compact: true),
          ),
          if (driver.currentLocation != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    driver.currentLocation!,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
