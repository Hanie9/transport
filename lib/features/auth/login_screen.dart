import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.driver;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    final success = await auth.login(
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
    );

    if (!mounted) return;

    if (success) {
      if (_selectedRole == UserRole.driver) {
        context.go('/driver');
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
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
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.local_shipping_rounded, size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.appName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.loginTitle,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.userType,
                        style: TextStyle(fontWeight: FontWeight.w700, color: palette.textPrimary),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: UserRole.values.map((role) {
                          final isSelected = _selectedRole == role;
                          final roleKey = role == UserRole.driver ? 'driver' : 'coordinator';
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
                                  borderRadius: BorderRadius.circular(16),
                                  child: Ink(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.primary.withValues(alpha: 0.1)
                                          : palette.cardBg,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppTheme.primary
                                            : palette.divider,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      boxShadow: isSelected ? null : palette.cardShadow,
                                    ),
                                    child: Text(
                                      l10n.roleLabel(roleKey),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isSelected ? AppTheme.primary : palette.textSecondary,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
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
                      const SizedBox(height: 16),
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
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return l10n.passwordRequired;
                          if (v.length < 6) return l10n.passwordMinLength;
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: auth.isLoading ? null : _login,
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(l10n.login),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.noAccount, style: TextStyle(color: palette.textSecondary)),
                          TextButton(
                            onPressed: () => context.go('/signup'),
                            child: Text(l10n.signup),
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
