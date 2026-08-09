import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/shell_scope.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/modern_app_bar.dart';
import '../../models/cargo.dart';
import '../../services/auth_service.dart';
import '../../services/cargo_service.dart';
import '../../services/location_service.dart';

class DriverShell extends StatefulWidget {
  const DriverShell({super.key, required this.child});

  final Widget child;

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  int _indexFromLocation(String location) {
    if (location.startsWith('/driver/cargos') || location.startsWith('/driver/nearby')) {
      return 1;
    }
    if (location.startsWith('/driver/missions')) return 2;
    if (location.startsWith('/driver/profile') || location.startsWith('/driver/vehicle')) {
      return 3;
    }
    return 0;
  }

  void _onTap(int index) {
    switch (index) {
      case 0:
        context.go('/driver');
      case 1:
        context.go('/driver/cargos');
      case 2:
        context.go('/driver/missions');
      case 3:
        context.go('/driver/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexFromLocation(location);
    final hideBottomNav = AppDrawer.hidesBottomNav(location, 'driver');

    return ShellScope(
      openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const AppDrawer(role: 'driver'),
        body: widget.child,
        bottomNavigationBar: hideBottomNav
            ? null
            : ModernBottomNav(
          currentIndex: index,
          onTap: _onTap,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: l10n.home,
            ),
            NavigationDestination(
              icon: const Icon(Icons.inventory_2_outlined),
              selectedIcon: const Icon(Icons.inventory_2),
              label: l10n.cargos,
            ),
            NavigationDestination(
              icon: const Icon(Icons.assignment_outlined),
              selectedIcon: const Icon(Icons.assignment),
              label: l10n.missions,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: l10n.profile,
            ),
          ],
        ),
      ),
    );
  }
}

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with WidgetsBindingObserver {
  final _cargoService = CargoService();
  final _location = LocationService();
  List<Cargo> _allCargos = [];
  List<Cargo> _nearbyCargos = [];
  bool _loading = true;
  bool _gpsEnabled = false;
  bool _gpsBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargoService.addListener(_onCargosChanged);
    _syncGpsAndLoad(showLoader: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cargoService.removeListener(_onCargosChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // After returning from system location settings, mirror real GPS state.
      _syncGpsAndLoad();
    }
  }

  void _onCargosChanged() => _syncGpsAndLoad();

  /// Mirror the device GPS/permission state onto the cargos-page toggle.
  Future<void> _syncGpsAndLoad({bool showLoader = false}) async {
    final ready = await _location.isGpsReady();
    if (!mounted) return;
    setState(() => _gpsEnabled = ready);
    await _loadCargos(showLoader: showLoader);
  }

  Future<void> _onGpsChanged(bool enabled) async {
    if (_gpsBusy) return;
    setState(() => _gpsBusy = true);

    try {
      if (!enabled) {
        await _location.disableGps(openSettings: true);
        if (!mounted) return;
        // Re-check real device state after settings (user may leave GPS on).
        final stillReady = await _location.isGpsReady();
        if (!mounted) return;
        setState(() {
          _gpsEnabled = stillReady;
          if (!stillReady) _nearbyCargos = [];
          _gpsBusy = false;
        });
        if (!stillReady) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.gpsDisabledSystemHint)),
          );
        } else {
          await _loadCargos();
        }
        return;
      }

      // Request permission + open system location settings if GPS is off.
      final pos = await _location.enableGps();
      if (!mounted) return;

      final ready = pos != null && await _location.isGpsReady();
      if (!mounted) return;

      if (!ready) {
        setState(() {
          _gpsEnabled = false;
          _nearbyCargos = [];
          _gpsBusy = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.gpsEnableFailed)),
        );
        return;
      }

      setState(() => _gpsEnabled = true);
      await _loadCargos();
    } finally {
      if (mounted) setState(() => _gpsBusy = false);
    }
  }

  Future<void> _loadCargos({bool showLoader = false}) async {
    if (showLoader) setState(() => _loading = true);

    final user = context.read<AuthService>().currentUser;
    final cargoType = user?.vehicleInfo?.cargoType ?? 'کفی';

    final allCargos = await _cargoService.getCargosForDriver(cargoType);

    // Always align toggle with real device GPS before deciding nearby list.
    final gpsOn = await _location.isGpsReady();
    var nearbyCargos = <Cargo>[];

    if (gpsOn) {
      final pos = await _location.getCurrentPosition(requestIfNeeded: false);
      if (pos != null) {
        nearbyCargos = await _cargoService.getNearbyCargos(
          cargoType: cargoType,
          driverPosition: pos,
        );
        await _cargoService.reportDriverLocation(
          lat: pos.latitude,
          lng: pos.longitude,
        );
      }
    }

    if (!mounted) return;

    setState(() {
      _allCargos = allCargos;
      _nearbyCargos = nearbyCargos;
      _gpsEnabled = gpsOn;
      _loading = false;
    });
  }

  List<Cargo> get _otherCargos {
    if (_nearbyCargos.isEmpty) return _allCargos;
    final nearbyIds = _nearbyCargos.map((c) => c.id).toSet();
    return _allCargos.where((c) => !nearbyIds.contains(c.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.watch<AuthService>().currentUser;
    final otherCargos = _otherCargos;
    final isEmpty = _nearbyCargos.isEmpty && _allCargos.isEmpty;
    final cargoType = user?.vehicleInfo?.cargoType;

    return Scaffold(
      appBar: ModernAppBar(title: l10n.cargos),
      body: AppRefreshIndicator(
        onRefresh: () => _loadCargos(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: GradientHeaderCard(
                title: l10n.hello(user?.fullName ?? l10n.roleLabel('driver')),
                subtitle: l10n.cargoTypeLabel(
                  cargoType ?? l10n.notRegistered,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _GpsBanner(
              enabled: _gpsEnabled,
              busy: _gpsBusy,
              onChanged: _onGpsChanged,
            ),
          ),
          if (_loading)
            SliverFillRemaining(
              hasScrollBody: false,
              child: SizedBox.expand(
                child: LoadingOverlay(message: l10n.loadingCargos),
              ),
            )
          else if (isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: SizedBox.expand(
                child: EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: l10n.noCargoFound,
                  subtitle: _gpsEnabled ? l10n.noMatchingCargo : l10n.enableGpsForNearby,
                ),
              ),
            )
          else ...[
            if (_gpsEnabled && _nearbyCargos.isNotEmpty) ...[
              SliverToBoxAdapter(child: SectionHeader(title: l10n.nearbyCargos)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final cargo = _nearbyCargos[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _NearbyCargoTile(
                          cargo: cargo,
                          onTap: () => context.push('/driver/cargo/${cargo.id}'),
                        ),
                      );
                    },
                    childCount: _nearbyCargos.length,
                  ),
                ),
              ),
            ],
            if (otherCargos.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: _nearbyCargos.isNotEmpty ? l10n.otherMatchingCargos : l10n.allMatchingCargos,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final cargo = otherCargos[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CargoListTile(
                          cargo: cargo,
                          onTap: () => context.push('/driver/cargo/${cargo.id}'),
                        ),
                      );
                    },
                    childCount: otherCargos.length,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _GpsBanner extends StatelessWidget {
  const _GpsBanner({
    required this.enabled,
    required this.onChanged,
    this.busy = false,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final color = enabled ? AppTheme.success : AppTheme.warning;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: busy
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                : Icon(
                    enabled ? Icons.gps_fixed : Icons.gps_off,
                    color: color,
                    size: 20,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enabled ? l10n.gpsEnabled : l10n.gpsDisabled,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                Text(
                  enabled ? l10n.gpsEnabledHint : l10n.gpsDisabledHint,
                  style: TextStyle(fontSize: 12, color: palette.textSecondary),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            activeThumbColor: AppTheme.success,
            onChanged: busy ? null : onChanged,
          ),
        ],
      ),
    );
  }
}

class _NearbyCargoTile extends StatelessWidget {
  const _NearbyCargoTile({required this.cargo, required this.onTap});

  final Cargo cargo;
  final VoidCallback onTap;

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
                      l10n.kmDistance(cargo.nearbyDistanceKm ?? 0),
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
              StatusChip(status: cargo.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            cargo.title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _RouteLine(icon: Icons.trip_origin, color: AppTheme.success, text: cargo.origin),
          const SizedBox(height: 4),
          _RouteLine(icon: Icons.location_on, color: AppTheme.error, text: cargo.destination),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: palette.divider),
          ),
          Row(
            children: [
              _TagChip(label: cargo.cargoType, color: AppTheme.primary),
              const Spacer(),
              PriceLabel(price: cargo.estimatedPrice, fontSize: 14),
            ],
          ),
        ],
      ),
    );
  }
}

class _CargoListTile extends StatelessWidget {
  const _CargoListTile({required this.cargo, required this.onTap});

  final Cargo cargo;
  final VoidCallback onTap;

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
                  cargo.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: palette.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              StatusChip(status: cargo.status),
            ],
          ),
          const SizedBox(height: 14),
          _RouteLine(icon: Icons.trip_origin, color: AppTheme.success, text: cargo.origin),
          const SizedBox(height: 6),
          _RouteLine(icon: Icons.location_on, color: AppTheme.error, text: cargo.destination),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: palette.divider),
          ),
          Row(
            children: [
              _TagChip(label: cargo.cargoType, color: AppTheme.primary),
              const SizedBox(width: 8),
              _TagChip(label: l10n.tons(cargo.weightTons), color: palette.textSecondary),
              const Spacer(),
              PriceLabel(price: cargo.estimatedPrice, fontSize: 14),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 13, color: palette.textSecondary)),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
