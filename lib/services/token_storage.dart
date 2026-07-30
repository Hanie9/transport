import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists JWT access/refresh tokens for future Django auth.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'jwt_access';
  static const _refreshKey = 'jwt_refresh';
  static const _userJsonKey = 'cached_user_json';

  final FlutterSecureStorage _storage;

  Future<void> saveTokens({
    required String access,
    String? refresh,
  }) async {
    await _storage.write(key: _accessKey, value: access);
    if (refresh != null) {
      await _storage.write(key: _refreshKey, value: refresh);
    }
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  Future<void> saveUserJson(String json) =>
      _storage.write(key: _userJsonKey, value: json);

  Future<String?> readUserJson() => _storage.read(key: _userJsonKey);

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _userJsonKey);
  }

  Future<bool> hasSession() async {
    final token = await readAccessToken();
    final user = await readUserJson();
    return (token != null && token.isNotEmpty) ||
        (user != null && user.isNotEmpty);
  }
}
