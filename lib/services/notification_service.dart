import 'package:flutter/foundation.dart';

/// Placeholder for FCM / push notifications until backend is ready.
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

  /// Call after login. When API exists, register FCM token with backend.
  Future<void> init() async {
    if (_initialized) return;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    // Mock device token — replace with FirebaseMessaging.instance.getToken()
    _deviceToken = 'mock-fcm-token-${DateTime.now().millisecondsSinceEpoch}';
    _initialized = true;
    notifyListeners();
  }

  Future<void> registerWithBackend() async {
    // POST /devices/ with {_deviceToken} when Django is ready.
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
