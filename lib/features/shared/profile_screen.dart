import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/iranian_plate_widget.dart';
import '../../core/widgets/modern_app_bar.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../driver/widgets/vehicle_info_form.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.role,
    this.editVehicleInitially = false,
  });

  final String role;
  final bool editVehicleInitially;

  @override
  Widget build(BuildContext context) {
    if (role == 'driver') {
      return _DriverProfileScreen(editVehicleInitially: editVehicleInitially);
    }
    return const _CoordinatorProfileScreen();
  }
}

class _DriverProfileScreen extends StatefulWidget {
  const _DriverProfileScreen({this.editVehicleInitially = false});

  final bool editVehicleInitially;

  @override
  State<_DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<_DriverProfileScreen> {
  late bool _editingVehicle;
  bool _refreshingProfile = false;

  @override
  void initState() {
    super.initState();
    _editingVehicle = widget.editVehicleInitially;
  }

  Future<void> _refreshProfile() async {
    if (_refreshingProfile || ApiConfig.shouldUseMock) return;
    setState(() => _refreshingProfile = true);
    final ok = await context.read<AuthService>().refreshProfile();
    if (!mounted) return;
    setState(() => _refreshingProfile = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? context.l10n.profileRefreshed
              : context.l10n.profileRefreshFailed,
        ),
      ),
    );
  }

  Future<void> _saveVehicle(VehicleInfo info) async {
    final auth = context.read<AuthService>();
    final saved = await auth.updateVehicleInfo(info);
    if (!mounted) return;
    if (!saved) {
      final message = auth.lastError ?? context.l10n.profileRefreshFailed;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    setState(() => _editingVehicle = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.vehicleSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.watch<AuthService>().currentUser;
    final vehicle = user?.vehicleInfo;

    return Scaffold(
      appBar: ModernAppBar(
        title: l10n.profile,
        actions: [
          IconButton(
            tooltip: l10n.edit,
            onPressed: () => _editProfile(context),
            icon: const Icon(Icons.edit_outlined),
          ),
          if (!ApiConfig.shouldUseMock)
            IconButton(
              tooltip: l10n.refreshProfile,
              onPressed: _refreshingProfile ? null : _refreshProfile,
              icon: _refreshingProfile
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FadeSlideIn(
              child: ProfileHeroHeader(
                name: user?.fullName ?? '',
                roleLabel: l10n.roleLabel('driver'),
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: _ProfileTile(
                icon: Icons.phone_outlined,
                title: l10n.phoneNumber,
                value: user?.phone ?? '',
              ),
            ),
            if (user?.email != null)
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: _ProfileTile(
                  icon: Icons.email_outlined,
                  title: l10n.email,
                  value: user!.email!,
                ),
              ),
            if (user?.nationalCode?.isNotEmpty == true)
              FadeSlideIn(
                delay: const Duration(milliseconds: 140),
                child: _ProfileTile(
                  icon: Icons.badge_outlined,
                  title: l10n.nationalCode,
                  value: user!.nationalCode!,
                ),
              ),
            const SizedBox(height: 8),
            FadeSlideIn(
              delay: const Duration(milliseconds: 160),
              child: _VehicleSection(
                vehicle: vehicle,
                editing: _editingVehicle,
                onEdit: () => setState(() => _editingVehicle = true),
                onCancel: () => setState(() => _editingVehicle = false),
                onSave: _saveVehicle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleSection extends StatelessWidget {
  const _VehicleSection({
    required this.vehicle,
    required this.editing,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
  });

  final VehicleInfo? vehicle;
  final bool editing;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final Future<void> Function(VehicleInfo info) onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.vehicleInfo,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              if (!editing)
                TextButton.icon(
                  onPressed: onEdit,
                  icon: Icon(
                    vehicle == null ? Icons.add : Icons.edit_outlined,
                    size: 18,
                  ),
                  label: Text(vehicle == null ? l10n.register : l10n.edit),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (editing)
            VehicleInfoForm(
              initial: vehicle,
              onSave: onSave,
              onCancel: onCancel,
              showHeader: false,
            )
          else if (vehicle == null)
            EmptyState(
              icon: Icons.local_shipping_outlined,
              useIllustration: true,
              title: l10n.vehicleNotRegistered,
              subtitle: l10n.vehicleRegisterHint,
            )
          else ...[
            Text(
              l10n.vehiclePlate,
              style: TextStyle(fontSize: 12, color: palette.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Center(
              child: IranianPlateDisplay(plateNumber: vehicle!.plateNumber),
            ),
            const SizedBox(height: 16),
            _InfoRow(label: l10n.vehicleModel, value: vehicle!.vehicleModel),
            _InfoRow(
              label: l10n.trailerType,
              value: l10n.cargoType(vehicle!.cargoType),
            ),
            if (vehicle!.capacityTons != null)
              _InfoRow(
                label: l10n.capacity,
                value: l10n.tons(vehicle!.capacityTons!),
              ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: palette.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoordinatorProfileScreen extends StatefulWidget {
  const _CoordinatorProfileScreen();

  @override
  State<_CoordinatorProfileScreen> createState() =>
      _CoordinatorProfileScreenState();
}

class _CoordinatorProfileScreenState extends State<_CoordinatorProfileScreen> {
  bool _refreshingProfile = false;

  Future<void> _refreshProfile() async {
    if (_refreshingProfile || ApiConfig.shouldUseMock) return;
    setState(() => _refreshingProfile = true);
    final ok = await context.read<AuthService>().refreshProfile();
    if (!mounted) return;
    setState(() => _refreshingProfile = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? context.l10n.profileRefreshed
              : context.l10n.profileRefreshFailed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.watch<AuthService>().currentUser;

    return Scaffold(
      appBar: ModernAppBar(
        title: l10n.profile,
        actions: [
          IconButton(
            tooltip: l10n.edit,
            onPressed: () => _editProfile(context),
            icon: const Icon(Icons.edit_outlined),
          ),
          if (!ApiConfig.shouldUseMock)
            IconButton(
              tooltip: l10n.refreshProfile,
              onPressed: _refreshingProfile ? null : _refreshProfile,
              icon: _refreshingProfile
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FadeSlideIn(
              child: ProfileHeroHeader(
                name: user?.fullName ?? '',
                roleLabel: l10n.roleLabel('coordinator'),
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: _ProfileTile(
                icon: Icons.phone_outlined,
                title: l10n.phoneNumber,
                value: user?.phone ?? '',
              ),
            ),
            if (user?.email != null)
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: _ProfileTile(
                  icon: Icons.email_outlined,
                  title: l10n.email,
                  value: user!.email!,
                ),
              ),
            if (user?.nationalCode?.isNotEmpty == true)
              FadeSlideIn(
                delay: const Duration(milliseconds: 140),
                child: _ProfileTile(
                  icon: Icons.badge_outlined,
                  title: l10n.nationalCode,
                  value: user!.nationalCode!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _editProfile(BuildContext context) async {
  final l10n = context.l10n;
  final auth = context.read<AuthService>();
  final user = auth.currentUser;
  if (user == null) return;

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: user.fullName);
  final nationalCodeController = TextEditingController(
    text: user.nationalCode ?? '',
  );
  final values = await showDialog<(String, String?)>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.edit),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(labelText: l10n.fullName),
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.nameRequired
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nationalCodeController,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: l10n.nationalCode),
              validator: (value) {
                final normalized = value?.trim() ?? '';
                if (normalized.isNotEmpty && normalized.length != 10) {
                  return l10n.nationalCodeInvalid;
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            Navigator.pop(dialogContext, (
              nameController.text.trim(),
              nationalCodeController.text.trim().isEmpty
                  ? null
                  : nationalCodeController.text.trim(),
            ));
          },
          child: Text(l10n.save),
        ),
      ],
    ),
  );
  nameController.dispose();
  nationalCodeController.dispose();
  if (values == null || !context.mounted) return;

  final saved = await auth.updateProfile(
    fullName: values.$1,
    nationalCode: values.$2,
    machineId: user.vehicleInfo?.machineId,
    ostanId: user.vehicleInfo?.ostanId,
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        saved
            ? context.l10n.profileRefreshed
            : (auth.lastError ?? context.l10n.profileRefreshFailed),
      ),
    ),
  );
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryLight),
      title: Text(
        title,
        style: TextStyle(fontSize: 12, color: palette.textSecondary),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: palette.textPrimary,
        ),
      ),
    );
  }
}
