import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_illustrations.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/modern_app_bar.dart';
import '../../core/widgets/scale_tap.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cargo.dart';
import '../../services/auth_service.dart';
import '../../services/cargo_service.dart';
import '../../services/location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.role});

  final String role;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _cargoService = CargoService();
  bool _loading = true;

  static const _suggestedLimit = 3;

  int _stat1 = 0;
  int _stat2 = 0;
  int _stat3 = 0;
  List<Cargo> _recent = [];
  bool _hasMoreSuggested = false;

  bool get _isDriver => widget.role == 'driver';

  @override
  void initState() {
    super.initState();
    _cargoService.addListener(_load);
    _load(showLoader: true);
  }

  @override
  void dispose() {
    _cargoService.removeListener(_load);
    super.dispose();
  }

  Future<void> _load({bool showLoader = false}) async {
    if (showLoader && mounted) setState(() => _loading = true);

    final user = context.read<AuthService>().currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (_isDriver) {
      final cargoType = user.vehicleInfo?.cargoType ?? 'کفی';
      final nearby = await _cargoService.getNearbyCargos(cargoType: cargoType);
      final available = await _cargoService.getCargosForDriver(cargoType);
      final missions = await _cargoService.getDriverMissions(
        driverPhone: user.phone,
        driverName: user.fullName,
      );
      final active = missions.where((c) => c.status == 'تخصیص یافته').length;
      if (!mounted) return;
      final pos =
          LocationService().lastKnown ??
          await LocationService().getCurrentPosition(requestIfNeeded: false);
      setState(() {
        _stat1 = nearby.length;
        _stat2 = available.length;
        _stat3 = active;
        var suggested = _uniqueCargos([...nearby, ...available]);
        if (pos != null) {
          suggested = _cargoService.withDistanceFromDriver(suggested, pos);
        }
        _hasMoreSuggested = suggested.length > _suggestedLimit;
        _recent = suggested.take(_suggestedLimit).toList();
        _loading = false;
      });
    } else {
      final cargos = await _cargoService.getCoordinatorCargos();
      final allCargos = cargos.isNotEmpty
          ? cargos
          : await _cargoService.getAllCargos();
      final pending = allCargos
          .where((c) => c.status == 'در انتظار راننده')
          .length;
      final assigned = allCargos.where((c) => c.status == 'تخصیص یافته').length;
      if (!mounted) return;
      setState(() {
        _stat1 = allCargos.length;
        _stat2 = pending;
        _stat3 = assigned;
        _pendingHint = pending;
        _inTransitHint = assigned;
        _hasMoreSuggested = allCargos.length > _suggestedLimit;
        _recent = allCargos.take(_suggestedLimit).toList();
        _loading = false;
      });
    }
  }

  int _pendingHint = 0;
  int _inTransitHint = 0;

  List<Cargo> _uniqueCargos(Iterable<Cargo> cargos) {
    final seen = <String>{};
    final result = <Cargo>[];
    for (final cargo in cargos) {
      if (cargo.id.isEmpty || !seen.add(cargo.id)) continue;
      result.add(cargo);
    }
    return result;
  }

  void _openAllCargos() {
    context.go(_isDriver ? '/driver/cargos' : '/coordinator/cargos');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final user = context.watch<AuthService>().currentUser;
    final name = user?.fullName ?? l10n.roleLabel(widget.role);

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: ModernAppBar(title: l10n.home),
      body: AppRefreshIndicator(
        onRefresh: () => _load(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: FadeSlideIn(
                child: _HomeHero(
                  greeting: l10n.hello(name),
                  subtitle: _isDriver
                      ? l10n.homeDriverSubtitle
                      : l10n.homeCoordinatorSubtitle,
                  roleLabel: l10n.roleLabel(widget.role),
                ),
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverToBoxAdapter(
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: _StatsRow(
                    items: _isDriver
                        ? [
                            _StatData(
                              label: l10n.homeStatNearby,
                              value: '$_stat1',
                              icon: Icons.near_me_rounded,
                              color: AppTheme.accent,
                            ),
                            _StatData(
                              label: l10n.homeStatAvailable,
                              value: '$_stat2',
                              icon: Icons.inventory_2_rounded,
                              color: AppTheme.primary,
                            ),
                            _StatData(
                              label: l10n.homeStatActiveMissions,
                              value: '$_stat3',
                              icon: Icons.local_shipping_rounded,
                              color: AppTheme.success,
                            ),
                          ]
                        : [
                            _StatData(
                              label: l10n.homeStatTotalCargos,
                              value: '$_stat1',
                              icon: Icons.list_alt_rounded,
                              color: AppTheme.primary,
                            ),
                            _StatData(
                              label: l10n.homeStatActiveDrivers,
                              value: '$_stat2',
                              icon: Icons.people_rounded,
                              color: AppTheme.accent,
                            ),
                            _StatData(
                              label: l10n.homeStatNearbyDrivers,
                              value: '$_stat3',
                              icon: Icons.near_me_rounded,
                              color: AppTheme.success,
                            ),
                          ],
                  ),
                ),
              ),
            ),
            if (!_isDriver)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: FadeSlideIn(
                    delay: const Duration(milliseconds: 140),
                    child: Row(
                      children: [
                        Expanded(
                          child: _MiniHintCard(
                            icon: Icons.hourglass_top_rounded,
                            label: l10n.homePendingCargos,
                            value: '$_pendingHint',
                            color: AppTheme.warning,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniHintCard(
                            icon: Icons.route_rounded,
                            label: l10n.homeInTransit,
                            value: '$_inTransitHint',
                            color: AppTheme.primaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: FadeSlideIn(
                delay: const Duration(milliseconds: 180),
                child: SectionHeader(title: l10n.homeQuickActions),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 220),
                  child: _QuickActionsGrid(
                    actions: _isDriver
                        ? [
                            _QuickAction(
                              icon: Icons.inventory_2_outlined,
                              label: l10n.cargos,
                              color: AppTheme.primary,
                              onTap: () => context.go('/driver/cargos'),
                            ),
                            _QuickAction(
                              icon: Icons.assignment_outlined,
                              label: l10n.missions,
                              color: AppTheme.accent,
                              onTap: () => context.go('/driver/missions'),
                            ),
                            _QuickAction(
                              icon: Icons.directions_car_outlined,
                              label: l10n.vehicleInfo,
                              color: AppTheme.success,
                              onTap: () =>
                                  context.go('/driver/profile?editVehicle=1'),
                            ),
                            _QuickAction(
                              icon: Icons.help_outline_rounded,
                              label: l10n.help,
                              color: AppTheme.primaryLight,
                              onTap: () => context.push('/driver/help'),
                            ),
                          ]
                        : [
                            _QuickAction(
                              icon: Icons.add_box_outlined,
                              label: l10n.addCargo,
                              color: AppTheme.accent,
                              onTap: () =>
                                  context.push('/coordinator/add-cargo'),
                            ),
                            _QuickAction(
                              icon: Icons.list_alt_outlined,
                              label: l10n.cargos,
                              color: AppTheme.primary,
                              onTap: () => context.go('/coordinator/cargos'),
                            ),
                            _QuickAction(
                              icon: Icons.person_outline,
                              label: l10n.profile,
                              color: AppTheme.success,
                              onTap: () => context.go('/coordinator/profile'),
                            ),
                            _QuickAction(
                              icon: Icons.help_outline_rounded,
                              label: l10n.help,
                              color: AppTheme.primaryLight,
                              onTap: () => context.push('/coordinator/help'),
                            ),
                          ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeSlideIn(
                delay: const Duration(milliseconds: 260),
                child: SectionHeader(
                  title: _isDriver
                      ? l10n.homeSuggestedCargos
                      : l10n.homeRecentCargos,
                  actionLabel: _hasMoreSuggested ? l10n.homeViewAll : null,
                  action: _hasMoreSuggested ? _openAllCargos : null,
                ),
              ),
            ),
            if (_recent.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverToBoxAdapter(
                  child: FadeSlideIn(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 28,
                      ),
                      decoration: BoxDecoration(
                        color: palette.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: palette.divider.withValues(alpha: 0.65),
                        ),
                        boxShadow: palette.cardShadow,
                      ),
                      child: Column(
                        children: [
                          const EmptyCargoIllustration(),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noCargoFound,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                            ),
                          ),
                          if (_isDriver) ...[
                            const SizedBox(height: 6),
                            Text(
                              l10n.noMatchingCargo,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: palette.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index >= _recent.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: FadeSlideIn(
                          delay: Duration(milliseconds: 80 * index),
                          child: OutlinedButton(
                            onPressed: _openAllCargos,
                            child: Text(l10n.homeViewAll),
                          ),
                        ),
                      );
                    }
                    final cargo = _recent[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FadeSlideIn(
                        delay: Duration(milliseconds: 80 * index),
                        child: _HomeCargoTile(
                          cargo: cargo,
                          showNearby: _isDriver,
                          onTap: () => context.push(
                            _isDriver
                                ? '/driver/cargo/${cargo.id}'
                                : '/coordinator/cargo/${cargo.id}',
                          ),
                        ),
                      ),
                    );
                  }, childCount: _recent.length + (_hasMoreSuggested ? 1 : 0)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.greeting,
    required this.subtitle,
    required this.roleLabel,
  });

  final String greeting;
  final String subtitle;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PositionedDirectional(
            end: -8,
            bottom: -6,
            child: Icon(
              Icons.local_shipping_rounded,
              size: 120,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          PositionedDirectional(
            end: 12,
            top: 0,
            child: LogisticsHeroArt(size: 96),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 108),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    roleLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  greeting,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13.5,
                    height: 1.45,
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

class _StatData {
  const _StatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.items});

  final List<_StatData> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _StatCard(data: items[i])),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: data.color.withValues(alpha: 0.14)),
        boxShadow: palette.cardShadow,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PositionedDirectional(
            top: -18,
            start: -10,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.color.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      data.color.withValues(alpha: 0.22),
                      data.color.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(data.icon, color: data.color, size: 20),
              ),
              const SizedBox(height: 14),
              Text(
                data.value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniHintCard extends StatelessWidget {
  const _MiniHintCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: palette.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: palette.textSecondary,
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

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.actions});

  final List<_QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.15,
      children: actions
          .map((action) => _QuickActionTile(action: action))
          .toList(),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ScaleTap(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Material(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: action.color.withValues(alpha: 0.1),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.divider.withValues(alpha: 0.7)),
              boxShadow: palette.cardShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          action.color.withValues(alpha: 0.2),
                          action.color.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(action.icon, color: action.color, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      action.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: palette.textSecondary.withValues(alpha: 0.7),
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

class _HomeCargoTile extends StatelessWidget {
  const _HomeCargoTile({
    required this.cargo,
    required this.onTap,
    this.showNearby = false,
  });

  final Cargo cargo;
  final VoidCallback onTap;
  final bool showNearby;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cargo.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              if (showNearby && cargo.isNearby)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: Text(
                    l10n.nearby,
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (showNearby && cargo.nearbyDistanceKm != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.kmDistance(cargo.nearbyDistanceKm!),
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              StatusChip(status: cargo.status, date: cargo.createdAt),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.trip_origin, size: 14, color: palette.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  cargo.origin,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: palette.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.flag_outlined, size: 14, color: palette.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  cargo.destination,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: palette.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
