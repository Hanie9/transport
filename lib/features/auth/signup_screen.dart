import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  UserRole _selectedRole = UserRole.driver;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    final success = await auth.signup(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      if (_selectedRole == UserRole.driver) {
        context.go('/driver/profile?editVehicle=1');
      } else {
        context.go('/coordinator');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SignupHeader(
                title: l10n.createAccount,
                subtitle: l10n.signupInApp(l10n.appName),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionCard(
                        title: l10n.userType,
                        child: Row(
                          children: UserRole.values.map((role) {
                            final isSelected = _selectedRole == role;
                            final roleKey = role == UserRole.driver ? 'driver' : 'coordinator';
                            final icon = role == UserRole.driver
                                ? Icons.local_shipping_outlined
                                : Icons.business_center_outlined;
                            final hint = role == UserRole.driver
                                ? l10n.driverSignupHint
                                : l10n.coordinatorSignupHint;

                            return Expanded(
                              child: Padding(
                                padding: EdgeInsetsDirectional.only(
                                  start: role == UserRole.driver ? 0 : 6,
                                  end: role == UserRole.coordinator ? 0 : 6,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => setState(() => _selectedRole = role),
                                    borderRadius: BorderRadius.circular(18),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        gradient: isSelected ? AppTheme.primaryGradient : null,
                                        color: isSelected ? null : palette.cardBg,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.transparent
                                              : palette.divider,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: AppTheme.primary.withValues(alpha: 0.28),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ]
                                            : palette.cardShadow,
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            icon,
                                            color: isSelected ? Colors.white : palette.textSecondary,
                                            size: 26,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            l10n.roleLabel(roleKey),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                              color: isSelected ? Colors.white : palette.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            hint,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              height: 1.3,
                                              color: isSelected
                                                  ? Colors.white.withValues(alpha: 0.85)
                                                  : palette.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: l10n.personalInfo,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: l10n.fullName,
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                              validator: (v) =>
                                  v == null || v.trim().isEmpty ? l10n.nameRequired : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textDirection: TextDirection.ltr,
                              decoration: InputDecoration(
                                labelText: l10n.phoneNumber,
                                prefixIcon: const Icon(Icons.phone_outlined),
                                hintText: '09123456789',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return l10n.phoneRequired;
                                if (v.trim().length < 11) return l10n.phoneInvalid;
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textDirection: TextDirection.ltr,
                              decoration: InputDecoration(
                                labelText: l10n.emailOptional,
                                prefixIcon: const Icon(Icons.email_outlined),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: l10n.securityInfo,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: l10n.password,
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return l10n.passwordRequired;
                                if (v.length < 6) return l10n.passwordMinLength;
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirm,
                              decoration: InputDecoration(
                                labelText: l10n.confirmPassword,
                                prefixIcon: const Icon(Icons.lock_reset_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                              validator: (v) {
                                if (v != _passwordController.text) return l10n.passwordsMismatch;
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _signup,
                          child: auth.isLoading
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
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.haveAccount, style: TextStyle(color: palette.textSecondary)),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: Text(l10n.login),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignupHeader extends StatelessWidget {
  const _SignupHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 24, 20, 28),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: palette.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
