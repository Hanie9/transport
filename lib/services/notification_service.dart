import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../api_config.dart';
import 'api_client.dart';

/// Push notification registration against the transport backend.
class NotificationService extends ChangeNotifier {
  NotificationService._({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final ApiClient _api;

  bool _initialized = false;
  String? _deviceToken;
  final List<String> _localInbox = [];

  bool get isInitialized => _initialized;
  String? get deviceToken => _deviceToken;
  List<String> get inbox => List.unmodifiable(_localInbox);

  /// Call after login. Registers FCM token with backend when available.
  Future<void> init() async {
    if (_initialized) return;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    // TODO: replace with FirebaseMessaging.instance.getToken() when FCM is added.
    _deviceToken = 'fcm-placeholder-${DateTime.now().millisecondsSinceEpoch}';
    _initialized = true;
    notifyListeners();
  }

  Future<void> registerWithBackend() async {
    if (ApiConfig.shouldUseMock) return;
    final token = _deviceToken;
    if (token == null || token.isEmpty) return;

    try {
      await _api.post(
        ApiConfig.devicesPath,
        body: {
          'token': token,
          'platform': _platformLabel(),
        },
      );
    } catch (_) {
      // Non-fatal — app works without push registration.
    }
  }

  String _platformLabel() {
    if (kIsWeb) return 'web';
    try {
      return Platform.operatingSystem;
    } catch (_) {
      return 'unknown';
    }
  }

  void pushLocal(String message) {
    _localInbox.insert(0, message);
    notifyListeners();
  }

  void clearInbox() {
    _localInbox.clear();
    notifyListeners();
  }
}
