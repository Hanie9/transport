import 'package:flutter/foundation.dart';

import '../api_config.dart';

/// Push notification registration against the transport backend.
class NotificationService extends ChangeNotifier {
  NotificationService._();

  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

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
    // Transport API has no device registration endpoint in OpenAPI yet.
    if (ApiConfig.shouldUseMock) return;
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
