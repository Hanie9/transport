import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
    _editingVehicle = widget.editVehicleInitially;
  }

  Future<void> _saveVehicle(VehicleInfo info) async {
    await context.read<AuthService>().updateVehicleInfo(info);
    if (!mounted) return;
    setState(() => _editingVehicle = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.vehicleSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.watch<AuthService>().currentUser;
    final vehicle = user?.vehicleInfo;

    return Scaffold(
      appBar: ModernAppBar(title: l10n.profile),
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
                  icon: Icon(vehicle == null ? Icons.add : Icons.edit_outlined, size: 18),
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
            Center(child: IranianPlateDisplay(plateNumber: vehicle!.plateNumber)),
            const SizedBox(height: 16),
            _InfoRow(label: l10n.vehicleModel, value: vehicle!.vehicleModel),
            _InfoRow(label: l10n.trailerType, value: l10n.cargoType(vehicle!.cargoType)),
            if (vehicle!.capacityTons != null)
              _InfoRow(label: l10n.capacity, value: l10n.tons(vehicle!.capacityTons!)),
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
          Text(label, style: TextStyle(fontSize: 13, color: palette.textSecondary)),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: palette.textPrimary)),
        ],
      ),
    );
  }
}

class _CoordinatorProfileScreen extends StatelessWidget {
  const _CoordinatorProfileScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.watch<AuthService>().currentUser;

    return Scaffold(
      appBar: ModernAppBar(title: l10n.profile),
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
          ],
        ),
      ),
    );
  }
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
      title: Text(title, style: TextStyle(fontSize: 12, color: palette.textSecondary)),
      subtitle: Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: palette.textPrimary)),
    );
  }
}
