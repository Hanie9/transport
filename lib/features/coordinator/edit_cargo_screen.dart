import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api_config.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/modern_app_bar.dart';
import '../../l10n/app_localizations.dart';
import '../../models/api_reference_item.dart';
import '../../models/cargo.dart';
import '../../services/cargo_service.dart';
import '../../services/reference_data_service.dart';

class EditCargoScreen extends StatefulWidget {
  const EditCargoScreen({super.key, required this.cargoId});

  final String cargoId;

  @override
  State<EditCargoScreen> createState() => _EditCargoScreenState();
}

class _EditCargoScreenState extends State<EditCargoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cargoService = CargoService();
  final _referenceData = ReferenceDataService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _priceController = TextEditingController();

  List<ApiReferenceItem> _products = const [];
  List<ApiReferenceItem> _machines = const [];
  List<ApiReferenceItem> _ostans = const [];
  Cargo? _cargo;
  int? _productId;
  int? _machineId;
  int? _ostanMabdaId;
  int? _ostanMaghsadId;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cargo = await _cargoService.getCargoById(widget.cargoId);
    if (!mounted) return;

    if (cargo == null) {
      setState(() => _loading = false);
      return;
    }

    if (!ApiConfig.shouldUseMock) {
      try {
        final results = await Future.wait([
          _referenceData.getProducts(),
          _referenceData.getMachines(),
          _referenceData.getOstans(),
        ]);
        if (!mounted) return;
        _products = results[0];
        _machines = results[1];
        _ostans = results[2];
      } catch (_) {}
    }

    _cargo = cargo;
    _titleController.text = cargo.title;
    _descriptionController.text = cargo.description ?? '';
    _originController.text = cargo.origin;
    _destinationController.text = cargo.destination;
    _priceController.text = '${cargo.estimatedPrice}';
    _productId = cargo.productId;
    _machineId = cargo.machineId;
    _ostanMabdaId = cargo.ostanMabdaId;
    _ostanMaghsadId = cargo.ostanMaghsadId;

    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_cargo == null || !_formKey.currentState!.validate()) return;

    if (!ApiConfig.shouldUseMock) {
      if (_productId == null ||
          _machineId == null ||
          _ostanMabdaId == null ||
          _ostanMaghsadId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.selectCargoAndGoods)),
        );
        return;
      }
    }

    setState(() => _submitting = true);
    final price = int.tryParse(_priceController.text.trim().replaceAll(',', '')) ?? 0;

    final success = await _cargoService.updateCargo(
      cargoId: _cargo!.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      price: price,
      productId: _productId,
      machineId: _machineId,
      ostanMabdaId: _ostanMabdaId,
      ostanMaghsadId: _ostanMaghsadId,
      addressMabda: _originController.text.trim(),
      addressMaghsad: _destinationController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cargoUpdated)),
      );
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
        appBar: ModernAppBar(title: l10n.editCargo),
        body: LoadingOverlay(message: l10n.loading),
      );
    }

    if (_cargo == null) {
      return Scaffold(
        appBar: ModernAppBar(title: l10n.editCargo),
        body: EmptyState(
          icon: Icons.error_outline,
          useIllustration: true,
          title: l10n.noCargoFound,
        ),
      );
    }

    return Scaffold(
      appBar: ModernAppBar(title: l10n.editCargo),
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
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? l10n.titleRequired : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.description,
                    prefixIcon: const Icon(Icons.notes_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? l10n.descriptionRequired : null,
                ),
                const SizedBox(height: 16),
                if (!ApiConfig.shouldUseMock) ...[
                  _refDropdown(
                    label: l10n.goodsType,
                    icon: Icons.inventory_2_outlined,
                    value: _productId,
                    items: _products,
                    onChanged: (v) => setState(() => _productId = v),
                  ),
                  const SizedBox(height: 16),
                  _refDropdown(
                    label: l10n.trailerType,
                    icon: Icons.local_shipping_outlined,
                    value: _machineId,
                    items: _machines,
                    onChanged: (v) => setState(() => _machineId = v),
                  ),
                  const SizedBox(height: 16),
                  _refDropdown(
                    label: l10n.originProvince,
                    icon: Icons.map_outlined,
                    value: _ostanMabdaId,
                    items: _ostans,
                    onChanged: (v) => setState(() => _ostanMabdaId = v),
                  ),
                  const SizedBox(height: 16),
                  _refDropdown(
                    label: l10n.destinationProvince,
                    icon: Icons.map_outlined,
                    value: _ostanMaghsadId,
                    items: _ostans,
                    onChanged: (v) => setState(() => _ostanMaghsadId = v),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _originController,
                  decoration: InputDecoration(
                    labelText: l10n.origin,
                    prefixIcon: const Icon(Icons.trip_origin),
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
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? l10n.destinationRequired : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.price,
                    prefixIcon: const Icon(Icons.payments_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return l10n.priceRequired;
                    if (int.tryParse(v.trim().replaceAll(',', '')) == null) {
                      return l10n.priceInvalid;
                    }
                    return null;
                  },
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
                      : Text(l10n.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _refDropdown({
    required String label,
    required IconData icon,
    required int? value,
    required List<ApiReferenceItem> items,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<int>(
              value: item.id,
              child: Text(item.name),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? label : null,
    );
  }
}
