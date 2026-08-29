import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum GpsAccessStatus {
  ready,
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  unavailable,
}

class GpsAccessResult {
  const GpsAccessResult({required this.status, this.position});

  final GpsAccessStatus status;
  final LatLng? position;

  bool get isReady => status == GpsAccessStatus.ready && position != null;
}

/// Device GPS helper — used for nearby cargo/driver suggestions.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();
  factory LocationService() => instance;

  LatLng? _lastKnown;

  /// App-level GPS preference (nearby suggestions). Independent of OS GPS.
  bool _appGpsEnabled = false;

  LatLng? get lastKnown => _lastKnown;

  /// User opted in to nearby-cargo suggestions on the Cargos page.
  bool get appGpsEnabled => _appGpsEnabled;

  bool _nearbyPreferenceInitialized = false;

  /// On first visit, mirror device GPS if it is already available.
  Future<void> initializeNearbyPreferenceFromDevice() async {
    if (_nearbyPreferenceInitialized) return;
    _nearbyPreferenceInitialized = true;
    if (await isGpsReady()) {
      _appGpsEnabled = true;
    }
  }

  /// Nearby suggestions are active only when the user opted in and device GPS works.
  Future<bool> isNearbyGpsActive() async =>
      _appGpsEnabled && await isGpsReady();

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

  /// Requests permission without opening the Settings app.
  ///
  /// When [openSettingsIfNeeded] is true, only permanently denied permission
  /// may redirect to app settings — never the device location settings screen.
  Future<bool> ensurePermission({bool openSettingsIfNeeded = false}) async {
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

    return Geolocator.isLocationServiceEnabled();
  }

  /// Requests permission and uses the platform location-service dialog on Android.
  ///
  /// Never opens the device location Settings screen automatically.
  Future<GpsAccessResult> requestGpsAccess() async {
    _appGpsEnabled = true;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      _appGpsEnabled = false;
      return const GpsAccessResult(status: GpsAccessStatus.permissionDeniedForever);
    }

    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      _appGpsEnabled = false;
      return const GpsAccessResult(status: GpsAccessStatus.permissionDenied);
    }

    final position = await _readCurrentPosition(triggerServiceDialog: true);
    if (position != null) {
      return GpsAccessResult(status: GpsAccessStatus.ready, position: position);
    }

    _appGpsEnabled = false;
    final servicesOn = await Geolocator.isLocationServiceEnabled();
    return GpsAccessResult(
      status: servicesOn ? GpsAccessStatus.unavailable : GpsAccessStatus.serviceDisabled,
    );
  }

  /// Turn GPS on for the app: system permission + device-location dialogs.
  Future<LatLng?> enableGps() async {
    final result = await requestGpsAccess();
    return result.position;
  }

  /// Disables nearby-cargo GPS in the app (does not change device location).
  Future<void> disableGps() async {
    _appGpsEnabled = false;
    _lastKnown = null;
  }

  void setNearbyGpsEnabled(bool enabled) {
    _appGpsEnabled = enabled;
    if (!enabled) _lastKnown = null;
  }

  Future<LatLng?> getCurrentPosition({bool requestIfNeeded = false}) async {
    if (requestIfNeeded) {
      final result = await requestGpsAccess();
      return result.position;
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return _lastKnown;
    }
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return _lastKnown;

    return _readCurrentPosition(triggerServiceDialog: false);
  }

  Future<LatLng?> _readCurrentPosition({required bool triggerServiceDialog}) async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: triggerServiceDialog ? 30 : 8),
        ),
      );
      _lastKnown = LatLng(pos.latitude, pos.longitude);
      return _lastKnown;
    } on LocationServiceDisabledException {
      return null;
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
