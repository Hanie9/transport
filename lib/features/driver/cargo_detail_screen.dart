import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/modern_app_bar.dart';
import '../../l10n/api_messages.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cargo.dart';
import '../../services/auth_service.dart';
import '../../services/cargo_service.dart';

class CargoDetailScreen extends StatefulWidget {
  const CargoDetailScreen({super.key, required this.cargoId});

  final String cargoId;

  @override
  State<CargoDetailScreen> createState() => _CargoDetailScreenState();
}

class _CargoDetailScreenState extends State<CargoDetailScreen> {
  final _cargoService = CargoService();
  Cargo? _cargo;
  bool _loading = true;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _loadCargo();
  }

  Future<void> _loadCargo() async {
    final cargo = await _cargoService.getCargoById(widget.cargoId);
    if (mounted) {
      setState(() {
        _cargo = cargo;
        _loading = false;
      });
    }
  }

  Future<void> _acceptCargo() async {
    if (_accepting) return;
    final user = context.read<AuthService>().currentUser;
    if (user == null || _cargo == null) return;
    final l10n = context.l10n;

    if (user.vehicleInfo?.isCompleteForCargoAcceptance != true) {
      final goToProfile = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.local_shipping_outlined),
          title: Text(l10n.completeVehicleProfile),
          content: Text(l10n.completeVehicleBeforeAccepting),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.notNow),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.goToProfile),
            ),
          ],
        ),
      );
      if (goToProfile == true && mounted) {
        context.go('/driver/profile?editVehicle=1');
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.acceptCargo),
        content: Text(l10n.acceptCargoConfirm(_cargo!.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted || _accepting) return;

    setState(() => _accepting = true);
    final success = await _cargoService.acceptCargo(
      _cargo!.id,
      user.fullName,
      user.phone,
      driverMachineId: user.vehicleInfo?.machineId,
    );

    if (!mounted) return;
    setState(() => _accepting = false);

    if (success) {
      setState(() => _cargo = _cargo!.copyWith(status: 'تخصیص یافته'));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.cargoAccepted)));
      context.push('/driver/route/${_cargo!.id}');
    } else {
      final msg = _cargoService.lastError;
      if (msg != null && msg.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_loading) {
      return Scaffold(
        appBar: ModernAppBar(title: l10n.cargoDetails),
        body: LoadingOverlay(message: l10n.loading),
      );
    }

    if (_cargo == null) {
      return Scaffold(
        appBar: ModernAppBar(title: l10n.cargoDetails),
        body: EmptyState(
          icon: Icons.error_outline,
          useIllustration: true,
          title: l10n.noCargoFound,
        ),
      );
    }

    final cargo = _cargo!;
    final canAccept = cargo.status == 'در انتظار راننده';
    final user = context.watch<AuthService>().currentUser;
    final driverMachineId = user?.vehicleInfo?.machineId;
    final machineMismatch =
        canAccept &&
        !ApiConfig.shouldUseMock &&
        cargo.machineId != null &&
        driverMachineId != null &&
        cargo.machineId != driverMachineId;
    final machineNotSet =
        canAccept && !ApiConfig.shouldUseMock && driverMachineId == null;

    return Scaffold(
      appBar: ModernAppBar(title: l10n.cargoDetails),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeSlideIn(
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cargo.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        StatusChip(status: cargo.status, date: cargo.createdAt),
                      ],
                    ),
                    const SizedBox(height: 16),
                    PriceLabel(price: cargo.estimatedPrice, fontSize: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: AppCard(
                child: Column(
                  children: [
                    InfoRow(
                      icon: Icons.trip_origin,
                      label: l10n.origin,
                      value: cargo.origin,
                    ),
                    InfoRow(
                      icon: Icons.location_on,
                      label: l10n.destination,
                      value: cargo.destination,
                    ),
                    if (cargo.distanceKm != null)
                      InfoRow(
                        icon: Icons.straighten,
                        label: l10n.distance,
                        value: l10n.distanceKm(cargo.distanceKm!),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: AppCard(
                child: Column(
                  children: [
                    InfoRow(
                      icon: Icons.category,
                      label: l10n.trailerType,
                      value: cargo.cargoType,
                    ),
                    InfoRow(
                      icon: Icons.inventory,
                      label: l10n.goodsType,
                      value: cargo.goodsType,
                    ),
                    InfoRow(
                      icon: Icons.scale,
                      label: l10n.weight,
                      value: l10n.tons(cargo.weightTons),
                    ),
                    InfoRow(
                      icon: Icons.business,
                      label: l10n.coordinator,
                      value: cargo.coordinatorName,
                    ),
                  ],
                ),
              ),
            ),
            if (cargo.isNearby && cargo.nearbyDistanceKm != null) ...[
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 160),
                child: InfoBanner(
                  message: l10n.nearbyCargoDistance(cargo.nearbyDistanceKm!),
                  icon: Icons.near_me_rounded,
                  color: AppTheme.accent,
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (machineNotSet) ...[
              InfoBanner(
                message: l10n.selectMachineType,
                icon: Icons.warning_amber_rounded,
                color: AppTheme.warning,
              ),
              const SizedBox(height: 12),
            ],
            if (machineMismatch) ...[
              InfoBanner(
                message: ApiMessages.machineMismatch(
                  isEnglish: !l10n.isFa,
                  requiredMachine: cargo.cargoType,
                ),
                icon: Icons.warning_amber_rounded,
                color: AppTheme.warning,
              ),
              const SizedBox(height: 12),
            ],
            FadeSlideIn(
              delay: const Duration(milliseconds: 200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (canAccept)
                    ElevatedButton(
                      onPressed: _accepting ? null : _acceptCargo,
                      child: _accepting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(l10n.acceptCargo),
                    ),
                  if (!canAccept && cargo.status != 'در انتظار راننده')
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.push('/driver/route/${cargo.id}'),
                      icon: const Icon(Icons.map_outlined),
                      label: Text(l10n.viewRoute),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
