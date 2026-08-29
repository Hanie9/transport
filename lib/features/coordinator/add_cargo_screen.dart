import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/modern_app_bar.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/cargo_service.dart';

class AddCargoScreen extends StatefulWidget {
  const AddCargoScreen({super.key});

  @override
  State<AddCargoScreen> createState() => _AddCargoScreenState();
}

class _AddCargoScreenState extends State<AddCargoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cargoService = CargoService();
  final _titleController = TextEditingController();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _weightController = TextEditingController();

  String? _cargoType;
  String? _goodsType;
  int? _estimatedPrice;
  bool _estimating = false;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _estimatePrice() async {
    final l10n = context.l10n;
    if (_originController.text.isEmpty ||
        _destinationController.text.isEmpty ||
        _cargoType == null ||
        _goodsType == null ||
        _weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fillRouteFields)),
      );
      return;
    }

    setState(() => _estimating = true);
    try {
      final price = await _cargoService.estimatePrice(
        origin: _originController.text.trim(),
        destination: _destinationController.text.trim(),
        cargoType: _cargoType!,
        goodsType: _goodsType!,
        weightTons: double.parse(_weightController.text.trim()),
      );

      if (mounted) {
        setState(() {
          _estimatedPrice = price;
          _estimating = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _estimating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cargoService.lastError ?? l10n.fillRouteFields),
        ),
      );
    }
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    if (_cargoType == null || _goodsType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectCargoAndGoods)),
      );
      return;
    }
    if (_estimatedPrice == null) {
      await _estimatePrice();
      if (_estimatedPrice == null) return;
    }

    setState(() => _submitting = true);
    final user = context.read<AuthService>().currentUser;
    final coordinatorName = user?.fullName ?? l10n.defaultCoordinatorName;

    try {
      await _cargoService.createCargo(
        title: _titleController.text.trim(),
        origin: _originController.text.trim(),
        destination: _destinationController.text.trim(),
        cargoType: _cargoType!,
        goodsType: _goodsType!,
        weightTons: double.parse(_weightController.text.trim()),
        estimatedPrice: _estimatedPrice!,
        coordinatorName: coordinatorName,
      );

      if (!mounted) return;
      setState(() => _submitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cargoRegistered)),
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cargoService.lastError ?? l10n.fillRouteFields),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: ModernAppBar(title: l10n.addNewCargo),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FadeSlideIn(
          child: Form(
            key: _formKey,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.cargoTitle,
                  prefixIcon: const Icon(Icons.title),
                  hintText: l10n.cargoTitleHint,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l10n.titleRequired : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _originController,
                decoration: InputDecoration(
                  labelText: l10n.origin,
                  prefixIcon: const Icon(Icons.trip_origin),
                  hintText: l10n.originHint,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l10n.originRequired : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _destinationController,
                decoration: InputDecoration(
                  labelText: l10n.destination,
                  prefixIcon: const Icon(Icons.location_on),
                  hintText: l10n.destinationHint,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l10n.destinationRequired : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _cargoType,
                decoration: InputDecoration(
                  labelText: l10n.trailerType,
                  prefixIcon: const Icon(Icons.local_shipping_outlined),
                ),
                items: AppConstants.cargoTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(l10n.cargoType(t))))
                    .toList(),
                onChanged: (v) => setState(() => _cargoType = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _goodsType,
                decoration: InputDecoration(
                  labelText: l10n.goodsType,
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                ),
                items: AppConstants.goodsTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(l10n.goodsTypeLabel(t))))
                    .toList(),
                onChanged: (v) => setState(() => _goodsType = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.weightTonsLabel,
                  prefixIcon: const Icon(Icons.scale_outlined),
                  hintText: '22',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l10n.weightRequired;
                  if (double.tryParse(v.trim()) == null) return l10n.weightInvalid;
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.price_check, color: AppTheme.accent),
                        const SizedBox(width: 8),
                        Text(
                          l10n.estimatePrice,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        if (_estimating)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          TextButton(
                            onPressed: _estimatePrice,
                            child: Text(l10n.calculate),
                          ),
                      ],
                    ),
                    if (_estimatedPrice != null) ...[
                      const SizedBox(height: 8),
                      PriceLabel(price: _estimatedPrice!, fontSize: 18),
                      Text(
                        l10n.priceEstimateHint,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(l10n.addCargo),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
