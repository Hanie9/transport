import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_role.dart';

class StoredCredentials {
  const StoredCredentials({
    required this.phone,
    required this.password,
    required this.role,
  });

  final String phone;
  final String password;
  final UserRole role;
}

class BiometricAuthMessages {
  const BiometricAuthMessages({
    required this.reason,
    required this.signInTitle,
    required this.cancelButton,
    required this.biometricHint,
    required this.biometricNotRecognized,
    required this.biometricRequiredTitle,
    required this.deviceCredentialsRequiredTitle,
    required this.deviceCredentialsSetupDescription,
    required this.goToSettingsButton,
    required this.goToSettingsDescription,
  });

  final String reason;
  final String signInTitle;
  final String cancelButton;
  final String biometricHint;
  final String biometricNotRecognized;
  final String biometricRequiredTitle;
  final String deviceCredentialsRequiredTitle;
  final String deviceCredentialsSetupDescription;
  final String goToSettingsButton;
  final String goToSettingsDescription;
}

/// Handles device biometrics / PIN / pattern and secure credential storage.
class BiometricAuthService {
  BiometricAuthService._();
  static final BiometricAuthService instance = BiometricAuthService._();
  factory BiometricAuthService() => instance;

  static const _phoneKey = 'bio_phone';
  static const _passwordKey = 'bio_password';
  static const _roleKey = 'bio_role';
  static const _rememberPhoneKey = 'saved_phone';

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _authInProgress = false;

  Future<bool> isDeviceAuthAvailable() async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> canCheckBiometrics() async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasStoredCredentials() async {
    final creds = await readStoredCredentials();
    return creds != null;
  }

  Future<StoredCredentials?> readStoredCredentials() async {
    try {
      final phone = await _secureStorage.read(key: _phoneKey);
      final password = await _secureStorage.read(key: _passwordKey);
      final roleName = await _secureStorage.read(key: _roleKey);
      if (phone == null ||
          phone.isEmpty ||
          password == null ||
          password.isEmpty ||
          roleName == null ||
          roleName.isEmpty) {
        return null;
      }
      final role = roleName == UserRole.coordinator.name
          ? UserRole.coordinator
          : UserRole.driver;
      return StoredCredentials(phone: phone, password: password, role: role);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCredentials({
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    await _secureStorage.write(key: _phoneKey, value: phone);
    await _secureStorage.write(key: _passwordKey, value: password);
    await _secureStorage.write(key: _roleKey, value: role.name);
  }

  Future<void> clearCredentials() async {
    await _secureStorage.delete(key: _phoneKey);
    await _secureStorage.delete(key: _passwordKey);
    await _secureStorage.delete(key: _roleKey);
  }

  Future<void> saveRememberedPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rememberPhoneKey, phone);
  }

  Future<void> clearRememberedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberPhoneKey);
  }

  Future<String?> loadRememberedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(_rememberPhoneKey);
    if (phone == null || phone.isEmpty) return null;
    return phone;
  }

  /// Returns `true` if the user authenticated successfully.
  /// Throws [PlatformException] on biometric system errors.
  Future<bool> authenticate({
    required BiometricAuthMessages messages,
  }) async {
    if (_authInProgress) {
      throw PlatformException(code: 'auth_in_progress');
    }

    final isSupported = await _localAuth.isDeviceSupported();
    if (!isSupported) return false;

    _authInProgress = true;
    try {
      return await _localAuth.authenticate(
        localizedReason: messages.reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
        authMessages: [
          AndroidAuthMessages(
            signInTitle: messages.signInTitle,
            cancelButton: messages.cancelButton,
            biometricHint: messages.biometricHint,
            biometricNotRecognized: messages.biometricNotRecognized,
            biometricRequiredTitle: messages.biometricRequiredTitle,
            deviceCredentialsRequiredTitle: messages.deviceCredentialsRequiredTitle,
            deviceCredentialsSetupDescription: messages.deviceCredentialsSetupDescription,
            goToSettingsButton: messages.goToSettingsButton,
            goToSettingsDescription: messages.goToSettingsDescription,
          ),
        ],
      );
    } finally {
      _authInProgress = false;
    }
  }

  bool get isAuthInProgress => _authInProgress;
}
