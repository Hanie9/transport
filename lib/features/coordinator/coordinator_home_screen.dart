import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/double_back_to_exit.dart';
import '../../core/widgets/shell_scope.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/modern_app_bar.dart';
import '../../models/cargo.dart';
import '../../services/cargo_service.dart';

class CoordinatorShell extends StatefulWidget {
  const CoordinatorShell({super.key, required this.child});

  final Widget child;

  @override
  State<CoordinatorShell> createState() => _CoordinatorShellState();
}

class _CoordinatorShellState extends State<CoordinatorShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  int _indexFromLocation(String location) {
    if (location.startsWith('/coordinator/cargos')) return 1;
    if (location.startsWith('/coordinator/profile')) return 2;
    return 0;
  }

  void _onTap(int index) {
    switch (index) {
      case 0:
        context.go('/coordinator');
      case 1:
        context.go('/coordinator/cargos');
      case 2:
        context.go('/coordinator/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexFromLocation(location);
    final hideBottomNav = AppDrawer.hidesBottomNav(location, 'coordinator');

    return DoubleBackToExit(
      enabled: !hideBottomNav,
      child: ShellScope(
        openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        child: Scaffold(
          key: _scaffoldKey,
          drawer: const AppDrawer(role: 'coordinator'),
          body: widget.child,
          floatingActionButton: (index == 0 || index == 1) && !hideBottomNav
              ? FloatingActionButton.extended(
                  onPressed: () => context.push('/coordinator/add-cargo'),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.addCargo),
                )
              : null,
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
                      icon: const Icon(Icons.list_alt_outlined),
                      selectedIcon: const Icon(Icons.list_alt),
                      label: l10n.cargos,
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

class CoordinatorHomeScreen extends StatefulWidget {
  const CoordinatorHomeScreen({super.key});

  @override
  State<CoordinatorHomeScreen> createState() => _CoordinatorHomeScreenState();
}

class _CoordinatorHomeScreenState extends State<CoordinatorHomeScreen> {
  final _cargoService = CargoService();
  List<Cargo> _cargos = [];
  bool _loading = true;
  String _filter = 'همه';

  @override
  void initState() {
    super.initState();
    _loadCargos(showLoader: true);
  }

  Future<void> _loadCargos({bool showLoader = false}) async {
    if (showLoader) setState(() => _loading = true);
    final cargos = await _cargoService.getCoordinatorCargos();
    if (mounted) {
      setState(() {
        _cargos = cargos;
        _loading = false;
      });
    }
  }

  List<Cargo> get _filteredCargos {
    if (_filter == 'همه') return _cargos;
    return _cargos.where((c) => c.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final filterOptions = ['همه', ...AppConstants.cargoStatuses];

    return Scaffold(
      appBar: ModernAppBar(title: l10n.cargoManagement),
      body: AppRefreshIndicator(
        onRefresh: () => _loadCargos(),
        slivers: [
          SliverToBoxAdapter(
            child: FadeSlideIn(
              child: SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  children: filterOptions.map((status) {
                    final isSelected = _filter == status;
                    final label = status == 'همه'
                        ? l10n.filterAll
                        : l10n.cargoStatus(status);
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8),
                      child: FilterChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _filter = status),
                        selectedColor: AppTheme.primary.withValues(alpha: 0.12),
                        checkmarkColor: AppTheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppTheme.primary
                              : palette.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        backgroundColor: palette.cardBg,
                        side: BorderSide(
                          color: isSelected
                              ? AppTheme.primary.withValues(alpha: 0.3)
                              : palette.divider,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          if (_loading)
            SliverFillRemaining(
              hasScrollBody: false,
              child: SizedBox.expand(
                child: LoadingOverlay(message: l10n.loading),
              ),
            )
          else if (_filteredCargos.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.inventory_2_outlined,
                useIllustration: true,
                title: l10n.noCargoFound,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final cargo = _filteredCargos[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: StaggeredItem(
                      index: index,
                      child: AppCard(
                        onTap: () =>
                            context.push('/coordinator/cargo/${cargo.id}'),
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
                                StatusChip(status: cargo.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              cargo.routeLabel,
                              style: TextStyle(
                                fontSize: 13,
                                color: palette.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    cargo.cargoType,
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                PriceLabel(
                                  price: cargo.estimatedPrice,
                                  fontSize: 13,
                                ),
                              ],
                            ),
                            if (cargo.assignedDriverName != null) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Divider(
                                  height: 1,
                                  color: palette.divider,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    size: 16,
                                    color: AppTheme.success,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n.driverLabel(cargo.assignedDriverName!),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.success,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }, childCount: _filteredCargos.length),
              ),
            ),
        ],
      ),
    );
  }
}
