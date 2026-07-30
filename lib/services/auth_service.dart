import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api_config.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import 'api_client.dart';
import 'notification_service.dart';
import 'token_storage.dart';

/// Auth facade — mock today, JWT/Django tomorrow via [ApiConfig].
class AuthService extends ChangeNotifier {
  AuthService({
    TokenStorage? tokenStorage,
    ApiClient? apiClient,
  })  : _tokens = tokenStorage ?? TokenStorage(),
        _api = apiClient ?? ApiClient();

  final TokenStorage _tokens;
  final ApiClient _api;

  User? _currentUser;
  bool _isLoading = false;
  bool _restored = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get sessionRestored => _restored;

  Future<void> restoreSession() async {
    if (_restored) return;
    try {
      final json = await _tokens.readUserJson();
      if (json != null && json.isNotEmpty) {
        _currentUser = User.fromJson(jsonDecode(json) as Map<String, dynamic>);
      } else if (!ApiConfig.shouldUseMock) {
        final me = await _api.get(ApiConfig.mePath);
        _currentUser = User.fromJson(me);
        await _tokens.saveUserJson(jsonEncode(_currentUser!.toJson()));
      }
    } catch (_) {
      await _tokens.clear();
      _currentUser = null;
    } finally {
      _restored = true;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (ApiConfig.shouldUseMock) {
        await Future<void>.delayed(const Duration(milliseconds: 800));
        _currentUser = User(
          id: role == UserRole.driver ? 'driver-1' : 'coord-1',
          fullName: role == UserRole.driver ? 'علی محمدی' : 'رضا کریمی',
          phone: phone,
          role: role,
          vehicleInfo: role == UserRole.driver
              ? const VehicleInfo(
                  plateNumber: '۱۲ ب ۳۴۵ ایران ۶۶',
                  cargoType: 'کفی',
                  vehicleModel: 'ولوو FH460',
                  capacityTons: 24,
                )
              : null,
        );
        await _tokens.saveTokens(access: 'mock-access-token', refresh: 'mock-refresh');
      } else {
        final data = await _api.post(
          ApiConfig.loginPath,
          body: {
            'phone': phone,
            'password': password,
            'role': role.apiValue,
          },
        );
        final access = (data['access'] ?? data['token'] ?? '').toString();
        final refresh = data['refresh']?.toString();
        await _tokens.saveTokens(access: access, refresh: refresh);
        _currentUser = User.fromJson(
          (data['user'] as Map<String, dynamic>?) ?? data,
        );
      }

      await _tokens.saveUserJson(jsonEncode(_currentUser!.toJson()));
      await NotificationService().init();
      await NotificationService().registerWithBackend();
      return true;
    } catch (_) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signup({
    required String fullName,
    required String phone,
    required String password,
    required UserRole role,
    String? email,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (ApiConfig.shouldUseMock) {
        await Future<void>.delayed(const Duration(milliseconds: 1000));
        _currentUser = User(
          id: 'user-${DateTime.now().millisecondsSinceEpoch}',
          fullName: fullName,
          phone: phone,
          email: email,
          role: role,
        );
        await _tokens.saveTokens(access: 'mock-access-token', refresh: 'mock-refresh');
      } else {
        final data = await _api.post(
          ApiConfig.signupPath,
          body: {
            'full_name': fullName,
            'phone': phone,
            'password': password,
            'role': role.apiValue,
            if (email != null && email.isNotEmpty) 'email': email,
          },
        );
        final access = (data['access'] ?? data['token'] ?? '').toString();
        final refresh = data['refresh']?.toString();
        await _tokens.saveTokens(access: access, refresh: refresh);
        _currentUser = User.fromJson(
          (data['user'] as Map<String, dynamic>?) ?? data,
        );
      }

      await _tokens.saveUserJson(jsonEncode(_currentUser!.toJson()));
      await NotificationService().init();
      return true;
    } catch (_) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateVehicleInfo(VehicleInfo info) async {
    if (_currentUser == null) return;
    if (ApiConfig.shouldUseMock) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    } else {
      await _api.put(ApiConfig.vehiclePath, body: info.toJson());
    }
    _currentUser = _currentUser!.copyWith(vehicleInfo: info);
    await _tokens.saveUserJson(jsonEncode(_currentUser!.toJson()));
    notifyListeners();
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (ApiConfig.shouldUseMock) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      return currentPassword.isNotEmpty && newPassword.length >= 6;
    }
    await _api.post(
      ApiConfig.changePasswordPath,
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    await _tokens.clear();
    notifyListeners();
  }
}
