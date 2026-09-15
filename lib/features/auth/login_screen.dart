import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/scale_tap.dart';
import '../../l10n/api_messages.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_auth_service.dart';
import '../../services/settings_service.dart';
import 'widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _biometric = BiometricAuthService();

  UserRole _selectedRole = UserRole.driver;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _authAvailable = false;
  bool _hasStoredCredentials = false;
  bool _biometricLoading = false;
  bool _autoPrompted = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthService>();
    final isEnglish = context.read<SettingsService>().isEnglish;
    final sessionExpired = auth.sessionExpiredNotice;

    await Future.wait([_loadRememberedPhone(), _initBiometricState()]);

    if (!mounted) return;
    if (sessionExpired) {
      setState(() {
        _error = ApiMessages.sessionExpired(isEnglish: isEnglish);
      });
    }
    _maybeAutoPromptBiometric();
  }

  Future<void> _loadRememberedPhone() async {
    final phone = await _biometric.loadRememberedPhone();
    if (!mounted || phone == null) return;
    setState(() {
      _phoneController.text = phone;
      _rememberMe = true;
    });
  }

  Future<void> _initBiometricState() async {
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _authAvailable = false;
          _hasStoredCredentials = false;
        });
      }
      return;
    }

    final available = await _biometric.isDeviceAuthAvailable();
    final hasCreds = await _biometric.hasStoredCredentials();
    if (!mounted) return;
    setState(() {
      _authAvailable = available;
      _hasStoredCredentials = hasCreds;
    });
  }

  void _maybeAutoPromptBiometric() {
    if (_autoPrompted || !_authAvailable || !_hasStoredCredentials) return;
    _autoPrompted = true;
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_biometricLoading || _biometric.isAuthInProgress) return;
      if (!_authAvailable || !_hasStoredCredentials) return;
      _tryBiometricLogin();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  BiometricAuthMessages _messages(AppLocalizations l10n) {
    return BiometricAuthMessages(
      reason: l10n.loginAuthReason,
      signInTitle: l10n.loginAccountTitle,
      cancelButton: l10n.cancel,
      biometricHint: l10n.loginBiometricHint,
      biometricNotRecognized: l10n.loginBiometricNotRecognized,
      biometricRequiredTitle: l10n.loginBiometricRequired,
      deviceCredentialsRequiredTitle: l10n.loginDeviceLockRequired,
      deviceCredentialsSetupDescription: l10n.loginEnableDeviceLock,
      goToSettingsButton: l10n.loginGoToSettings,
      goToSettingsDescription: l10n.loginEnableDeviceLock,
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _error = '');

    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final auth = context.read<AuthService>();
    final success = await auth.login(
      phone: phone,
      password: password,
      role: _selectedRole,
    );

    if (!mounted) return;

    if (!success) {
      setState(
        () => _error = auth.lastError ?? context.l10n.loginFingerprintError,
      );
      return;
    }

    try {
      await _biometric.saveCredentials(
        phone: phone,
        password: password,
        role: _selectedRole,
      );
      if (_rememberMe) {
        await _biometric.saveRememberedPhone(phone);
      } else {
        await _biometric.clearRememberedPhone();
      }
      if (mounted) setState(() => _hasStoredCredentials = true);
    } catch (_) {}

    if (!mounted) return;
    _goHome(_selectedRole);
  }

  void _goHome(UserRole role) {
    if (role == UserRole.driver) {
      context.go('/driver');
    } else {
      context.go('/coordinator');
    }
  }

  Future<void> _tryBiometricLogin() async {
    if (_biometricLoading || _biometric.isAuthInProgress) return;

    final l10n = context.l10n;
    final available = await _biometric.isDeviceAuthAvailable();
    if (!available) {
      setState(() => _error = l10n.loginNoAuthentication);
      return;
    }

    final creds = await _biometric.readStoredCredentials();
    if (creds == null) {
      setState(() => _error = l10n.loginNeedPasswordFirst);
      return;
    }

    setState(() {
      _biometricLoading = true;
      _error = '';
    });

    try {
      final didAuth = await _biometric.authenticate(messages: _messages(l10n));
      if (!didAuth || !mounted) return;

      _phoneController.text = creds.phone;
      _passwordController.text = creds.password;
      setState(() {
        _selectedRole = creds.role;
        _biometricLoading = false;
      });

      final auth = context.read<AuthService>();
      final success = await auth.login(
        phone: creds.phone,
        password: creds.password,
        role: creds.role,
      );
      if (!mounted) return;
      if (success) {
        _goHome(creds.role);
      } else {
        setState(() => _error = auth.lastError ?? l10n.loginFingerprintError);
      }
    } on PlatformException catch (e) {
      if (e.code == 'auth_in_progress') return;
      setState(() => _error = _mapBiometricError(e.code, l10n));
    } catch (_) {
      if (mounted) setState(() => _error = l10n.loginFingerprintError);
    } finally {
      if (mounted) setState(() => _biometricLoading = false);
    }
  }

  String _mapBiometricError(String code, AppLocalizations l10n) {
    switch (code) {
      case 'NotAvailable':
        return l10n.loginFingerprintNotAvailable;
      case 'NotEnrolled':
        return l10n.loginFingerprintNotEnrolled;
      case 'PasscodeNotSet':
        return l10n.loginFingerprintNotSet;
      case 'LockedOut':
        return l10n.loginFingerprintLockedOut;
      case 'PermanentlyLockedOut':
        return l10n.loginFingerprintPermanentlyLockedOut;
      default:
        return '${l10n.loginFingerprintError}: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final auth = context.watch<AuthService>();
    final busy = auth.isLoading || _biometricLoading;

    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeroHeader(title: l10n.appName, subtitle: l10n.loginTitle),
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
                          title: l10n.loginAccountTitle,
                          child: Column(
                            children: [
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
                                  if (v.trim().length < 11) {
                                    return l10n.phoneInvalid;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                enabled: !busy,
                                onFieldSubmitted: (_) => busy ? null : _login(),
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
                                      () =>
                                          _obscurePassword = !_obscurePassword,
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
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: busy
                                          ? null
                                          : (v) => setState(
                                              () => _rememberMe = v ?? false,
                                            ),
                                      activeColor: AppTheme.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: busy
                                        ? null
                                        : () => setState(
                                            () => _rememberMe = !_rememberMe,
                                          ),
                                    child: Text(
                                      l10n.rememberMe,
                                      style: TextStyle(
                                        color: palette.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      AuthFormSection(
                        delay: const Duration(milliseconds: 140),
                        child: SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: busy ? null : _login,
                            child: auth.isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(l10n.login),
                          ),
                        ),
                      ),
                      if (_authAvailable) ...[
                        const SizedBox(height: 24),
                        AuthFormSection(
                          delay: const Duration(milliseconds: 180),
                          child: Center(
                            child: Column(
                              children: [
                                ScaleTap(
                                  enabled: !busy && _hasStoredCredentials,
                                  onTap: _tryBiometricLogin,
                                  borderRadius: BorderRadius.circular(36),
                                  child: Opacity(
                                    opacity: (busy || !_hasStoredCredentials)
                                        ? 0.45
                                        : 1,
                                    child: Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            AppTheme.primary.withValues(
                                              alpha: 0.18,
                                            ),
                                            AppTheme.primaryLight.withValues(
                                              alpha: 0.06,
                                            ),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: AppTheme.primaryLight,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primary.withValues(
                                              alpha: 0.18,
                                            ),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: _biometricLoading
                                          ? const SizedBox(
                                              width: 26,
                                              height: 26,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                color: AppTheme.primary,
                                              ),
                                            )
                                          : Icon(
                                              Icons.fingerprint_rounded,
                                              size: 38,
                                              color:
                                                  Theme.of(
                                                        context,
                                                      ).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : AppTheme.primary,
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _hasStoredCredentials
                                      ? l10n.loginBiometric
                                      : l10n.loginLoginFirst,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white70
                                        : AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (_error.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        AuthFormSection(
                          delay: const Duration(milliseconds: 200),
                          child: AuthErrorBanner(message: _error),
                        ),
                      ],
                      const SizedBox(height: 16),
                      AuthFormSection(
                        delay: const Duration(milliseconds: 220),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.noAccount,
                              style: TextStyle(color: palette.textSecondary),
                            ),
                            TextButton(
                              onPressed: busy
                                  ? null
                                  : () => context.go('/signup'),
                              child: Text(l10n.signup),
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
