import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/double_back_to_exit.dart';
import '../../core/widgets/shell_scope.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/location_access_dialog.dart';
import '../../core/widgets/modern_app_bar.dart';
import '../../core/widgets/modern_dropdown.dart';
import '../../models/cargo.dart';
import '../../models/driver_bar_query.dart';
import '../../services/reference_data_service.dart';
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
    if (location.startsWith('/driver/cargos') ||
        location.startsWith('/driver/nearby')) {
      return 1;
    }
    if (location.startsWith('/driver/missions')) return 2;
    if (location.startsWith('/driver/profile') ||
        location.startsWith('/driver/vehicle')) {
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

    return DoubleBackToExit(
      enabled: !hideBottomNav,
      child: ShellScope(
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
  DriverBarQuery? _barQuery;
  int _currentPage = 1;
  bool _hasMore = false;
  bool _loadingMore = false;

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

  /// Mirror nearby GPS preference and device state onto the cargos-page toggle.
  Future<void> _syncGpsAndLoad({bool showLoader = false}) async {
    await _location.initializeNearbyPreferenceFromDevice();
    final ready = await _location.isNearbyGpsActive();
    if (!mounted) return;
    setState(() => _gpsEnabled = ready);
    await _loadCargos(showLoader: showLoader);
  }

  Future<void> _onGpsChanged(bool enabled) async {
    if (_gpsBusy) return;
    setState(() => _gpsBusy = true);

    try {
      if (!enabled) {
        await _location.disableGps();
        if (!mounted) return;
        setState(() {
          _gpsEnabled = false;
          _nearbyCargos = [];
          _gpsBusy = false;
        });
        await _loadCargos();
        if (!mounted) return;
        await showNearbyGpsDisabledDialog(context);
        return;
      }

      final ready = await requestLocationAccessWithDialog(
        context,
        title: context.l10n.locationEnableTitle,
        message: context.l10n.locationEnableNearbyMessage,
      );
      if (!mounted) return;

      if (!ready) {
        _location.setNearbyGpsEnabled(false);
        setState(() {
          _gpsEnabled = false;
          _nearbyCargos = [];
          _gpsBusy = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.gpsEnableFailed)));
        return;
      }

      _location.setNearbyGpsEnabled(true);
      setState(() => _gpsEnabled = true);
      await _loadCargos();
    } finally {
      if (mounted) setState(() => _gpsBusy = false);
    }
  }

  Future<void> _loadCargos({
    bool showLoader = false,
    bool loadMore = false,
  }) async {
    if (loadMore) {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    } else if (showLoader) {
      setState(() => _loading = true);
    }

    final page = loadMore ? _currentPage + 1 : 1;

    final pageResult = await _cargoService.getDriverBarsPage(
      query: _barQuery,
      page: page,
    );

    // Respect the user's nearby-GPS preference, not only device GPS state.
    final gpsOn = await _location.isNearbyGpsActive();
    var items = pageResult.items;

    if (gpsOn) {
      var pos = _location.lastKnown;
      pos ??= await _location.getCurrentPosition(requestIfNeeded: false);
      pos ??= await _location.getCurrentPosition(requestIfNeeded: true);
      if (pos != null) {
        items = _cargoService.withDistanceFromDriver(items, pos);
      }
    }

    if (!mounted) return;

    setState(() {
      if (loadMore) {
        _allCargos = [..._allCargos, ...items];
        _loadingMore = false;
      } else {
        _allCargos = items;
        _loading = false;
      }
      _gpsEnabled = gpsOn;
      _nearbyCargos = gpsOn
          ? (_allCargos.where((cargo) => cargo.isNearby).toList()..sort(
              (a, b) =>
                  (a.nearbyDistanceKm ?? 0).compareTo(b.nearbyDistanceKm ?? 0),
            ))
          : [];
      _currentPage = pageResult.currentPage;
      _hasMore = pageResult.hasNext;
    });
  }

  Future<void> _showFilterSheet() async {
    final l10n = context.l10n;
    final reference = ReferenceDataService();
    final ostans = await reference.getOstans();

    if (!mounted) return;

    var ostanMabda = _barQuery?.ostanMabda;
    var ostanMaghsad = _barQuery?.ostanMaghsad;
    var priceMin = _barQuery?.priceMin;
    var priceMax = _barQuery?.priceMax;
    final minController = TextEditingController(
      text: priceMin?.toString() ?? '',
    );
    final maxController = TextEditingController(
      text: priceMax?.toString() ?? '',
    );

    final result = await showModalBottomSheet<DriverBarQuery?>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.filterCargos,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ModernDropdownField<int?>(
                    value: ostanMabda,
                    label: l10n.originOstan,
                    prefixIcon: Icons.trip_origin_rounded,
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(l10n.filterAll),
                      ),
                      ...ostans.map(
                        (o) => DropdownMenuItem<int?>(
                          value: o.id,
                          child: Text(o.name),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setModalState(() => ostanMabda = value),
                  ),
                  const SizedBox(height: 12),
                  ModernDropdownField<int?>(
                    value: ostanMaghsad,
                    label: l10n.destinationOstan,
                    prefixIcon: Icons.location_on_rounded,
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(l10n.filterAll),
                      ),
                      ...ostans.map(
                        (o) => DropdownMenuItem<int?>(
                          value: o.id,
                          child: Text(o.name),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setModalState(() => ostanMaghsad = value),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: l10n.minPrice),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: maxController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: l10n.maxPrice),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.pop(context, const DriverBarQuery()),
                          child: Text(l10n.clearFilters),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final min = int.tryParse(minController.text.trim());
                            final max = int.tryParse(maxController.text.trim());
                            Navigator.pop(
                              context,
                              DriverBarQuery(
                                ostanMabda: ostanMabda,
                                ostanMaghsad: ostanMaghsad,
                                priceMin: min,
                                priceMax: max,
                              ),
                            );
                          },
                          child: Text(l10n.applyFilters),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    minController.dispose();
    maxController.dispose();

    if (!mounted || result == null) return;

    setState(() {
      _barQuery = result.isEmpty ? null : result;
      _currentPage = 1;
    });
    await _loadCargos(showLoader: true);
  }

  List<Cargo> get _otherCargos {
    final others = _nearbyCargos.isEmpty
        ? List<Cargo>.from(_allCargos)
        : _allCargos
              .where((c) => !_nearbyCargos.any((nearby) => nearby.id == c.id))
              .toList();
    if (!_gpsEnabled) return others;
    others.sort(_byDistance);
    return others;
  }

  static int _byDistance(Cargo a, Cargo b) {
    final da = a.nearbyDistanceKm;
    final db = b.nearbyDistanceKm;
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return da.compareTo(db);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.watch<AuthService>().currentUser;
    final otherCargos = _otherCargos;
    final isEmpty = _nearbyCargos.isEmpty && _allCargos.isEmpty;
    final cargoType = user?.vehicleInfo?.cargoType;

    return Scaffold(
      appBar: ModernAppBar(
        title: l10n.cargos,
        actions: [
          IconButton(
            tooltip: l10n.filterCargos,
            onPressed: _showFilterSheet,
            icon: Badge(
              isLabelVisible: _barQuery != null && !_barQuery!.isEmpty,
              child: const Icon(Icons.filter_list_rounded),
            ),
          ),
        ],
      ),
      body: AppRefreshIndicator(
        onRefresh: () => _loadCargos(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: FadeSlideIn(
                child: GradientHeaderCard(
                  title: l10n.hello(user?.fullName ?? l10n.roleLabel('driver')),
                  subtitle: l10n.cargoTypeLabel(
                    cargoType ?? l10n.notRegistered,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: _GpsBanner(
                enabled: _gpsEnabled,
                busy: _gpsBusy,
                onChanged: _onGpsChanged,
              ),
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
                  useIllustration: true,
                  title: l10n.noCargoFound,
                  subtitle: _gpsEnabled
                      ? l10n.noMatchingCargo
                      : l10n.enableGpsForNearby,
                ),
              ),
            )
          else ...[
            if (_gpsEnabled && _nearbyCargos.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(title: l10n.nearbyCargos),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final cargo = _nearbyCargos[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CargoListTile(
                        cargo: cargo,
                        onTap: () => context.push('/driver/cargo/${cargo.id}'),
                      ),
                    );
                  }, childCount: _nearbyCargos.length),
                ),
              ),
            ],
            if (otherCargos.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: _nearbyCargos.isNotEmpty
                      ? l10n.otherMatchingCargos
                      : l10n.allMatchingCargos,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final cargo = otherCargos[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CargoListTile(
                        cargo: cargo,
                        onTap: () => context.push('/driver/cargo/${cargo.id}'),
                      ),
                    );
                  }, childCount: otherCargos.length),
                ),
              ),
            ],
            if (_hasMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: OutlinedButton(
                    onPressed: _loadingMore
                        ? null
                        : () => _loadCargos(loadMore: true),
                    child: _loadingMore
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.loadMore),
                  ),
                ),
              ),
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
          SwitchTheme(
            data: SwitchTheme.of(context).copyWith(
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return Colors.white.withValues(alpha: 0.6);
                }
                return Colors.white;
              }),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppTheme.success;
                }
                if (states.contains(WidgetState.disabled)) {
                  return palette.divider.withValues(alpha: 0.5);
                }
                return Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF334155)
                    : const Color(0xFFCBD5E1);
              }),
              trackOutlineColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppTheme.success.withValues(alpha: 0.35);
                }
                return Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8);
              }),
            ),
            child: Switch.adaptive(
              value: enabled,
              onChanged: busy ? null : onChanged,
            ),
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
    final showNearby = cargo.isNearby;
    final distanceKm = cargo.nearbyDistanceKm;
    final showDistance = distanceKm != null;
    final showGpsMeta = showNearby || showDistance;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showGpsMeta)
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (showNearby)
                        _TagChip(label: l10n.nearby, color: AppTheme.accent),
                      if (distanceKm != null) _DistanceChip(km: distanceKm),
                    ],
                  ),
                )
              else
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
              StatusChip(status: cargo.status, date: cargo.createdAt),
            ],
          ),
          if (showGpsMeta) ...[
            const SizedBox(height: 12),
            Text(
              cargo.title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: palette.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _RouteLine(
            icon: Icons.trip_origin,
            color: AppTheme.success,
            text: cargo.origin,
          ),
          const SizedBox(height: 6),
          _RouteLine(
            icon: Icons.location_on,
            color: AppTheme.error,
            text: cargo.destination,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: palette.divider),
          ),
          Row(
            children: [
              _TagChip(label: cargo.cargoType, color: AppTheme.primary),
              const SizedBox(width: 8),
              _TagChip(
                label: l10n.tons(cargo.weightTons),
                color: palette.textSecondary,
              ),
              const Spacer(),
              PriceLabel(price: cargo.estimatedPrice, fontSize: 14),
            ],
          ),
        ],
      ),
    );
  }
}

class _DistanceChip extends StatelessWidget {
  const _DistanceChip({required this.km});

  final num km;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
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
            l10n.kmDistance(km),
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({
    required this.icon,
    required this.color,
    required this.text,
  });

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
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: palette.textSecondary),
          ),
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
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
