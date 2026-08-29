import 'package:legestic/services/token_storage.dart';

/// In-memory token storage for unit/integration tests (no platform channels).
class FakeTokenStorage extends TokenStorage {
  FakeTokenStorage();

  String? _access;
  String? _refresh;
  String? _userJson;

  @override
  Future<void> saveTokens({required String access, String? refresh}) async {
    _access = access;
    _refresh = refresh;
  }

  @override
  Future<String?> readAccessToken() async => _access;

  @override
  Future<String?> readRefreshToken() async => _refresh;

  @override
  Future<void> saveUserJson(String json) async => _userJson = json;

  @override
  Future<String?> readUserJson() async => _userJson;

  @override
  Future<void> clear() async {
    _access = null;
    _refresh = null;
    _userJson = null;
  }

  @override
  Future<bool> hasSession() async =>
      (_access != null && _access!.isNotEmpty) ||
      (_userJson != null && _userJson!.isNotEmpty);
}
