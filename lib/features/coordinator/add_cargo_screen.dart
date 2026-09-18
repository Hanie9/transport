import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../api_config.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/modern_app_bar.dart';
import '../../core/widgets/modern_dropdown.dart';
import '../../l10n/app_localizations.dart';
import '../../models/api_reference_item.dart';
import '../../services/auth_service.dart';
import '../../services/cargo_service.dart';
import '../../services/reference_data_service.dart';
import '../../services/transport_api_mapper.dart';

class AddCargoScreen extends StatefulWidget {
  const AddCargoScreen({super.key});

  @override
  State<AddCargoScreen> createState() => _AddCargoScreenState();
}

class _AddCargoScreenState extends State<AddCargoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cargoService = CargoService();
  final _referenceData = ReferenceDataService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _priceController = TextEditingController();
  final _weightController = TextEditingController();

  List<ApiReferenceItem> _products = const [];
  List<ApiReferenceItem> _machines = const [];
  List<ApiReferenceItem> _ostans = const [];
  int? _productId;
  int? _machineId;
  int? _ostanMabdaId;
  int? _ostanMaghsadId;
  bool _loadingRefs = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadReferenceData();
  }

  Future<void> _loadReferenceData() async {
    if (ApiConfig.shouldUseMock) {
      if (mounted) setState(() => _loadingRefs = false);
      return;
    }

    try {
      final results = await Future.wait([
        _referenceData.getProducts(),
        _referenceData.getMachines(),
        _referenceData.getOstans(),
      ]);
      if (!mounted) return;
      setState(() {
        _products = results[0];
        _machines = results[1];
        _ostans = results[2];
        _loadingRefs = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingRefs = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _priceController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;

    if (!ApiConfig.shouldUseMock) {
      if (_productId == null ||
          _machineId == null ||
          _ostanMabdaId == null ||
          _ostanMaghsadId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.selectCargoAndGoods)));
        return;
      }
    }

    setState(() => _submitting = true);
    final user = context.read<AuthService>().currentUser;
    final coordinatorName = user?.fullName ?? l10n.defaultCoordinatorName;
    final price =
        int.tryParse(_priceController.text.trim().replaceAll(',', '')) ?? 0;

    try {
      await _cargoService.createCargo(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        origin: _originController.text.trim(),
        destination: _destinationController.text.trim(),
        cargoType: _machines
            .firstWhere(
              (m) => m.id == _machineId,
              orElse: () => const ApiReferenceItem(id: 0, name: ''),
            )
            .name,
        goodsType: _products
            .firstWhere(
              (p) => p.id == _productId,
              orElse: () => const ApiReferenceItem(id: 0, name: ''),
            )
            .name,
        weightTons: TransportApiMapper.parseWeightTons(_weightController.text)!,
        estimatedPrice: price,
        coordinatorName: coordinatorName,
        productId: _productId,
        machineId: _machineId,
        ostanMabdaId: _ostanMabdaId,
        ostanMaghsadId: _ostanMaghsadId,
      );

      if (!mounted) return;
      setState(() => _submitting = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.cargoRegistered)));
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

    if (_loadingRefs && !ApiConfig.shouldUseMock) {
      return Scaffold(
        appBar: ModernAppBar(title: l10n.addNewCargo),
        body: LoadingOverlay(message: l10n.loading),
      );
    }

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
                  controller: _descriptionController,
                  maxLength: 450,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.description,
                    prefixIcon: const Icon(Icons.notes_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? l10n.descriptionRequired
                      : null,
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
                    hintText: l10n.originHint,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? l10n.originRequired
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    labelText: l10n.destination,
                    prefixIcon: const Icon(Icons.location_on),
                    hintText: l10n.destinationHint,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? l10n.destinationRequired
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _weightController,
                  maxLength: 20,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.weightTonsLabel,
                    prefixIcon: const Icon(Icons.scale_outlined),
                    hintText: '12.5',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.weightRequired;
                    }
                    return TransportApiMapper.parseWeightTons(value) == null
                        ? l10n.weightInvalid
                        : null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.price,
                    prefixIcon: const Icon(Icons.payments_outlined),
                    hintText: '5000000',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return l10n.priceRequired;
                    }
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
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
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

  Widget _refDropdown({
    required String label,
    required IconData icon,
    required int? value,
    required List<ApiReferenceItem> items,
    required ValueChanged<int?> onChanged,
  }) {
    return ModernDropdownField<int>(
      value: value,
      label: label,
      prefixIcon: icon,
      items: items
          .map(
            (item) =>
                DropdownMenuItem<int>(value: item.id, child: Text(item.name)),
          )
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? label : null,
    );
  }
}
