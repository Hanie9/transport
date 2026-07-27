import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cargo.dart';
import '../../services/cargo_service.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key, required this.cargoId});

  final String cargoId;

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final _cargoService = CargoService();
  Cargo? _cargo;
  bool _loading = true;
  int _routeStep = 0; // 0: to origin, 1: to destination

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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.routeTitle)),
        body: LoadingOverlay(message: l10n.loadingRoute),
      );
    }

    if (_cargo == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.routeTitle)),
        body: EmptyState(icon: Icons.map_outlined, title: l10n.routeNotFound),
      );
    }

    final cargo = _cargo!;
    final destination = _routeStep == 0 ? cargo.origin : cargo.destination;
    final stepLabel = _routeStep == 0 ? l10n.routeToOrigin : l10n.routeToDestination;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.routeTitle)),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            height: 220,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map, size: 64, color: AppTheme.primary.withValues(alpha: 0.4)),
                      const SizedBox(height: 8),
                      Text(
                        l10n.neshanMap,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.neshanApiNote,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      stepLabel,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppCard(
              child: Column(
                children: [
                  InfoRow(
                    icon: _routeStep == 0 ? Icons.trip_origin : Icons.location_on,
                    label: _routeStep == 0 ? l10n.cargoOriginPoint : l10n.cargoDestinationPoint,
                    value: destination,
                  ),
                  if (cargo.distanceKm != null)
                    InfoRow(
                      icon: Icons.straighten,
                      label: l10n.totalDistance,
                      value: l10n.distanceKm(cargo.distanceKm!),
                    ),
                  InfoRow(
                    icon: Icons.local_shipping,
                    label: l10n.statusLabel,
                    value: cargo.status,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _StepIndicator(
                  step: 1,
                  label: l10n.origin,
                  isActive: _routeStep == 0,
                  isCompleted: _routeStep > 0,
                ),
                Expanded(
                  child: Container(
                    height: 2,
                    color: _routeStep > 0 ? AppTheme.success : Colors.grey.shade300,
                  ),
                ),
                _StepIndicator(
                  step: 2,
                  label: l10n.destination,
                  isActive: _routeStep == 1,
                  isCompleted: false,
                ),
              ],
            ),
          ),
          const Spacer(),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 28),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.navigationToApi(destination)),
                        ),
                      );
                    },
                    icon: const Icon(Icons.navigation),
                    label: Text(l10n.startNavigationTo(_routeStep == 0 ? l10n.origin : l10n.destination)),
                  ),
                  if (_routeStep == 0) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => setState(() => _routeStep = 1),
                      child: Text(l10n.arrivedAtOriginContinue),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.step,
    required this.label,
    required this.isActive,
    required this.isCompleted,
  });

  final int step;
  final String label;
  final bool isActive;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final color = isCompleted
        ? AppTheme.success
        : isActive
            ? AppTheme.primary
            : Colors.grey.shade400;

    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color,
          child: isCompleted
              ? const Icon(Icons.check, size: 18, color: Colors.white)
              : Text('$step', style: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
