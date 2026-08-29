import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api_config.dart';
import '../l10n/api_messages.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import '../utils/phone_utils.dart';
import 'api_client.dart';
import 'api_response.dart';
import 'notification_service.dart';
import 'session_service.dart';
import 'settings_service.dart';
import 'token_storage.dart';

/// Auth facade — JWT against transport.liara.run (or mock when enabled).
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
  bool _sessionExpired = false;
  String? _lastError;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get sessionRestored => _restored;
  bool get sessionExpiredNotice => _sessionExpired;
  String? get lastError => _lastError;

  bool get _isEnglish => SettingsService().isEnglish;

  void _clearError() => _lastError = null;

  void _setError(Object error) {
    if (error is ApiException) {
      _lastError = error.message;
      return;
    }

    final text = error.toString();
    if (text.contains('SocketException') ||
        text.contains('Failed host lookup') ||
        text.contains('Network is unreachable') ||
        text.contains('Connection refused')) {
      _lastError = ApiMessages.noInternet(isEnglish: _isEnglish);
      return;
    }

    if (error is FormatException) {
      _lastError = ApiMessages.invalidServerResponse(isEnglish: _isEnglish);
      return;
    }

    _lastError = ApiResponse.httpErrorMessage(
      rawBody: text,
      isEnglish: _isEnglish,
    );
  }

  Future<User?> _fetchMe() async {
    final me = await _api.get(ApiConfig.mePath);
    final user = User.fromJson(me);
    _currentUser = user;
    await _tokens.saveUserJson(jsonEncode(user.toJson()));
    return user;
  }

  Future<void> restoreSession() async {
    if (_restored) return;
    _clearError();

    if (await SessionService().shouldRequireLogin()) {
      await _tokens.clear();
      _currentUser = null;
      _sessionExpired = true;
      _restored = true;
      notifyListeners();
      return;
    }

    try {
      final json = await _tokens.readUserJson();
      if (json != null && json.isNotEmpty) {
        _currentUser = User.fromJson(jsonDecode(json) as Map<String, dynamic>);
      }

      if (!ApiConfig.shouldUseMock) {
        final token = await _tokens.readAccessToken();
        if (token != null && token.isNotEmpty) {
          await _fetchMe();
        } else {
          await _tokens.clear();
          _currentUser = null;
        }
      }

      if (_currentUser != null) {
        await SessionService().clearBackgroundMarker();
      }
    } catch (_) {
      await _tokens.clear();
      _currentUser = null;
    } finally {
      _restored = true;
      notifyListeners();
    }
  }

  Future<void> expireSession() async {
    _currentUser = null;
    _sessionExpired = true;
    _clearError();
    await _tokens.clear();
    notifyListeners();
  }

  Future<bool> login({
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    _isLoading = true;
    _clearError();
    _sessionExpired = false;
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
            'phone': normalizeIranPhone(phone),
            'password': password,
            'role': role.apiValue,
          },
        );
        final access = (data['access'] ?? data['token'] ?? '').toString();
        if (access.isEmpty) {
          throw ApiException(
            ApiMessages.loginTokenMissing(isEnglish: _isEnglish),
          );
        }
        final refresh = data['refresh']?.toString();
        await _tokens.saveTokens(access: access, refresh: refresh);

        if (data['user'] is Map) {
          _currentUser = User.fromJson(
            Map<String, dynamic>.from(data['user'] as Map),
          );
        } else {
          await _fetchMe();
        }
      }

      await _tokens.saveUserJson(jsonEncode(_currentUser!.toJson()));
      await SessionService().clearBackgroundMarker();
      await NotificationService().init();
      await NotificationService().registerWithBackend();
      return true;
    } catch (e) {
      _setError(e);
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
    _clearError();
    _sessionExpired = false;
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
            'phone': normalizeIranPhone(phone),
            'password': password,
            'role': role.apiValue,
            if (email != null && email.isNotEmpty) 'email': email,
          },
        );

        final access = (data['access'] ?? data['token'] ?? '').toString();
        if (access.isNotEmpty) {
          final refresh = data['refresh']?.toString();
          await _tokens.saveTokens(access: access, refresh: refresh);
          if (data['user'] is Map) {
            _currentUser = User.fromJson(
              Map<String, dynamic>.from(data['user'] as Map),
            );
          } else {
            await _fetchMe();
          }
        } else {
          // Some backends only create the user — log in right after signup.
          return login(
            phone: normalizeIranPhone(phone),
            password: password,
            role: role,
          );
        }
      }

      await _tokens.saveUserJson(jsonEncode(_currentUser!.toJson()));
      await SessionService().clearBackgroundMarker();
      await NotificationService().init();
      await NotificationService().registerWithBackend();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateVehicleInfo(VehicleInfo info) async {
    if (_currentUser == null) return;
    _clearError();
    if (ApiConfig.shouldUseMock) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _currentUser = _currentUser!.copyWith(vehicleInfo: info);
    } else {
      final data = await _api.put(ApiConfig.vehiclePath, body: info.toJson());
      final updated = data.isNotEmpty && data.containsKey('plate_number')
          ? VehicleInfo.fromJson(data)
          : info;
      _currentUser = _currentUser!.copyWith(vehicleInfo: updated);
    }
    await _tokens.saveUserJson(jsonEncode(_currentUser!.toJson()));
    notifyListeners();
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _clearError();
    if (ApiConfig.shouldUseMock) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (currentPassword.isEmpty || newPassword.length < 6) {
        _lastError = ApiMessages.invalidPassword(isEnglish: _isEnglish);
        return false;
      }
      return true;
    }
    try {
      await _api.post(
        ApiConfig.changePasswordPath,
        body: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  Future<void> logout() async {
    if (!ApiConfig.shouldUseMock) {
      try {
        final refresh = await _tokens.readRefreshToken();
        await _api.post(
          ApiConfig.logoutPath,
          body: refresh == null ? null : {'refresh': refresh},
        );
      } catch (_) {
        // Clear local session even if remote logout fails.
      }
    }
    _currentUser = null;
    _sessionExpired = false;
    _clearError();
    await _tokens.clear();
    await SessionService().clearBackgroundMarker();
    notifyListeners();
  }
}
