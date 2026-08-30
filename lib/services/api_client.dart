import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';
import 'api_response.dart';
import 'token_storage.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.body});

  final String message;
  final int? statusCode;
  final String? body;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// HTTP client with JWT Authorization header — Django REST ready.
class ApiClient {
  ApiClient({http.Client? client, TokenStorage? tokenStorage})
      : _client = client ?? http.Client(),
        _tokens = tokenStorage ?? TokenStorage();

  final http.Client _client;
  final TokenStorage _tokens;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = ApiConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalized').replace(queryParameters: query);
  }

  Future<Map<String, String>> _headers({bool jsonBody = true}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
    };
    final token = await _tokens.readAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, String>? query,
  }) async {
    final data = await get(path, query: query);
    return ApiResponse.extractList(data);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
    bool allowRefresh = true,
  }) async {
    final response = await _client.get(
      _uri(path, query),
      headers: await _headers(jsonBody: false),
    );
    return _decode(response, allowRefresh: allowRefresh, retry: () {
      return get(path, query: query, allowRefresh: false);
    });
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool allowRefresh = true,
  }) async {
    final response = await _client.post(
      _uri(path),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response, allowRefresh: allowRefresh, retry: () {
      return post(path, body: body, allowRefresh: false);
    });
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool allowRefresh = true,
  }) async {
    final response = await _client.patch(
      _uri(path),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response, allowRefresh: allowRefresh, retry: () {
      return patch(path, body: body, allowRefresh: false);
    });
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool allowRefresh = true,
  }) async {
    final response = await _client.put(
      _uri(path),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response, allowRefresh: allowRefresh, retry: () {
      return put(path, body: body, allowRefresh: false);
    });
  }

  Future<void> delete(
    String path, {
    bool allowRefresh = true,
  }) async {
    final response = await _client.delete(
      _uri(path),
      headers: await _headers(jsonBody: false),
    );
    if (response.statusCode == 401 && allowRefresh) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        await delete(path, allowRefresh: false);
        return;
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final raw = utf8.decode(response.bodyBytes);
      throw ApiException(
        ApiResponse.httpErrorMessage(
          statusCode: response.statusCode,
          rawBody: raw,
        ),
        statusCode: response.statusCode,
        body: raw,
      );
    }
  }

  Future<bool> refreshAccessToken() => _tryRefreshToken();

  Future<bool> _tryRefreshToken() async {
    // Transport API does not expose a token refresh endpoint in OpenAPI.
    return false;
  }

  Future<Map<String, dynamic>> _decode(
    http.Response response, {
    required bool allowRefresh,
    required Future<Map<String, dynamic>> Function() retry,
  }) async {
    final raw = utf8.decode(response.bodyBytes);

    if (response.statusCode == 401 && allowRefresh) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) return retry();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        ApiResponse.httpErrorMessage(
          statusCode: response.statusCode,
          rawBody: raw,
        ),
        statusCode: response.statusCode,
        body: raw,
      );
    }

    if (raw.trim().isEmpty) return <String, dynamic>{};
    try {
      final data = json.decode(raw);
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {'data': data};
    } catch (_) {
      throw ApiException(
        ApiResponse.httpErrorMessage(
          statusCode: response.statusCode,
          rawBody: raw,
        ),
        statusCode: response.statusCode,
        body: raw,
      );
    }
  }
}
