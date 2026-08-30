import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/modern_app_bar.dart';
import '../../models/cargo.dart';
import '../../services/auth_service.dart';
import '../../services/cargo_service.dart';

class DriverMissionsScreen extends StatefulWidget {
  const DriverMissionsScreen({super.key});

  @override
  State<DriverMissionsScreen> createState() => _DriverMissionsScreenState();
}

class _DriverMissionsScreenState extends State<DriverMissionsScreen> {
  final _cargoService = CargoService();
  List<Cargo> _missions = [];
  bool _loading = true;
  String _filter = 'active';

  @override
  void initState() {
    super.initState();
    _cargoService.addListener(_loadMissions);
    _loadMissions(showLoader: true);
  }

  @override
  void dispose() {
    _cargoService.removeListener(_loadMissions);
    super.dispose();
  }

  Future<void> _loadMissions({bool showLoader = false}) async {
    if (showLoader) setState(() => _loading = true);

    final user = context.read<AuthService>().currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final missions = await _cargoService.getDriverMissions(
      driverPhone: user.phone,
      driverName: user.fullName,
    );

    if (mounted) {
      setState(() {
        _missions = missions;
        _loading = false;
      });
    }
  }

  List<Cargo> get _filteredMissions {
    if (_filter == 'all') return _missions;
    if (_filter == 'active') {
      return _missions
          .where((m) => m.status == 'تخصیص یافته')
          .toList();
    }
    return _missions.where((m) => m.status == 'تحویل شده').toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final activeCount = _missions
        .where((m) => m.status == 'تخصیص یافته')
        .length;
    final filters = {
      'active': l10n.filterActive,
      'completed': l10n.filterCompleted,
      'all': l10n.filterAll,
    };

    return Scaffold(
      appBar: ModernAppBar(title: l10n.myMissions),
      body: AppRefreshIndicator(
        onRefresh: () => _loadMissions(),
        slivers: [
          SliverToBoxAdapter(
            child: FadeSlideIn(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: GradientHeaderCard(
                  title: l10n.activeMissionsCount(activeCount),
                  subtitle: l10n.missionsSubtitle,
                  icon: Icons.assignment_outlined,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: InfoBanner(
                  message: l10n.missionsSyncNote,
                  icon: Icons.info_outline,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: filters.entries.map((entry) {
                  final selected = _filter == entry.key;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8),
                    child: FilterChip(
                      label: Text(entry.value),
                      selected: selected,
                      onSelected: (_) => setState(() => _filter = entry.key),
                      selectedColor: AppTheme.primary.withValues(alpha: 0.12),
                      checkmarkColor: AppTheme.primary,
                      labelStyle: TextStyle(
                        color: selected ? AppTheme.primary : palette.textSecondary,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          if (_loading)
            SliverFillRemaining(
              hasScrollBody: false,
              child: SizedBox.expand(child: LoadingOverlay(message: l10n.loadingMissions)),
            )
          else if (_filteredMissions.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.assignment_outlined,
                useIllustration: true,
                title: _filter == 'active' ? l10n.noActiveMission : l10n.noMissionFound,
                subtitle: _filter == 'active' ? l10n.acceptCargoHint : null,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final mission = _filteredMissions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: StaggeredItem(
                        index: index,
                        child: _MissionCard(
                        mission: mission,
                        onTap: () => context.push('/driver/cargo/${mission.id}'),
                        onRoute: () => context.push('/driver/route/${mission.id}'),
                        ),
                      ),
                    );
                  },
                  childCount: _filteredMissions.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.mission,
    required this.onTap,
    required this.onRoute,
  });

  final Cargo mission;
  final VoidCallback onTap;
  final VoidCallback onRoute;

  bool get _isActive =>
      mission.status == 'تخصیص یافته';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mission.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              StatusChip(status: mission.status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.trip_origin, size: 15, color: AppTheme.success),
              const SizedBox(width: 6),
              Expanded(
                child: Text(mission.origin, style: TextStyle(fontSize: 13, color: palette.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, size: 15, color: AppTheme.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(mission.destination, style: TextStyle(fontSize: 13, color: palette.textSecondary)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: palette.divider),
          ),
          Row(
            children: [
              PriceLabel(price: mission.estimatedPrice, fontSize: 13),
              const Spacer(),
              if (_isActive)
                TextButton.icon(
                  onPressed: onRoute,
                  icon: const Icon(Icons.navigation_outlined, size: 18),
                  label: Text(l10n.navigation),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
