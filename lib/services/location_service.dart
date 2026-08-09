import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Device GPS helper — used for nearby cargo/driver suggestions.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();
  factory LocationService() => instance;

  LatLng? _lastKnown;

  /// App-level GPS preference (nearby suggestions). Independent of OS GPS.
  bool _appGpsEnabled = false;

  LatLng? get lastKnown => _lastKnown;

  bool get appGpsEnabled => _appGpsEnabled;

  Future<bool> isSystemLocationEnabled() =>
      Geolocator.isLocationServiceEnabled();

  /// True when device location is on and app has usable permission
  /// (does not prompt or open settings).
  Future<bool> isGpsReady() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;

    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Opens the system screen where the user can turn device location on/off.
  Future<bool> openSystemLocationSettings() =>
      Geolocator.openLocationSettings();

  Future<bool> openAppPermissionSettings() => Geolocator.openAppSettings();

  /// Requests permission and prompts to enable device location if needed.
  Future<bool> ensurePermission({bool openSettingsIfNeeded = true}) async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (openSettingsIfNeeded) {
        await openAppPermissionSettings();
      }
      return false;
    }

    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return false;
    }

    var enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled && openSettingsIfNeeded) {
      await openSystemLocationSettings();
      // Give the user a moment after returning from settings.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      enabled = await Geolocator.isLocationServiceEnabled();
    }
    return enabled;
  }

  /// Turn GPS on for the app: request permission + enable device location.
  Future<LatLng?> enableGps() async {
    _appGpsEnabled = true;
    final ok = await ensurePermission(openSettingsIfNeeded: true);
    if (!ok) {
      _appGpsEnabled = false;
      return null;
    }
    return getCurrentPosition(requestIfNeeded: false);
  }

  /// Turn GPS off for the app and open system location settings so the user
  /// can disable device location (apps cannot force-disable OS GPS).
  Future<void> disableGps({bool openSettings = true}) async {
    _appGpsEnabled = false;
    _lastKnown = null;
    if (openSettings) {
      final stillOn = await Geolocator.isLocationServiceEnabled();
      if (stillOn) {
        await openSystemLocationSettings();
      }
    }
  }

  Future<LatLng?> getCurrentPosition({bool requestIfNeeded = true}) async {
    if (requestIfNeeded) {
      final ok = await ensurePermission();
      if (!ok) return _lastKnown;
    } else {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _lastKnown;
      }
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return _lastKnown;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      _lastKnown = LatLng(pos.latitude, pos.longitude);
      return _lastKnown;
    } catch (_) {
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          _lastKnown = LatLng(last.latitude, last.longitude);
        }
      } catch (_) {}
      return _lastKnown;
    }
  }

  double distanceKm(LatLng a, LatLng b) {
    return Geolocator.distanceBetween(
          a.latitude,
          a.longitude,
          b.latitude,
          b.longitude,
        ) /
        1000.0;
  }
}
