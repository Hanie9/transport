import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/iranian_plate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/iranian_plate_widget.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/user.dart';

class VehicleInfoForm extends StatefulWidget {
  const VehicleInfoForm({
    super.key,
    this.initial,
    required this.onSave,
    this.onCancel,
    this.showHeader = true,
  });

  final VehicleInfo? initial;
  final Future<void> Function(VehicleInfo info) onSave;
  final VoidCallback? onCancel;
  final bool showHeader;

  @override
  State<VehicleInfoForm> createState() => _VehicleInfoFormState();
}

class _VehicleInfoFormState extends State<VehicleInfoForm> {
  final _formKey = GlobalKey<FormState>();
  final _plateKey = GlobalKey<IranianPlateInputState>();
  final _modelController = TextEditingController();
  final _capacityController = TextEditingController();
  String? _selectedCargoType;
  bool _saving = false;
  IranianPlateData _plateData = const IranianPlateData();

  @override
  void initState() {
    super.initState();
    _loadInitial(widget.initial);
  }

  @override
  void didUpdateWidget(covariant VehicleInfoForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial) {
      _loadInitial(widget.initial);
    }
  }

  void _loadInitial(VehicleInfo? vehicle) {
    if (vehicle != null) {
      _plateData = IranianPlateData.parse(vehicle.plateNumber) ?? const IranianPlateData();
      _modelController.text = vehicle.vehicleModel;
      _selectedCargoType = vehicle.cargoType;
      _capacityController.text = vehicle.capacityTons?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _modelController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final plateError = _plateKey.currentState?.validate();
    if (!_formKey.currentState!.validate() || plateError != null) return;
    if (_selectedCargoType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectTrailerType)),
      );
      return;
    }

    setState(() => _saving = true);

    final info = VehicleInfo(
      plateNumber: _plateData.toStorageString(),
      cargoType: _selectedCargoType!,
      vehicleModel: _modelController.text.trim(),
      capacityTons: double.tryParse(_capacityController.text.trim()),
    );

    await widget.onSave(info);

    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showHeader) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.vehicleFormHint,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          IranianPlateInput(
            key: _plateKey,
            initialValue: widget.initial?.plateNumber,
            onChanged: (data) => _plateData = data,
            validator: (data) {
              if (data == null || !data.isComplete) {
                return l10n.plateIncomplete;
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _modelController,
            decoration: InputDecoration(
              labelText: l10n.vehicleModel,
              prefixIcon: const Icon(Icons.directions_car_outlined),
              hintText: l10n.vehicleModelHint,
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? l10n.modelRequired : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCargoType,
            decoration: InputDecoration(
              labelText: l10n.trailerType,
              prefixIcon: const Icon(Icons.category_outlined),
            ),
            items: AppConstants.cargoTypes
                .map((t) => DropdownMenuItem(value: t, child: Text(l10n.cargoType(t))))
                .toList(),
            onChanged: (v) => setState(() => _selectedCargoType = v),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _capacityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.capacityTons,
              prefixIcon: const Icon(Icons.scale_outlined),
              hintText: '24',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(l10n.saveVehicleInfo),
          ),
          if (widget.onCancel != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _saving ? null : widget.onCancel,
              child: Text(l10n.cancel),
            ),
          ],
        ],
      ),
    );
  }
}
