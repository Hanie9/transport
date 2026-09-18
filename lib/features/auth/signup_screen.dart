import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/modern_dropdown.dart';
import '../../l10n/app_localizations.dart';
import '../../models/api_reference_item.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import '../../services/settings_service.dart';
import '../../services/reference_data_service.dart';
import '../../utils/phone_utils.dart';
import 'widgets/auth_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referenceData = ReferenceDataService();
  List<ApiReferenceItem> _machines = const [];
  List<ApiReferenceItem> _ostans = const [];
  int? _machineId;
  int? _ostanId;
  bool _loadingReferences = false;
  bool _referenceLoadFailed = false;
  UserRole _selectedRole = UserRole.driver;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    if (!ApiConfig.shouldUseMock) _loadReferences();
  }

  Future<void> _loadReferences() async {
    setState(() {
      _loadingReferences = true;
      _referenceLoadFailed = false;
    });
    try {
      final lists = await Future.wait([
        _referenceData.getMachines(),
        _referenceData.getOstans(),
      ]);
      if (!mounted) return;
      setState(() {
        _machines = lists[0];
        _ostans = lists[1];
        _referenceLoadFailed = _machines.isEmpty || _ostans.isEmpty;
        _loadingReferences = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _referenceLoadFailed = true;
        _loadingReferences = false;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _error = '');

    final auth = context.read<AuthService>();
    final success = await auth.signup(
      fullName:
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      passwordConfirm: _confirmPasswordController.text,
      machineId: _selectedRole == UserRole.driver ? _machineId : null,
      ostanId: _selectedRole == UserRole.driver ? _ostanId : null,
    );

    if (!mounted) return;

    if (success) {
      await context.read<SettingsService>().setPreferredRole(_selectedRole);
      if (!mounted) return;
      if (_selectedRole == UserRole.driver) {
        context.go('/driver/profile?editVehicle=1');
      } else {
        context.go('/coordinator');
      }
    } else {
      setState(
        () => _error = auth.lastError ?? context.l10n.loginFingerprintError,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final auth = context.watch<AuthService>();
    final busy = auth.isLoading;

    return Scaffold(
      backgroundColor: palette.surface,
      body: AuthPageLayout(
        children: [
          AuthHeroHeader(
            title: l10n.createAccount,
            subtitle: l10n.signupInApp(l10n.appName),
            showBack: true,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.sizeOf(context).width < 360 ? 12 : 20,
              24,
              MediaQuery.sizeOf(context).width < 360 ? 12 : 20,
              32,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthFormSection(
                    child: AuthSectionCard(
                      title: l10n.userType,
                      child: AuthRoleSelector(
                        selectedRole: _selectedRole,
                        onRoleChanged: (role) =>
                            setState(() => _selectedRole = role),
                        enabled: !busy,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AuthFormSection(
                    delay: const Duration(milliseconds: 80),
                    child: AuthSectionCard(
                      title: l10n.personalInfo,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _firstNameController,
                            textCapitalization: TextCapitalization.words,
                            enabled: !busy,
                            decoration: InputDecoration(
                              labelText: l10n.firstName,
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? l10n.firstNameRequired
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _lastNameController,
                            textCapitalization: TextCapitalization.words,
                            enabled: !busy,
                            decoration: InputDecoration(
                              labelText: l10n.lastName,
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                              ),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? l10n.lastNameRequired
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textDirection: TextDirection.ltr,
                            enabled: !busy,
                            decoration: InputDecoration(
                              labelText: l10n.phoneNumber,
                              prefixIcon: const Icon(Icons.phone_outlined),
                              hintText: '09123456789',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return l10n.phoneRequired;
                              }
                              if (!RegExp(
                                r'^09\d{9}$',
                              ).hasMatch(normalizeIranPhone(v))) {
                                return l10n.phoneInvalid;
                              }
                              return null;
                            },
                          ),
                          if (ApiConfig.shouldUseMock) ...[
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textDirection: TextDirection.ltr,
                              enabled: !busy,
                              decoration: InputDecoration(
                                labelText: l10n.emailOptional,
                                prefixIcon: const Icon(Icons.email_outlined),
                              ),
                            ),
                          ],
                          if (!ApiConfig.shouldUseMock &&
                              _selectedRole == UserRole.driver) ...[
                            const SizedBox(height: 14),
                            Text(
                              l10n.signupDriverMachineIdHint,
                              style: TextStyle(
                                fontSize: 12,
                                color: palette.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_loadingReferences) ...[
                              const LinearProgressIndicator(),
                              const SizedBox(height: 10),
                              Text(l10n.loading),
                            ],
                            if (_referenceLoadFailed)
                              TextButton.icon(
                                onPressed: busy ? null : _loadReferences,
                                icon: const Icon(Icons.refresh),
                                label: Text(l10n.signupReferencesRetry),
                              ),
                            ModernDropdownField<int>(
                              label: l10n.selectMachineType,
                              value: _machineId,
                              prefixIcon: Icons.local_shipping_outlined,
                              enabled:
                                  !busy &&
                                  !_loadingReferences &&
                                  _machines.isNotEmpty,
                              items: _machines
                                  .map(
                                    (item) => ModernDropdownField.item(
                                      item.id,
                                      item.name,
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _machineId = value),
                              validator: (value) =>
                                  value == null ? l10n.selectMachineType : null,
                            ),
                            const SizedBox(height: 14),
                            ModernDropdownField<int>(
                              label: l10n.provinceOptional,
                              value: _ostanId,
                              prefixIcon: Icons.location_on_outlined,
                              enabled:
                                  !busy &&
                                  !_loadingReferences &&
                                  _ostans.isNotEmpty,
                              items: [
                                ModernDropdownField.item(
                                  0,
                                  l10n.provinceNotSelected,
                                ),
                                ..._ostans.map(
                                  (item) => ModernDropdownField.item(
                                    item.id,
                                    item.name,
                                  ),
                                ),
                              ],
                              onChanged: (value) => setState(
                                () => _ostanId = value == 0 ? null : value,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AuthFormSection(
                    delay: const Duration(milliseconds: 140),
                    child: AuthSectionCard(
                      title: l10n.securityInfo,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            enabled: !busy,
                            decoration: InputDecoration(
                              labelText: l10n.password,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return l10n.passwordRequired;
                              }
                              if (v.length < 8) {
                                return l10n.passwordMinLength;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            enabled: !busy,
                            decoration: InputDecoration(
                              labelText: l10n.confirmPassword,
                              prefixIcon: const Icon(Icons.lock_reset_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v != _passwordController.text) {
                                return l10n.passwordsMismatch;
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    AuthFormSection(
                      delay: const Duration(milliseconds: 180),
                      child: AuthErrorBanner(message: _error),
                    ),
                  ],
                  const SizedBox(height: 28),
                  AuthFormSection(
                    delay: const Duration(milliseconds: 200),
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: busy ? null : _signup,
                        child: busy
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(l10n.signup),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AuthFormSection(
                    delay: const Duration(milliseconds: 220),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          l10n.haveAccount,
                          style: TextStyle(color: palette.textSecondary),
                        ),
                        TextButton(
                          onPressed: busy ? null : () => context.go('/login'),
                          child: Text(l10n.login),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
