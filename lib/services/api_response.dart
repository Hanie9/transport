import 'dart:convert';

import '../l10n/api_messages.dart';
import 'settings_service.dart';

/// Helpers for decoding Django REST / OpenAPI-shaped JSON bodies.
abstract final class ApiResponse {
  static bool get _isEnglish => SettingsService().isEnglish;

  /// Unwraps `{data: {...}}` or returns the map as-is.
  static Map<String, dynamic> extractObject(Map<String, dynamic> data) {
    final nested = data['data'];
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }
    return data;
  }

  static List<Map<String, dynamic>> extractList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data is! Map) return const [];

    final map = Map<String, dynamic>.from(data);
    final raw = map['results'] ?? map['data'] ?? map['items'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  static ({int count, int currentPage, int totalPages, bool hasNext})
  extractPagination(dynamic data) {
    if (data is! Map) {
      return (count: 0, currentPage: 1, totalPages: 1, hasNext: false);
    }
    final map = Map<String, dynamic>.from(data);
    final count = int.tryParse('${map['count']}') ?? 0;
    final currentPage = int.tryParse('${map['current_page']}') ?? 1;
    final totalPages = int.tryParse('${map['total_pages']}') ?? 1;
    final hasNext = map['next'] != null;
    return (
      count: count,
      currentPage: currentPage,
      totalPages: totalPages,
      hasNext: hasNext,
    );
  }

  /// Builds a short, user-facing HTTP error message in the active app language.
  static String httpErrorMessage({
    int? statusCode,
    String? rawBody,
    bool? isEnglish,
  }) {
    final english = isEnglish ?? _isEnglish;
    final fallback = ApiMessages.requestFailed(isEnglish: english);
    final body = rawBody?.trim();

    if (body != null && body.isNotEmpty) {
      if (looksLikeHtml(body)) {
        return _hostingOrStatusMessage(body, statusCode, english);
      }

      final parsed = _tryParseJson(body);
      final extracted = extractErrorMessage(
        parsed,
        fallback: fallback,
        isEnglish: english,
      );
      if (extracted != fallback && !looksLikeHtml(extracted)) {
        return _clampMessage(extracted);
      }
    }

    return ApiMessages.messageForStatusCode(statusCode, isEnglish: english) ??
        fallback;
  }

  /// Pulls a human-readable error from DRF validation payloads.
  static String extractErrorMessage(
    dynamic data, {
    String fallback = 'Request failed',
    bool? isEnglish,
  }) {
    final english = isEnglish ?? _isEnglish;

    if (data == null) return fallback;
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) return fallback;
      if (looksLikeHtml(trimmed)) return fallback;
      return _clampMessage(
        ApiMessages.localizeBackendDetail(trimmed, isEnglish: english),
      );
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      const summaryKeys = ['detail', 'message', 'error', 'non_field_errors'];
      final parts = <String>[];

      for (final key in summaryKeys) {
        final value = map[key];
        final msg = _stringifyFieldError(value, isEnglish: english);
        if (msg != null && !looksLikeHtml(msg)) {
          parts.add(ApiMessages.localizeBackendDetail(msg, isEnglish: english));
        }
      }

      for (final entry in map.entries) {
        if (summaryKeys.contains(entry.key)) continue;
        final msg = _stringifyFieldError(entry.value, isEnglish: english);
        if (msg == null || looksLikeHtml(msg)) continue;
        final field = ApiMessages.localizeFieldName(
          entry.key,
          isEnglish: english,
        );
        final localized = ApiMessages.localizeBackendDetail(
          msg,
          isEnglish: english,
        );
        parts.add('$field: $localized');
      }

      if (parts.isNotEmpty) {
        return _clampMessage(parts.join(english ? '; ' : '؛ '));
      }
    }

    return fallback;
  }

  static bool looksLikeHtml(String value) {
    final lower = value.trimLeft().toLowerCase();
    if (lower.startsWith('<!doctype') || lower.startsWith('<html')) return true;
    if (lower.contains('<head>') || lower.contains('<body')) return true;
    if (lower.contains('<title>') && lower.contains('</title>')) return true;
    if (lower.contains('<iframe') || lower.contains('</iframe>')) return true;
    return RegExp(r'<[a-z][\s\S]*>', caseSensitive: false).hasMatch(value);
  }

  static String _hostingOrStatusMessage(
    String body,
    int? statusCode,
    bool isEnglish,
  ) {
    final lower = body.toLowerCase();
    if (lower.contains('shutdown') ||
        lower.contains('liara') ||
        lower.contains('error-pages.iran.liara.run')) {
      return ApiMessages.serverUnavailableRetry(isEnglish: isEnglish);
    }
    return ApiMessages.messageForStatusCode(statusCode, isEnglish: isEnglish) ??
        ApiMessages.invalidServerResponse(isEnglish: isEnglish);
  }

  static String _clampMessage(String message, {int maxLength = 220}) {
    final singleLine = message.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (singleLine.length <= maxLength) return singleLine;
    return '${singleLine.substring(0, maxLength - 1)}…';
  }

  static String? _stringifyFieldError(
    dynamic value, {
    required bool isEnglish,
  }) {
    if (value == null) return null;
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is List && value.isNotEmpty) {
      final join = isEnglish ? ', ' : '، ';
      return value.map((e) => e.toString()).join(join);
    }
    return value.toString();
  }

  static dynamic _tryParseJson(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return json.decode(raw);
    } catch (_) {
      return raw;
    }
  }
}
