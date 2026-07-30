import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/modern_app_bar.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cargo.dart';
import '../../services/cargo_service.dart';
import '../../services/driver_routing_service.dart';
import '../../services/neshan_models.dart';
import '../../services/neshan_service.dart';
import '../../utils/neshan_config.dart';
import '../../utils/neshan_degraded_route.dart';
import '../../utils/neshan_errors.dart';
import '../../utils/route_map_geometry.dart';
import '../../widgets/driver_map_controller.dart';
import '../../widgets/driver_navigation_map.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key, required this.cargoId});

  final String cargoId;

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  static const _routing = DriverRoutingService();

  final _cargoService = CargoService();
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

  LatLng? _driverPosition;
  double? _driverHeading;
  StreamSubscription<Position>? _positionSub;

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

      final originGeo = await _routing.geocodeAddress(cargo.origin);
      final destGeo = await _routing.geocodeAddress(cargo.destination);
      final delivery = await _routing.getRouteWithTraffic(
        origin: originGeo.location,
        destination: destGeo.location,
      );

      if (!mounted) return;
      setState(() {
        _originPoint = originGeo.location;
        _destinationPoint = destGeo.location;
        _deliveryRoute = delivery;
        _loading = false;
      });
      await _startLocation();
      await _loadPickupRoute();
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

  Future<void> _loadPickupRoute() async {
    final origin = _originPoint;
    final driver = _driverPosition;
    if (origin == null || driver == null) return;

    try {
      final route = await _routing.getRouteWithTraffic(
        origin: NeshanLatLng(latitude: driver.latitude, longitude: driver.longitude),
        destination: origin,
      );
      if (!mounted) return;
      setState(() => _pickupRoute = route);
    } catch (_) {
      if (!mounted || _driverPosition == null || _originPoint == null) return;
      setState(() {
        _pickupRoute = buildDegradedDirectRoute(
          origin: NeshanLatLng(
            latitude: _driverPosition!.latitude,
            longitude: _driverPosition!.longitude,
          ),
          destination: _originPoint!,
        );
      });
    }
  }

  Future<void> _startLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    try {
      final current = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _driverPosition = LatLng(current.latitude, current.longitude);
        _driverHeading = current.heading >= 0 ? current.heading : null;
      });
      await _loadPickupRoute();
    } catch (_) {}

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 8,
      ),
    ).listen((pos) {
      if (!mounted) return;
      setState(() {
        _driverPosition = LatLng(pos.latitude, pos.longitude);
        if (pos.heading >= 0) _driverHeading = pos.heading;
      });
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
    if (_driverPosition != null && _originPoint != null) {
      return buildDegradedDirectRoute(
        origin: NeshanLatLng(
          latitude: _driverPosition!.latitude,
          longitude: _driverPosition!.longitude,
        ),
        destination: _originPoint!,
      );
    }
    return buildDegradedDirectRoute(
      origin: _originPoint!,
      destination: _originPoint!,
    );
  }

  RouteMapGeometry get _activeGeometry {
    if (_routeStep == 1) {
      return RouteMapGeometry.fromRoute(
        _activeRoute,
        origin: _originLatLng,
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

  Future<void> _openInNeshan() async {
    final dest = _routeStep == 0 ? _originPoint : _destinationPoint;
    if (dest == null) return;
    final uri = Uri.parse(
      'https://neshan.org/maps#@${dest.latitude},${dest.longitude},15z',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        appBar: ModernAppBar(title: l10n.routeTitle),
        body: LoadingOverlay(message: l10n.loadingRoute),
      );
    }

    if (_cargo == null) {
      return Scaffold(
        appBar: ModernAppBar(title: l10n.routeTitle),
        body: EmptyState(icon: Icons.map_outlined, title: l10n.routeNotFound),
      );
    }

    if (_error != null || _originPoint == null || _destinationPoint == null) {
      return Scaffold(
        appBar: ModernAppBar(title: l10n.routeTitle),
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

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: ModernAppBar(
        title: l10n.routeTitle,
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
                  origin: _routeStep == 0
                      ? (_driverPosition ?? _originLatLng)
                      : _originLatLng,
                  destination:
                      _routeStep == 0 ? _originLatLng : _destinationLatLng,
                  driverPosition: _driverPosition,
                  driverHeading: _driverHeading,
                  followDriver: _navigationActive && !_mapCameraDetached,
                  navigationMode: _navigationActive,
                  isDark: isDark,
                  overviewMode: !_navigationActive,
                  pickupLeg: _routeStep == 0,
                  returnToRouteLabel: l10n.returnToRoute,
                  controller: _mapController,
                  onCameraDetached: (detached) {
                    if (!mounted) return;
                    setState(() => _mapCameraDetached = detached);
                  },
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: palette.cardBg.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: palette.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(8),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            decoration: BoxDecoration(
              color: palette.cardBg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                    Row(
                      children: [
                        Icon(Icons.straighten, size: 16, color: palette.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          leg.distanceText,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.schedule, size: 16, color: palette.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          leg.durationText,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () {
                      final pos = _driverPosition;
                      setState(() {
                        _navigationActive = true;
                        _mapCameraDetached = false;
                      });
                      if (pos != null) {
                        _mapController.resumeNavigation(
                          position: pos,
                          heading: _driverHeading,
                        );
                      } else {
                        _mapController.refitOverview();
                      }
                    },
                    icon: const Icon(Icons.navigation_rounded),
                    label: Text(
                      l10n.startNavigationTo(
                        _routeStep == 0 ? l10n.origin : l10n.destination,
                      ),
                    ),
                  ),
                  if (_routeStep == 0) ...[
                    const SizedBox(height: 8),
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
        ],
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
    final color = isCompleted
        ? AppTheme.success
        : isActive
            ? AppTheme.primary
            : Colors.grey.shade400;

    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color,
          child: isCompleted
              ? const Icon(Icons.check, size: 18, color: Colors.white)
              : Text(
                  '$step',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
