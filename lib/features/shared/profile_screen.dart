import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/iranian_plate_widget.dart';
import '../../core/widgets/modern_app_bar.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user.dart';
import '../../models/cargo.dart';
import '../../services/auth_service.dart';
import '../../services/cargo_service.dart';
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
  bool _loadingCargos = true;
  List<Cargo> _cargos = const [];

  @override
  void initState() {
    super.initState();
    _loadCargos();
  }

  Future<bool> _loadCargos() async {
    try {
      final cargos = await CargoService().getCoordinatorCargos();
      if (!mounted) return false;
      setState(() {
        _cargos = cargos;
        _loadingCargos = false;
      });
      return true;
    } catch (_) {
      if (mounted) setState(() => _loadingCargos = false);
      return false;
    }
  }

  Future<void> _refreshProfile() async {
    if (_refreshingProfile || ApiConfig.shouldUseMock) return;
    setState(() => _refreshingProfile = true);
    final results = await Future.wait([
      context.read<AuthService>().refreshProfile(),
      _loadCargos(),
    ]);
    if (!mounted) return;
    setState(() => _refreshingProfile = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          results.every((result) => result)
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
    final pending = _cargos
        .where((cargo) => cargo.status == 'در انتظار راننده')
        .length;
    final assigned = _cargos
        .where((cargo) => cargo.status == 'تخصیص یافته')
        .length;
    final completed = _cargos
        .where((cargo) => cargo.status == 'تحویل شده')
        .length;
    final totalValue = _cargos.fold<int>(
      0,
      (total, cargo) => total + cargo.estimatedPrice,
    );

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
              child: _CoordinatorProfileHero(
                name: user?.fullName ?? '',
                phone: user?.phone ?? '',
                roleLabel: l10n.roleLabel('coordinator'),
                activeLabel: l10n.accountActive,
              ),
            ),
            const SizedBox(height: 20),
            SectionHeader(title: l10n.coordinatorOverview),
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: _loadingCargos
                  ? const AppCard(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _CoordinatorStat(
                            value: '$pending',
                            label: l10n.homePendingCargos,
                            icon: Icons.hourglass_top_rounded,
                            color: AppTheme.warning,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CoordinatorStat(
                            value: '$assigned',
                            label: l10n.homeInTransit,
                            icon: Icons.local_shipping_rounded,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CoordinatorStat(
                            value: '$completed',
                            label: l10n.completedCargos,
                            icon: Icons.task_alt_rounded,
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: AppCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        l10n.totalCargoValue,
                        style: TextStyle(
                          color: context.palette.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    PriceLabel(price: totalValue, fontSize: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            SectionHeader(title: l10n.transportTools),
            FadeSlideIn(
              delay: const Duration(milliseconds: 140),
              child: Row(
                children: [
                  Expanded(
                    child: _CoordinatorAction(
                      icon: Icons.add_box_rounded,
                      title: l10n.createNewCargo,
                      color: AppTheme.accent,
                      onTap: () => context.push('/coordinator/add-cargo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CoordinatorAction(
                      icon: Icons.inventory_2_rounded,
                      title: l10n.manageCargos,
                      color: AppTheme.primary,
                      onTap: () => context.push('/coordinator/cargos'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SectionHeader(title: l10n.accountInformation),
            FadeSlideIn(
              delay: const Duration(milliseconds: 180),
              child: AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ProfileTile(
                      icon: Icons.phone_rounded,
                      title: l10n.phoneNumber,
                      value: user?.phone ?? '',
                    ),
                    if (user?.nationalCode?.isNotEmpty == true) ...[
                      Divider(height: 1, color: context.palette.divider),
                      _ProfileTile(
                        icon: Icons.badge_rounded,
                        title: l10n.nationalCode,
                        value: user!.nationalCode!,
                      ),
                    ],
                    if (user?.email != null) ...[
                      Divider(height: 1, color: context.palette.divider),
                      _ProfileTile(
                        icon: Icons.email_rounded,
                        title: l10n.email,
                        value: user!.email!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoordinatorProfileHero extends StatelessWidget {
  const _CoordinatorProfileHero({
    required this.name,
    required this.phone,
    required this.roleLabel,
    required this.activeLabel,
  });

  final String name;
  final String phone;
  final String roleLabel;
  final String activeLabel;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: -36,
            top: -45,
            child: Icon(
              Icons.local_shipping_rounded,
              size: 150,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _ProfileBadge(
                          icon: Icons.business_center_rounded,
                          label: roleLabel,
                        ),
                        _ProfileBadge(
                          icon: Icons.verified_rounded,
                          label: activeLabel,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _CoordinatorStat extends StatelessWidget {
  const _CoordinatorStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
    child: Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 7),
        Text(
          value,
          style: TextStyle(
            color: context.palette.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.palette.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _CoordinatorAction extends StatelessWidget {
  const _CoordinatorAction({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          maxLines: 2,
          style: TextStyle(
            color: context.palette.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
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
