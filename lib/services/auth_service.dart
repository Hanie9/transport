import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api_config.dart';
import '../core/models/iranian_plate.dart';
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

/// Auth facade — JWT against the configured Transport API (or mock).
class AuthService extends ChangeNotifier {
  AuthService({TokenStorage? tokenStorage, ApiClient? apiClient})
    : _tokens = tokenStorage ?? TokenStorage(),
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

  /// Refreshes user from the documented profile endpoint.
  Future<bool> refreshProfile() => _tryRefreshProfile();

  Future<bool> _tryRefreshProfile() async {
    if (ApiConfig.shouldUseMock) return true;
    _clearError();
    try {
      final me = await _api.get(ApiConfig.profilePath);
      final userJson = me.containsKey('user') && me['user'] is Map
          ? Map<String, dynamic>.from(me['user'] as Map)
          : ApiResponse.extractObject(me);
      _currentUser = _mergeServerUser(User.fromJson(userJson));
      await _tokens.saveUserJson(jsonEncode(_currentUser!.toJson()));
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
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
          await _tryRefreshProfile();
        } else {
          await _tokens.clear();
          _currentUser = null;
        }
      }

      if (_currentUser != null) {
        await SessionService().clearBackgroundMarker();
      }
    } catch (e) {
      _setError(e);
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
                )
              : null,
        );
        await _tokens.saveTokens(
          access: 'mock-access-token',
          refresh: 'mock-refresh',
        );
      } else {
        final data = await _api.post(
          ApiConfig.loginPath,
          body: {
            'phone_number': normalizeIranPhone(phone),
            'password': password,
          },
        );

        final userMap = data['user'];
        if (userMap is! Map) {
          throw ApiException(
            ApiMessages.loginTokenMissing(isEnglish: _isEnglish),
          );
        }
        final userJson = Map<String, dynamic>.from(userMap);
        if (!UserRole.matchesApiUser(userJson, role)) {
          throw ApiException(
            ApiMessages.roleMismatch(isEnglish: _isEnglish, role: role),
          );
        }

        final tokens = data['tokens'];
        String access = '';
        String? refresh;
        if (tokens is Map) {
          access = (tokens['access'] ?? '').toString();
          refresh = tokens['refresh']?.toString();
        }
        access = access.isNotEmpty
            ? access
            : (data['access'] ?? data['token'] ?? '').toString();
        refresh ??= data['refresh']?.toString();
        if (access.isEmpty) {
          throw ApiException(
            ApiMessages.loginTokenMissing(isEnglish: _isEnglish),
          );
        }
        await _tokens.saveTokens(access: access, refresh: refresh);

        _currentUser = User.fromJson(userJson);
      }

      await _tokens.saveUserJson(jsonEncode(_currentUser!.toJson()));
      if (!ApiConfig.shouldUseMock) {
        await _tryRefreshProfile();
      }
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
    String? passwordConfirm,
    int? machineId,
    int? ostanId,
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
        await _tokens.saveTokens(
          access: 'mock-access-token',
          refresh: 'mock-refresh',
        );
      } else {
        final names = _splitName(fullName);
        await _api.post(
          ApiConfig.registerPath,
          body: {
            'first_name': names.$1,
            'last_name': names.$2,
            'phone_number': normalizeIranPhone(phone),
            'password': password,
            'password_confirm': passwordConfirm ?? password,
            'user_type': role == UserRole.driver ? 'driver' : 'operator',
            if (role == UserRole.driver && machineId != null)
              'machine_id': machineId,
            if (role == UserRole.driver && ostanId != null) 'ostan_id': ostanId,
          },
        );
        // The registration response has no JWT; log in with the new account.
        return login(phone: phone, password: password, role: role);
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

  Future<bool> updateVehicleInfo(VehicleInfo info) async {
    if (_currentUser == null) return false;
    _clearError();
    if (ApiConfig.shouldUseMock) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    } else {
      if (info.machineId == null) {
        _lastError = ApiMessages.featureUnavailable(isEnglish: _isEnglish);
        notifyListeners();
        return false;
      }
      try {
        final response = await _api.put(
          ApiConfig.profilePath,
          body: {
            'machine_id': info.machineId,
            'ostan_id': info.ostanId,
            'pelak':
                IranianPlateData.parse(info.plateNumber)?.toApiString() ??
                info.plateNumber.trim(),
            'model': info.vehicleModel.trim(),
          },
        );
        final serverUser = User.fromJson(ApiResponse.extractObject(response));
        _currentUser = _mergeServerUser(serverUser, localVehicle: info);
        await _tokens.saveUserJson(jsonEncode(_currentUser!.toJson()));
        notifyListeners();
        return true;
      } catch (e) {
        _setError(e);
        notifyListeners();
        return false;
      }
    }
    _currentUser = _currentUser!.copyWith(vehicleInfo: info);
    await _tokens.saveUserJson(jsonEncode(_currentUser!.toJson()));
    notifyListeners();
    return true;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    String? newPasswordConfirm,
  }) async {
    _clearError();
    if (ApiConfig.shouldUseMock) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (currentPassword.isEmpty ||
          newPassword.length < 8 ||
          (newPasswordConfirm ?? newPassword) != newPassword) {
        _lastError = ApiMessages.invalidPassword(isEnglish: _isEnglish);
        return false;
      }
      return true;
    }
    try {
      await _api.post(
        ApiConfig.changePasswordPath,
        body: {
          'old_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirm': newPasswordConfirm ?? newPassword,
        },
      );
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    String? nationalCode,
    int? machineId,
    int? ostanId,
  }) async {
    _clearError();
    if (_currentUser == null) return false;
    if (ApiConfig.shouldUseMock) {
      _currentUser = _currentUser!.copyWith(
        fullName: fullName,
        nationalCode: nationalCode,
      );
      await _tokens.saveUserJson(jsonEncode(_currentUser!.toJson()));
      notifyListeners();
      return true;
    }

    try {
      final names = _splitName(fullName);
      final response = await _api.put(
        ApiConfig.profilePath,
        body: {
          'first_name': names.$1,
          'last_name': names.$2,
          if (nationalCode != null)
            'national_code': nationalCode.trim().isEmpty
                ? null
                : nationalCode.trim(),
          if (_currentUser!.role == UserRole.driver) ...{
            'machine_id': ?machineId,
            'ostan_id': ?ostanId,
          },
        },
      );
      _currentUser = _mergeServerUser(
        User.fromJson(ApiResponse.extractObject(response)),
      );
      await _tokens.saveUserJson(jsonEncode(_currentUser!.toJson()));
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  (String, String) _splitName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return ('', '');
    return (parts.first, parts.skip(1).join(' '));
  }

  User _mergeServerUser(User server, {VehicleInfo? localVehicle}) {
    final current = _currentUser;
    final local = localVehicle ?? current?.vehicleInfo;
    final remote = server.vehicleInfo;
    VehicleInfo? vehicle;
    if (local != null || remote != null) {
      vehicle = VehicleInfo(
        plateNumber: remote?.plateNumber ?? local?.plateNumber ?? '',
        cargoType: remote?.cargoType.isNotEmpty == true
            ? remote!.cargoType
            : (local?.cargoType ?? ''),
        vehicleModel: remote?.vehicleModel ?? local?.vehicleModel ?? '',
        machineId: remote?.machineId ?? local?.machineId,
        ostanId: remote != null ? remote.ostanId : local?.ostanId,
        ostanName: remote != null ? remote.ostanName : local?.ostanName,
      );
    }
    return server.copyWith(
      phone: server.phone.isEmpty ? current?.phone : null,
      fullName: server.fullName.isEmpty ? current?.fullName : null,
      vehicleInfo: vehicle,
    );
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
