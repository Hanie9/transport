import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import 'widgets/auth_widgets.dart';

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
  String _error = '';

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

    setState(() => _error = '');

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
    } else {
      setState(() => _error = auth.lastError ?? context.l10n.loginFingerprintError);
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
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeroHeader(
                title: l10n.createAccount,
                subtitle: l10n.signupInApp(l10n.appName),
                showBack: true,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
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
                            onRoleChanged: (role) => setState(() => _selectedRole = role),
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
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                enabled: !busy,
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
                                enabled: !busy,
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
                                enabled: !busy,
                                decoration: InputDecoration(
                                  labelText: l10n.emailOptional,
                                  prefixIcon: const Icon(Icons.email_outlined),
                                ),
                              ),
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
                                enabled: !busy,
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(l10n.haveAccount, style: TextStyle(color: palette.textSecondary)),
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
        ),
      ),
    );
  }
}
