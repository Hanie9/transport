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

class _CoordinatorCargoDetailScreenState
    extends State<CoordinatorCargoDetailScreen> {
  final _cargoService = CargoService();
  Cargo? _cargo;
  bool _loading = true;
  bool _busy = false;

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

  Future<void> _updateStatus(String status) async {
    if (_cargo == null || _busy) return;
    setState(() => _busy = true);
    final success = await _cargoService.updateCargoStatus(_cargo!.id, status);
    if (!mounted) return;
    setState(() => _busy = false);
    if (success) {
      await _loadCargo();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.cargoStatusUpdated(status))),
      );
    } else {
      final error = _cargoService.lastError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? context.l10n.genericError)),
      );
    }
  }

  Future<void> _deleteCargo() async {
    if (_cargo == null || _busy) return;
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCargo),
        content: Text(l10n.deleteCargoConfirm(_cargo!.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final success = await _cargoService.deleteCargo(_cargo!.id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.cargoDeleted)));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cargoService.lastError ?? l10n.genericError)),
      );
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
    final isCancelled = cargo.status == 'لغو شده';
    final isDone = cargo.status == 'تحویل شده';
    final canDelete = cargo.status == 'در انتظار راننده';
    final canCancel =
        cargo.status == 'در انتظار راننده' || cargo.status == 'تخصیص یافته';
    final canMarkDone = cargo.status == 'تخصیص یافته';
    final canEdit = cargo.status == 'در انتظار راننده';

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
                        StatusChip(status: cargo.status, date: cargo.createdAt),
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
                    if (cargo.description != null &&
                        cargo.description!.trim().isNotEmpty)
                      InfoRow(
                        icon: Icons.notes,
                        label: l10n.description,
                        value: cargo.description!,
                      ),
                    if (cargo.weightTons > 0)
                      InfoRow(
                        icon: Icons.scale,
                        label: l10n.weight,
                        value: l10n.tons(cargo.weightTons),
                      ),
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
            if (!isCancelled && !isDone) ...[
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (canEdit)
                      OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => context.push(
                                '/coordinator/cargo/${cargo.id}/edit',
                              ),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(l10n.editCargo),
                      ),
                    if (canEdit) const SizedBox(height: 8),
                    if (canMarkDone)
                      FilledButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _updateStatus('تحویل شده'),
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(l10n.markCargoDone),
                      ),
                    if (canMarkDone) const SizedBox(height: 8),
                    if (canCancel)
                      OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _updateStatus('لغو شده'),
                        icon: const Icon(Icons.cancel_outlined),
                        label: Text(l10n.cancelCargo),
                      ),
                    if (canDelete) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _deleteCargo,
                        icon: const Icon(Icons.delete_outline),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                        ),
                        label: Text(l10n.deleteCargo),
                      ),
                    ],
                  ],
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

  static const _steps = ['در انتظار راننده', 'تخصیص یافته', 'تحویل شده'];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (status == 'لغو شده') {
      return AppCard(
        child: Row(
          children: [
            const Icon(Icons.cancel, color: AppTheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.cargoStatus('لغو شده'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.error,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final currentIndex = _steps.indexOf(status);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.shippingProgress,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...List.generate(_steps.length, (index) {
            final isCompleted = currentIndex >= 0 && index <= currentIndex;
            final isCurrent = index == currentIndex;
            return Row(
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: isCompleted
                          ? AppTheme.success
                          : Colors.grey.shade300,
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
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
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
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
