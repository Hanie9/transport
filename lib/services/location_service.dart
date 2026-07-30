import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Device GPS helper — used for nearby cargo/driver suggestions.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();
  factory LocationService() => instance;

  LatLng? _lastKnown;

  LatLng? get lastKnown => _lastKnown;

  Future<bool> ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
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
