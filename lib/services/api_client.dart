import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';
import 'token_storage.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.body});

  final String message;
  final int? statusCode;
  final String? body;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// HTTP client with JWT Authorization header — ready for Django REST.
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

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    final response = await _client.get(
      _uri(path, query),
      headers: await _headers(jsonBody: false),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _client.post(
      _uri(path),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _client.patch(
      _uri(path),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _client.put(
      _uri(path),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  Future<void> delete(String path) async {
    final response = await _client.delete(
      _uri(path),
      headers: await _headers(jsonBody: false),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'Request failed',
        statusCode: response.statusCode,
        body: utf8.decode(response.bodyBytes),
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    final raw = utf8.decode(response.bodyBytes);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Request failed';
      try {
        final data = json.decode(raw);
        if (data is Map) {
          message = (data['detail'] ?? data['message'] ?? data['error'] ?? message)
              .toString();
        }
      } catch (_) {}
      throw ApiException(message, statusCode: response.statusCode, body: raw);
    }
    if (raw.trim().isEmpty) return <String, dynamic>{};
    final data = json.decode(raw);
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'data': data};
  }
}
