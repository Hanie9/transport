import 'package:shared_preferences/shared_preferences.dart';

/// Tracks how long the app has been in the background before requiring login.
class SessionService {
  SessionService._();

  static final SessionService instance = SessionService._();
  factory SessionService() => instance;

  static const _lastPausedAtKey = 'session_last_paused_at_ms';
  static const Duration inactivityTimeout = Duration(minutes: 15);

  Future<void> clearBackgroundMarker() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastPausedAtKey);
  }

  Future<void> markBackgrounded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastPausedAtKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> shouldRequireLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final pausedAtMs = prefs.getInt(_lastPausedAtKey);
    if (pausedAtMs == null) return false;

    final pausedAt = DateTime.fromMillisecondsSinceEpoch(pausedAtMs);
    return DateTime.now().difference(pausedAt) > inactivityTimeout;
  }
}
