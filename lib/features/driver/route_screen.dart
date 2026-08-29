import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/location_access_dialog.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/metric_chip.dart';
import '../../core/widgets/modern_app_bar.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cargo.dart';
import '../../services/cargo_service.dart';
import '../../services/driver_routing_service.dart';
import '../../services/location_service.dart';
import '../../services/neshan_models.dart';
import '../../services/neshan_service.dart';
import '../../utils/address_geocode_hints.dart';
import '../../utils/neshan_config.dart';
import '../../utils/neshan_degraded_route.dart';
import '../../utils/neshan_errors.dart';
import '../../utils/route_maneuver.dart';
import '../../utils/route_map_geometry.dart';
import '../../utils/route_progress.dart';
import '../../widgets/driver_map_controller.dart';
import '../../widgets/driver_navigation_map.dart';
import '../../widgets/neshan_return_to_route_button.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key, required this.cargoId});

  final String cargoId;

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  static const _routing = DriverRoutingService();

  /// How far (m) from the planned path before counting as off-route.
  static const double _offRouteThresholdMeters = 50;

  /// Consecutive GPS fixes off-route before triggering a replacement route.
  static const int _offRouteHitsRequired = 2;

  /// Minimum gap between automatic reroutes.
  static const Duration _rerouteCooldown = Duration(seconds: 12);

  final _cargoService = CargoService();
  final _location = LocationService();
  final _mapController = DriverMapController();

  Cargo? _cargo;
  bool _loading = true;
  String? _error;

  /// 0 = navigate to origin (pickup), 1 = navigate to destination.
  int _routeStep = 0;
  bool _navigationActive = false;
  bool _mapCameraDetached = false;

  NeshanLatLng? _originPoint;
  NeshanLatLng? _destinationPoint;
  NeshanRoute? _pickupRoute;
  NeshanRoute? _deliveryRoute;

  /// True after mid-trip delivery reroute (route starts at driver, not cargo origin).
  bool _deliveryFromDriver = false;

  LatLng? _driverPosition;
  double? _driverHeading;
  StreamSubscription<Position>? _positionSub;
  bool _pickupRouteLoading = false;
  bool _rerouting = false;
  int _offRouteHits = 0;
  DateTime? _lastPickupRerouteAt;
  DateTime? _lastRerouteAt;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final cargo = await _cargoService.getCargoById(widget.cargoId);
    if (!mounted) return;
    if (cargo == null) {
      setState(() {
        _cargo = null;
        _loading = false;
      });
      return;
    }

    setState(() => _cargo = cargo);

    try {
      if (!hasDirectNeshanKey && !hasNeshanApiKey) {
        throw const NeshanApiException(
          'Neshan API key is not configured',
          neshanStatus: 'KeyNotFound',
        );
      }

      final originPoint = await _resolveCargoPoint(
        address: cargo.origin,
        lat: cargo.originLat,
        lng: cargo.originLng,
      );
      final destPoint = await _resolveCargoPoint(
        address: cargo.destination,
        lat: cargo.destinationLat,
        lng: cargo.destinationLng,
        sibling: originPoint.result,
      );
      if (!mounted) return;

      final origin = originPoint.location;
      final destination = destPoint.location;

      // Do not prompt for GPS on entry — only when the user starts navigation.
      final driverPos = await _location.getCurrentPosition(requestIfNeeded: false);
      if (!mounted) return;

      NeshanRoute? pickup;
      var pickupDegraded = false;

      if (driverPos != null) {
        setState(() => _driverPosition = driverPos);
        final driverNeshan = NeshanLatLng(
          latitude: driverPos.latitude,
          longitude: driverPos.longitude,
        );
        try {
          pickup = await _routing.getRouteWithTraffic(
            origin: driverNeshan,
            destination: origin,
          );
        } catch (_) {
          try {
            pickup = await _routing.getRoute(
              origin: driverNeshan,
              destination: origin,
            );
          } catch (_) {
            pickup = buildDegradedDirectRoute(
              origin: driverNeshan,
              destination: origin,
            );
            pickupDegraded = true;
          }
        }
      }

      NeshanRoute delivery;
      try {
        delivery = await _routing.getRouteWithTraffic(
          origin: origin,
          destination: destination,
        );
      } catch (_) {
        try {
          delivery = await _routing.getRoute(
            origin: origin,
            destination: destination,
          );
        } catch (_) {
          delivery = buildDegradedDirectRoute(
            origin: origin,
            destination: destination,
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _originPoint = origin;
        _destinationPoint = destination;
        _pickupRoute = pickup;
        _deliveryRoute = delivery;
        _loading = false;
        if (pickup != null) _lastPickupRerouteAt = DateTime.now();
      });

      await _startLocationStream();

      if (driverPos == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final ready = await requestLocationAccessWithDialog(
            context,
            title: context.l10n.locationEnableTitle,
            message: context.l10n.locationEnableNavigationMessage,
          );
          if (!mounted || !ready) return;

          final pos = await _location.getCurrentPosition(requestIfNeeded: false);
          if (!mounted || pos == null) return;

          setState(() => _driverPosition = pos);
          await _startLocationStream();
          if (_routeStep == 0 && _pickupRoute == null) {
            await _loadPickupRoute(force: true, fromDriver: pos);
          }
        });
      }

      final approximateMessage = context.l10n.routeApproximateFallback;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || _navigationActive) return;
        await Future<void>.delayed(const Duration(milliseconds: 350));
        if (!mounted || _navigationActive) return;
        await _mapController.refitOverview();
        if (pickupDegraded && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(approximateMessage)),
          );
        }
      });
    } on NeshanApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = localizeNeshanError(context.l10n, e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  /// Prefer stored cargo coords; otherwise geocode with cargo-aware bias.
  Future<({NeshanLatLng location, NeshanGeocodingResult? result})>
      _resolveCargoPoint({
    required String address,
    double? lat,
    double? lng,
    NeshanGeocodingResult? sibling,
  }) async {
    final hasStored = lat != null && lng != null;
    if (hasStored) {
      final stored = NeshanLatLng(latitude: lat, longitude: lng);
      final hints = extractGeocodeHints(address);
      return (
        location: stored,
        result: NeshanGeocodingResult(
          location: stored,
          city: hints.city,
          province: hints.province,
        ),
      );
    }

    try {
      final geo = await _routing.resolveCargoAddress(
        address,
        siblingResult: sibling,
      );
      return (location: geo.location, result: geo);
    } catch (_) {
      final hints = extractGeocodeHints(address);
      final centroid =
          hints.city != null ? iranCityCentroids[hints.city] : null;
      if (centroid != null) {
        return (
          location: centroid,
          result: NeshanGeocodingResult(
            location: centroid,
            city: hints.city,
            province: hints.province,
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> _loadPickupRoute({
    bool force = false,
    LatLng? fromDriver,
  }) async {
    final origin = _originPoint;
    final driver = fromDriver ?? _driverPosition;
    if (origin == null || driver == null) return;
    if (_routeStep != 0) return;
    if (_pickupRouteLoading) return;

    final now = DateTime.now();
    if (!force &&
        _lastPickupRerouteAt != null &&
        now.difference(_lastPickupRerouteAt!) < const Duration(seconds: 45)) {
      return;
    }

    _pickupRouteLoading = true;
    try {
      final route = await _routing.getRouteWithTraffic(
        origin: NeshanLatLng(
          latitude: driver.latitude,
          longitude: driver.longitude,
        ),
        destination: origin,
      );
      if (!mounted) return;
      setState(() {
        _pickupRoute = route;
        _lastPickupRerouteAt = DateTime.now();
      });
    } catch (_) {
      if (!mounted || _originPoint == null) return;
      setState(() {
        _pickupRoute = buildDegradedDirectRoute(
          origin: NeshanLatLng(
            latitude: driver.latitude,
            longitude: driver.longitude,
          ),
          destination: _originPoint!,
        );
        _lastPickupRerouteAt = DateTime.now();
      });
    } finally {
      _pickupRouteLoading = false;
    }
  }

  Future<void> _loadDeliveryRouteFromDriver(LatLng driver) async {
    final destination = _destinationPoint;
    if (destination == null) return;

    try {
      final route = await _routing.getRouteWithTraffic(
        origin: NeshanLatLng(
          latitude: driver.latitude,
          longitude: driver.longitude,
        ),
        destination: destination,
      );
      if (!mounted) return;
      setState(() {
        _deliveryRoute = route;
        _deliveryFromDriver = true;
      });
    } catch (_) {
      try {
        final route = await _routing.getRoute(
          origin: NeshanLatLng(
            latitude: driver.latitude,
            longitude: driver.longitude,
          ),
          destination: destination,
        );
        if (!mounted) return;
        setState(() {
          _deliveryRoute = route;
          _deliveryFromDriver = true;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _deliveryRoute = buildDegradedDirectRoute(
            origin: NeshanLatLng(
              latitude: driver.latitude,
              longitude: driver.longitude,
            ),
            destination: destination,
          );
          _deliveryFromDriver = true;
        });
      }
    }
  }

  /// Off-route → recalculate an alternate path from the live GPS position.
  void _maybeRerouteOffRoute(LatLng driver) {
    if (!_navigationActive || _rerouting) return;
    final route = _routeCoordinates;
    if (route.length < 2) return;

    final offBy = distanceToPolylineMeters(route, driver);
    if (offBy <= _offRouteThresholdMeters) {
      _offRouteHits = 0;
      return;
    }

    _offRouteHits++;
    if (_offRouteHits < _offRouteHitsRequired) return;

    final now = DateTime.now();
    if (_lastRerouteAt != null &&
        now.difference(_lastRerouteAt!) < _rerouteCooldown) {
      return;
    }

    _offRouteHits = 0;
    _lastRerouteAt = now;
    unawaited(_rerouteFromDriver(driver));
  }

  Future<void> _rerouteFromDriver(LatLng driver) async {
    if (_rerouting) return;
    _rerouting = true;

    final messenger = mounted ? ScaffoldMessenger.of(context) : null;
    final reroutingMsg = mounted ? context.l10n.routeRerouting : null;
    final reroutedMsg = mounted ? context.l10n.routeRerouted : null;

    if (messenger != null && reroutingMsg != null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(reroutingMsg),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    try {
      if (_routeStep == 0) {
        await _loadPickupRoute(force: true, fromDriver: driver);
      } else {
        await _loadDeliveryRouteFromDriver(driver);
      }

      if (!mounted) return;

      if (reroutedMsg != null) {
        messenger?.hideCurrentSnackBar();
        messenger?.showSnackBar(
          SnackBar(
            content: Text(reroutedMsg),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      if (_navigationActive && !_mapCameraDetached) {
        await _mapController.resumeNavigation(
          position: _driverPosition ?? driver,
          heading: _driverHeading,
        );
      } else if (!_navigationActive) {
        await _mapController.refitOverview();
      }
    } finally {
      _rerouting = false;
    }
  }

  Future<void> _startLocationStream() async {
    if (!await _location.isGpsReady()) return;

    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 8,
      ),
    ).listen((pos) {
      if (!mounted) return;
      final next = LatLng(pos.latitude, pos.longitude);
      final heading = pos.heading >= 0 ? pos.heading : _driverHeading;
      final hadDriver = _driverPosition != null;
      setState(() {
        _driverPosition = next;
        if (pos.heading >= 0) _driverHeading = pos.heading;
      });

      if (!hadDriver && _routeStep == 0 && _pickupRoute == null) {
        unawaited(_loadPickupRoute(force: true, fromDriver: next));
      }

      if (_navigationActive) {
        unawaited(
          _mapController.tickNavigation(
            position: next,
            heading: heading,
          ),
        );
        _maybeRerouteOffRoute(next);
      }
    });
  }

  LatLng get _originLatLng =>
      LatLng(_originPoint!.latitude, _originPoint!.longitude);

  LatLng get _destinationLatLng =>
      LatLng(_destinationPoint!.latitude, _destinationPoint!.longitude);

  NeshanRoute get _activeRoute {
    if (_routeStep == 1) {
      return _deliveryRoute ??
          buildDegradedDirectRoute(
            origin: _originPoint!,
            destination: _destinationPoint!,
          );
    }
    if (_pickupRoute != null) return _pickupRoute!;
    // No usable driver GPS yet — show cargo trip (origin→destination) roads.
    if (_deliveryRoute != null) return _deliveryRoute!;
    return buildDegradedDirectRoute(
      origin: _originPoint!,
      destination: _destinationPoint ?? _originPoint!,
    );
  }

  RouteMapGeometry get _activeGeometry {
    // Overview: prefer driver→origin when available, else cargo trip.
    if (!_navigationActive) {
      if (_routeStep == 0 &&
          _pickupRoute != null &&
          _driverPosition != null) {
        return RouteMapGeometry.fromRoute(
          _pickupRoute!,
          origin: _driverPosition!,
          destination: _originLatLng,
        );
      }
      if (_deliveryRoute != null) {
        return RouteMapGeometry.fromRoute(
          _deliveryRoute!,
          origin: _originLatLng,
          destination: _destinationLatLng,
        );
      }
    }
    if (_routeStep == 1) {
      final origin = (_deliveryFromDriver && _driverPosition != null)
          ? _driverPosition!
          : _originLatLng;
      return RouteMapGeometry.fromRoute(
        _activeRoute,
        origin: origin,
        destination: _destinationLatLng,
      );
    }
    final driver = _driverPosition ?? _originLatLng;
    return RouteMapGeometry.fromRoute(
      _activeRoute,
      origin: driver,
      destination: _originLatLng,
    );
  }

  List<NeshanRouteStep> get _steps =>
      _activeRoute.primaryLeg?.steps ?? const [];

  List<LatLng> get _routeCoordinates => _activeGeometry.fullPolyline;

  int get _guidanceStepIndex {
    final driver = _driverPosition;
    final steps = _steps;
    if (driver == null || steps.isEmpty) return 0;
    return findNextGuidanceStepIndex(
      steps: steps,
      driver: driver,
      routePolyline: _routeCoordinates,
    );
  }

  NeshanRouteStep? get _guidanceStep {
    final steps = _steps;
    if (steps.isEmpty) return null;
    return steps[_guidanceStepIndex.clamp(0, steps.length - 1)];
  }

  NeshanRouteStep? get _thenGuidanceStep {
    final steps = _steps;
    if (steps.isEmpty) return null;
    final start = _guidanceStepIndex + 1;
    if (start >= steps.length) return null;
    for (var i = start; i < steps.length; i++) {
      if (!isDepartOrContinueStep(steps[i]) || i == steps.length - 1) {
        return steps[i];
      }
    }
    return null;
  }

  double _distanceToGuidanceStepMeters() {
    final driver = _driverPosition;
    final step = _guidanceStep;
    if (driver == null || step == null) return 0;
    return distanceMetersToGuidanceStep(
      driver: driver,
      step: step,
      routePolyline: _routeCoordinates,
    );
  }

  int? get _traveledPolylineIndex {
    final driver = _driverPosition;
    if (!_navigationActive || driver == null || _routeCoordinates.length < 2) {
      return null;
    }
    final snapped = snapPointToPolyline(_routeCoordinates, driver);
    return findClosestPolylineIndex(_routeCoordinates, snapped);
  }

  Future<void> _openInNeshan() async {
    final dest = _routeStep == 0 ? _originPoint : _destinationPoint;
    if (dest == null) return;
    final uri = Uri.parse(
      'https://neshan.org/maps/@${dest.latitude},${dest.longitude},15z',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _onMapCameraDetached(bool detached) {
    if (!mounted) return;
    if (_mapCameraDetached == detached) return;
    setState(() => _mapCameraDetached = detached);
  }

  Future<void> _returnToRoute() async {
    if (_navigationActive) {
      final position = _driverPosition;
      if (position == null) return;
      setState(() => _mapCameraDetached = false);
      await _mapController.resumeNavigation(
        position: position,
        heading: _driverHeading,
      );
    } else {
      setState(() => _mapCameraDetached = false);
      await _mapController.refitOverview();
    }
  }

  Widget _returnToRouteButton({double bottom = 16}) {
    if (!_navigationActive || !_mapCameraDetached) {
      return const SizedBox.shrink();
    }
    return NeshanReturnToRouteButton(
      label: context.l10n.returnToRoute,
      onPressed: () {
        unawaited(_returnToRoute());
      },
      bottom: bottom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        appBar: ModernAppBar(
          title: l10n.routeTitle,
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: LoadingOverlay(message: l10n.loadingRoute),
      );
    }

    if (_cargo == null) {
      return Scaffold(
        appBar: ModernAppBar(
          title: l10n.routeTitle,
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: EmptyState(icon: Icons.map_outlined, title: l10n.routeNotFound),
      );
    }

    if (_error != null || _originPoint == null || _destinationPoint == null) {
      return Scaffold(
        appBar: ModernAppBar(
          title: l10n.routeTitle,
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: EmptyState(
          icon: Icons.error_outline,
          title: l10n.neshanMap,
          subtitle: _error ?? l10n.neshanErrorGeneric,
        ),
      );
    }

    final cargo = _cargo!;
    final geometry = _activeGeometry;
    final stepLabel =
        _routeStep == 0 ? l10n.routeToOrigin : l10n.routeToDestination;
    final targetLabel = _routeStep == 0 ? cargo.origin : cargo.destination;
    final leg = _activeRoute.primaryLeg;
    // Overview markers: cargo origin & destination (uzita mission overview).
    // Navigation: live driver → current target.
    final LatLng mapOrigin;
    final LatLng mapDestination;
    if (!_navigationActive) {
      mapOrigin = _originLatLng;
      mapDestination = _destinationLatLng;
    } else if (_routeStep == 0) {
      mapOrigin = _driverPosition ?? _originLatLng;
      mapDestination = _originLatLng;
    } else {
      mapOrigin = _deliveryFromDriver
          ? (_driverPosition ?? _originLatLng)
          : _originLatLng;
      mapDestination = _destinationLatLng;
    }

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: ModernAppBar(
        title: l10n.routeTitle,
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          IconButton(
            tooltip: l10n.openInNeshanMaps,
            onPressed: _openInNeshan,
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                DriverNavigationMap(
                  routeCoordinates: geometry.fullPolyline,
                  routeSegments: geometry.segments,
                  origin: mapOrigin,
                  destination: mapDestination,
                  driverPosition: _driverPosition,
                  driverHeading: _driverHeading,
                  followDriver: _navigationActive && !_mapCameraDetached,
                  navigationMode: _navigationActive,
                  isDark: isDark,
                  overviewMode: !_navigationActive,
                  pickupLeg: _routeStep == 0,
                  traveledFromIndex: _traveledPolylineIndex,
                  returnToRouteLabel: l10n.returnToRoute,
                  controller: _mapController,
                  onCameraDetached: _onMapCameraDetached,
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  left: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_navigationActive)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: palette.cardBg.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: palette.divider.withValues(alpha: 0.8)),
                            boxShadow: palette.cardShadow,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  stepLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  targetLabel,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_navigationActive && _guidanceStep != null)
                        _NavigationGuidanceCard(
                          step: _guidanceStep!,
                          nextStep: _thenGuidanceStep,
                          distanceMeters: _distanceToGuidanceStepMeters(),
                          persian: l10n.isFa,
                          thenLabel: l10n.routeThen,
                        ),
                    ],
                  ),
                ),
                _returnToRouteButton(bottom: 20),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: palette.cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: palette.divider.withValues(alpha: 0.8))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: palette.divider,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      _StepIndicator(
                        step: 1,
                        label: l10n.origin,
                        isActive: _routeStep == 0,
                        isCompleted: _routeStep > 0,
                      ),
                      Expanded(
                        child: Container(
                          height: 2,
                          color: _routeStep > 0
                              ? AppTheme.success
                              : palette.divider,
                        ),
                      ),
                      _StepIndicator(
                        step: 2,
                        label: l10n.destination,
                        isActive: _routeStep == 1,
                        isCompleted: false,
                      ),
                    ],
                  ),
                  if (leg != null) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        MetricChip(
                          icon: Icons.straighten_rounded,
                          label: leg.distanceText,
                          color: AppTheme.primary,
                        ),
                        MetricChip(
                          icon: Icons.schedule_rounded,
                          label: leg.durationText,
                          color: AppTheme.accent,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (!_navigationActive)
                    ElevatedButton.icon(
                      onPressed: () async {
                        var pos = _driverPosition;
                        if (pos == null) {
                          final ready = await requestLocationAccessWithDialog(
                            context,
                            title: l10n.locationEnableTitle,
                            message: l10n.locationEnableNavigationMessage,
                          );
                          if (!mounted) return;
                          if (!ready) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.locationRequiredForRoute),
                              ),
                            );
                            return;
                          }
                          pos = await _location.getCurrentPosition(requestIfNeeded: false);
                          if (!mounted) return;
                          if (pos == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.locationRequiredForRoute),
                              ),
                            );
                            return;
                          }
                          setState(() => _driverPosition = pos);
                          await _startLocationStream();
                        }
                        // Refresh a real road route before heading-up navigation.
                        if (_routeStep == 0) {
                          await _loadPickupRoute(force: true, fromDriver: pos);
                        } else if (_destinationPoint != null) {
                          await _loadDeliveryRouteFromDriver(pos);
                        }
                        if (!mounted) return;
                        setState(() {
                          _navigationActive = true;
                          _mapCameraDetached = false;
                        });
                        await _mapController.resumeNavigation(
                          position: pos,
                          heading: _driverHeading,
                        );
                      },
                      icon: const Icon(Icons.navigation_rounded),
                      label: Text(
                        l10n.startNavigationTo(
                          _routeStep == 0 ? l10n.origin : l10n.destination,
                        ),
                      ),
                    ),
                  if (_routeStep == 0) ...[
                    if (!_navigationActive) const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () async {
                        await _cargoService.updateCargoStatus(
                          cargo.id,
                          'در حال حمل',
                        );
                        if (!mounted) return;
                        setState(() {
                          _routeStep = 1;
                          _navigationActive = false;
                          _mapCameraDetached = false;
                          _deliveryFromDriver = false;
                          _offRouteHits = 0;
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          unawaited(_mapController.refitOverview());
                        });
                      },
                      child: Text(l10n.arrivedAtOriginContinue),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () async {
                        await _cargoService.updateCargoStatus(
                          cargo.id,
                          'تحویل شده',
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.cargoDelivered)),
                        );
                        context.pop();
                      },
                      child: Text(l10n.markDelivered),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }
}

class _NavigationGuidanceCard extends StatelessWidget {
  const _NavigationGuidanceCard({
    required this.step,
    required this.nextStep,
    required this.distanceMeters,
    required this.persian,
    required this.thenLabel,
  });

  final NeshanRouteStep step;
  final NeshanRouteStep? nextStep;
  final double distanceMeters;
  final bool persian;
  final String thenLabel;

  @override
  Widget build(BuildContext context) {
    final direction = persian ? TextDirection.rtl : TextDirection.ltr;
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.cardBg.withValues(alpha: 0.98),
            AppTheme.primaryDark.withValues(alpha: 0.96),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Row(
          textDirection: direction,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: maneuverIconWidget(step, rtl: persian),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    maneuverDistancePrefix(distanceMeters, persian: persian),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection: direction,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    guidancePrimaryLabel(step),
                    style: const TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    textDirection: direction,
                  ),
                  if (nextStep != null &&
                      nextStep!.instruction.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '$thenLabel: ${nextStep!.instruction}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12,
                      ),
                      textDirection: direction,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.step,
    required this.label,
    required this.isActive,
    required this.isCompleted,
  });

  final int step;
  final String label;
  final bool isActive;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = isCompleted
        ? AppTheme.success
        : isActive
            ? AppTheme.primary
            : palette.textSecondary.withValues(alpha: 0.45);

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: isActive || isCompleted
                ? LinearGradient(
                    colors: isCompleted
                        ? [AppTheme.success, AppTheme.success.withValues(alpha: 0.8)]
                        : [AppTheme.primary, AppTheme.primaryLight],
                  )
                : null,
            color: isActive || isCompleted ? null : palette.divider,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: isCompleted
              ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
              : Text(
                  '$step',
                  style: TextStyle(
                    color: isActive ? Colors.white : palette.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
