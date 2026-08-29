import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/modern_app_bar.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cargo.dart';
import '../../services/cargo_service.dart';

class CoordinatorCargoDetailScreen extends StatefulWidget {
  const CoordinatorCargoDetailScreen({super.key, required this.cargoId});

  final String cargoId;

  @override
  State<CoordinatorCargoDetailScreen> createState() =>
      _CoordinatorCargoDetailScreenState();
}

class _CoordinatorCargoDetailScreenState extends State<CoordinatorCargoDetailScreen> {
  final _cargoService = CargoService();
  Cargo? _cargo;
  bool _loading = true;

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
        appBar: ModernAppBar(title: l10n.cargoStatusTitle),
        body: const LoadingOverlay(),
      );
    }

    if (_cargo == null) {
      return Scaffold(
        appBar: ModernAppBar(title: l10n.cargoStatusTitle),
        body: EmptyState(
          icon: Icons.error_outline,
          useIllustration: true,
          title: l10n.noCargoFound,
        ),
      );
    }

    final cargo = _cargo!;

    return Scaffold(
      appBar: ModernAppBar(title: l10n.cargoStatusTitle),
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
                        StatusChip(status: cargo.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    PriceLabel(price: cargo.estimatedPrice, fontSize: 18),
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
                    InfoRow(icon: Icons.trip_origin, label: l10n.origin, value: cargo.origin),
                    InfoRow(icon: Icons.location_on, label: l10n.destination, value: cargo.destination),
                    InfoRow(icon: Icons.category, label: l10n.trailerType, value: cargo.cargoType),
                    InfoRow(icon: Icons.inventory, label: l10n.goodsType, value: cargo.goodsType),
                    InfoRow(icon: Icons.scale, label: l10n.weight, value: l10n.tons(cargo.weightTons)),
                  ],
                ),
              ),
            ),
            if (cargo.assignedDriverName != null) ...[
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.assignedDriver,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      InfoRow(
                        icon: Icons.person,
                        label: l10n.name,
                        value: cargo.assignedDriverName!,
                      ),
                      if (cargo.assignedDriverPhone != null)
                        InfoRow(
                          icon: Icons.phone,
                          label: l10n.phone,
                          value: cargo.assignedDriverPhone!,
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 160),
              child: _StatusTimeline(status: cargo.status),
            ),
            if (cargo.status == 'در انتظار راننده') ...[
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/coordinator/nearby-drivers'),
                  icon: const Icon(Icons.person_search),
                  label: Text(l10n.viewNearbyDrivers),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.status});

  final String status;

  static const _steps = [
  'در انتظار راننده',
  'تخصیص یافته',
  'در حال حمل',
  'تحویل شده',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentIndex = _steps.indexOf(status);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.shippingProgress, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...List.generate(_steps.length, (index) {
            final isCompleted = index <= currentIndex;
            final isCurrent = index == currentIndex;
            return Row(
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: isCompleted ? AppTheme.success : Colors.grey.shade300,
                      child: isCompleted
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                    if (index < _steps.length - 1)
                      Container(
                        width: 2,
                        height: 24,
                        color: index < currentIndex
                            ? AppTheme.success
                            : Colors.grey.shade300,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      l10n.cargoStatus(_steps[index]),
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCompleted ? AppTheme.primary : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
