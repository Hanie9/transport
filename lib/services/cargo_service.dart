import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../api_config.dart';
import '../models/cargo.dart';
import '../models/driver_profile.dart';
import 'api_client.dart';
import 'location_service.dart';
import 'notification_service.dart';

/// Cargo / driver facade — mock data now, REST when [ApiConfig.shouldUseMock] is false.
class CargoService extends ChangeNotifier {
  CargoService._({ApiClient? apiClient, LocationService? locationService})
      : _api = apiClient ?? ApiClient(),
        _location = locationService ?? LocationService();

  static final CargoService _instance = CargoService._();
  factory CargoService() => _instance;

  final ApiClient _api;
  final LocationService _location;

  static const double nearbyRadiusKm = 25;

  static final List<Cargo> _cargos = [
    Cargo(
      id: 'cargo-1',
      title: 'حمل سیمان به اصفهان',
      origin: 'تهران، شهرک صنعتی',
      destination: 'اصفهان، شهرک صنعتی محمودآباد',
      cargoType: 'کفی',
      goodsType: 'مصالح ساختمانی',
      weightTons: 22,
      estimatedPrice: 18500000,
      status: 'در انتظار راننده',
      coordinatorName: 'رضا کریمی',
      distanceKm: 420,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      originLat: 35.6892,
      originLng: 51.3890,
      destinationLat: 32.6539,
      destinationLng: 51.6660,
    ),
    Cargo(
      id: 'cargo-2',
      title: 'حمل مواد غذایی یخچالی',
      origin: 'کرج، مهرشهر',
      destination: 'قم، شهرک صنعتی',
      cargoType: 'یخچالی',
      goodsType: 'مواد غذایی',
      weightTons: 12,
      estimatedPrice: 9200000,
      status: 'در انتظار راننده',
      coordinatorName: 'مریم احمدی',
      distanceKm: 180,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      originLat: 35.8400,
      originLng: 50.9391,
      destinationLat: 34.6416,
      destinationLng: 50.8746,
    ),
    Cargo(
      id: 'cargo-3',
      title: 'حمل محصولات کشاورزی',
      origin: 'ساری',
      destination: 'تهران، بازار میوه و تره‌بار',
      cargoType: 'کمپرسی',
      goodsType: 'محصولات کشاورزی',
      weightTons: 18,
      estimatedPrice: 14800000,
      status: 'تخصیص یافته',
      coordinatorName: 'حسین رضایی',
      distanceKm: 280,
      assignedDriverName: 'محمد حسینی',
      assignedDriverPhone: '09121234567',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      originLat: 36.5633,
      originLng: 53.0601,
      destinationLat: 35.6892,
      destinationLng: 51.3890,
    ),
    Cargo(
      id: 'cargo-4',
      title: 'حمل مواد شیمیایی',
      origin: 'بندرعباس',
      destination: 'یزد، شهرک صنعتی',
      cargoType: 'تانکر',
      goodsType: 'مواد شیمیایی',
      weightTons: 20,
      estimatedPrice: 25600000,
      status: 'در حال حمل',
      coordinatorName: 'رضا کریمی',
      distanceKm: 650,
      assignedDriverName: 'علی محمدی',
      assignedDriverPhone: '09129876543',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      originLat: 27.1865,
      originLng: 56.2808,
      destinationLat: 31.8974,
      destinationLng: 54.3569,
    ),
    Cargo(
      id: 'cargo-5',
      title: 'حمل لوازم خانگی',
      origin: 'تهران، شهریار',
      destination: 'مشهد، شهرک صنعتی توس',
      cargoType: 'کانتینربر',
      goodsType: 'لوازم خانگی',
      weightTons: 16,
      estimatedPrice: 32000000,
      status: 'تحویل شده',
      coordinatorName: 'رضا کریمی',
      distanceKm: 900,
      assignedDriverName: 'حسن مرادی',
      assignedDriverPhone: '09131112233',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      originLat: 35.6581,
      originLng: 51.0594,
      destinationLat: 36.2970,
      destinationLng: 59.6062,
    ),
    Cargo(
      id: 'cargo-6',
      title: 'حمل قطعات صنعتی',
      origin: 'تهران، آزادی',
      destination: 'کرج، مهرشهر',
      cargoType: 'کفی',
      goodsType: 'قطعات صنعتی',
      weightTons: 14,
      estimatedPrice: 6500000,
      status: 'در انتظار راننده',
      coordinatorName: 'رضا کریمی',
      distanceKm: 45,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      originLat: 35.6997,
      originLng: 51.3380,
      destinationLat: 35.8400,
      destinationLng: 50.9391,
    ),
  ];

  static final List<DriverProfile> _drivers = [
    const DriverProfile(
      id: 'driver-1',
      fullName: 'علی محمدی',
      phone: '09129876543',
      cargoType: 'کفی',
      plateNumber: '۱۲ ب ۳۴۵ ایران ۶۶',
      vehicleModel: 'ولوو FH460',
      isActive: true,
      rating: 4.8,
      completedTrips: 156,
      currentLocation: 'تهران، آزادی',
      lat: 35.6997,
      lng: 51.3380,
    ),
    const DriverProfile(
      id: 'driver-2',
      fullName: 'محمد حسینی',
      phone: '09121234567',
      cargoType: 'یخچالی',
      plateNumber: '۴۵ ج ۶۷۸ ایران ۲۲',
      vehicleModel: 'بنز اکتروس',
      isActive: true,
      rating: 4.6,
      completedTrips: 98,
      currentLocation: 'کرج، مهرشهر',
      lat: 35.8400,
      lng: 50.9391,
    ),
    const DriverProfile(
      id: 'driver-3',
      fullName: 'حسن مرادی',
      phone: '09131112233',
      cargoType: 'کمپرسی',
      plateNumber: '۷۸ د ۹۰۱ ایران ۴۴',
      vehicleModel: 'اسکانیا R500',
      isActive: false,
      rating: 4.5,
      completedTrips: 72,
      currentLocation: 'ورامین',
      lat: 35.3242,
      lng: 51.6472,
    ),
    const DriverProfile(
      id: 'driver-4',
      fullName: 'رضا نوری',
      phone: '09145556677',
      cargoType: 'تانکر',
      plateNumber: '۳۴ الف ۵۶۷ ایران ۱۱',
      vehicleModel: 'ولوو FM',
      isActive: true,
      rating: 4.9,
      completedTrips: 210,
      currentLocation: 'تهران، شهرک صنعتی',
      lat: 35.6200,
      lng: 51.4200,
    ),
  ];

  Future<List<Cargo>> getAllCargos() async {
    if (!ApiConfig.shouldUseMock) {
      final data = await _api.get(ApiConfig.cargosPath);
      final list = (data['results'] ?? data['data'] ?? data) as dynamic;
      if (list is List) {
        return list
            .whereType<Map>()
            .map((e) => Cargo.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable(_cargos);
  }

  Future<List<Cargo>> getCargosForDriver(String cargoType) async {
    final all = await getAllCargos();
    return all
        .where((c) => c.cargoType == cargoType && c.status == 'در انتظار راننده')
        .toList();
  }

  /// Nearby cargos using device GPS distance to cargo origin.
  Future<List<Cargo>> getNearbyCargos({
    String? cargoType,
    double radiusKm = nearbyRadiusKm,
  }) async {
    if (!ApiConfig.shouldUseMock) {
      final pos = await _location.getCurrentPosition();
      final data = await _api.get(
        ApiConfig.nearbyCargosPath,
        query: {
          if (pos != null) 'lat': '${pos.latitude}',
          if (pos != null) 'lng': '${pos.longitude}',
          'radius_km': '$radiusKm',
          if (cargoType != null) 'cargo_type': cargoType,
        },
      );
      final list = (data['results'] ?? data['data'] ?? data) as dynamic;
      if (list is List) {
        return list
            .whereType<Map>()
            .map((e) => Cargo.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 350));
    final pos = await _location.getCurrentPosition();
    // Fallback center (Tehran) when GPS unavailable — still ranks by distance.
    final center = pos ?? const LatLng(35.6892, 51.3890);

    final results = <Cargo>[];
    for (final cargo in _cargos) {
      if (cargo.status != 'در انتظار راننده') continue;
      if (cargoType != null && cargo.cargoType != cargoType) continue;
      if (!cargo.hasOriginCoords) continue;

      final km = _location.distanceKm(
        center,
        LatLng(cargo.originLat!, cargo.originLng!),
      );
      if (km <= radiusKm) {
        results.add(
          cargo.copyWith(
            isNearby: true,
            nearbyDistanceKm: double.parse(km.toStringAsFixed(1)),
          ),
        );
      }
    }
    results.sort(
      (a, b) => (a.nearbyDistanceKm ?? 0).compareTo(b.nearbyDistanceKm ?? 0),
    );
    return results;
  }

  Future<List<Cargo>> getCoordinatorCargos(String coordinatorName) async {
    final all = await getAllCargos();
    return all.where((c) => c.coordinatorName == coordinatorName).toList();
  }

  Future<Cargo?> getCargoById(String id) async {
    if (!ApiConfig.shouldUseMock) {
      final data = await _api.get('${ApiConfig.cargosPath}$id/');
      return Cargo.fromJson(data);
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
    try {
      return _cargos.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<DriverProfile>> getActiveDrivers() async {
    if (!ApiConfig.shouldUseMock) {
      final data = await _api.get(ApiConfig.driversPath, query: {'active': 'true'});
      final list = (data['results'] ?? data['data'] ?? data) as dynamic;
      if (list is List) {
        return list
            .whereType<Map>()
            .map((e) => DriverProfile.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _drivers.where((d) => d.isActive).toList();
  }

  Future<List<DriverProfile>> getNearbyDrivers({
    double? originLat,
    double? originLng,
    double radiusKm = nearbyRadiusKm,
  }) async {
    if (!ApiConfig.shouldUseMock) {
      final data = await _api.get(
        ApiConfig.nearbyDriversPath,
        query: {
          if (originLat != null) 'lat': '$originLat',
          if (originLng != null) 'lng': '$originLng',
          'radius_km': '$radiusKm',
        },
      );
      final list = (data['results'] ?? data['data'] ?? data) as dynamic;
      if (list is List) {
        return list
            .whereType<Map>()
            .map((e) => DriverProfile.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 350));
    LatLng center;
    if (originLat != null && originLng != null) {
      center = LatLng(originLat, originLng);
    } else {
      center = await _location.getCurrentPosition() ??
          const LatLng(35.6892, 51.3890);
    }

    final results = <DriverProfile>[];
    for (final driver in _drivers) {
      if (!driver.isActive || !driver.hasCoords) continue;
      final km = _location.distanceKm(center, LatLng(driver.lat!, driver.lng!));
      if (km <= radiusKm) {
        results.add(
          driver.copyWith(distanceKm: double.parse(km.toStringAsFixed(1))),
        );
      }
    }
    results.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
    return results;
  }

  Future<int> estimatePrice({
    required String origin,
    required String destination,
    required String cargoType,
    required String goodsType,
    required double weightTons,
  }) async {
    if (!ApiConfig.shouldUseMock) {
      final data = await _api.post(
        ApiConfig.estimatePricePath,
        body: {
          'origin': origin,
          'destination': destination,
          'cargo_type': cargoType,
          'goods_type': goodsType,
          'weight_tons': weightTons,
        },
      );
      return int.tryParse('${data['estimated_price'] ?? data['price'] ?? 0}') ?? 0;
    }

    await Future<void>.delayed(const Duration(milliseconds: 600));
    final base = 5000000;
    final distanceFactor = (origin.length + destination.length) * 150000;
    final weightFactor = (weightTons * 200000).toInt();
    final typeFactor = cargoType == 'یخچالی' ? 2000000 : 0;
    return base + distanceFactor + weightFactor + typeFactor;
  }

  Future<Cargo> createCargo({
    required String title,
    required String origin,
    required String destination,
    required String cargoType,
    required String goodsType,
    required double weightTons,
    required int estimatedPrice,
    required String coordinatorName,
    double? originLat,
    double? originLng,
    double? destinationLat,
    double? destinationLng,
  }) async {
    if (!ApiConfig.shouldUseMock) {
      final data = await _api.post(
        ApiConfig.cargosPath,
        body: {
          'title': title,
          'origin': origin,
          'destination': destination,
          'cargo_type': cargoType,
          'goods_type': goodsType,
          'weight_tons': weightTons,
          'estimated_price': estimatedPrice,
          if (originLat != null) 'origin_lat': originLat,
          if (originLng != null) 'origin_lng': originLng,
          if (destinationLat != null) 'destination_lat': destinationLat,
          if (destinationLng != null) 'destination_lng': destinationLng,
        },
      );
      final cargo = Cargo.fromJson(data);
      notifyListeners();
      return cargo;
    }

    await Future<void>.delayed(const Duration(milliseconds: 800));
    final cargo = Cargo(
      id: 'cargo-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      origin: origin,
      destination: destination,
      cargoType: cargoType,
      goodsType: goodsType,
      weightTons: weightTons,
      estimatedPrice: estimatedPrice,
      status: 'در انتظار راننده',
      coordinatorName: coordinatorName,
      createdAt: DateTime.now(),
      originLat: originLat,
      originLng: originLng,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
    );
    _cargos.insert(0, cargo);
    NotificationService().pushLocal('بار جدید ثبت شد: $title');
    notifyListeners();
    return cargo;
  }

  Future<List<Cargo>> getDriverMissions({
    required String driverPhone,
    String? driverName,
  }) async {
    final all = await getAllCargos();
    return all
        .where(
          (c) =>
              c.status != 'در انتظار راننده' &&
              c.status != 'لغو شده' &&
              (c.assignedDriverPhone == driverPhone ||
                  (driverName != null && c.assignedDriverName == driverName)),
        )
        .toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
  }

  Future<bool> acceptCargo(
    String cargoId,
    String driverName,
    String driverPhone,
  ) async {
    if (!ApiConfig.shouldUseMock) {
      await _api.post(
        ApiConfig.acceptCargoPath.replaceFirst('{id}', cargoId),
        body: {
          'driver_name': driverName,
          'driver_phone': driverPhone,
        },
      );
      notifyListeners();
      NotificationService().pushLocal('بار پذیرفته شد');
      return true;
    }

    await Future<void>.delayed(const Duration(milliseconds: 600));
    final index = _cargos.indexWhere((c) => c.id == cargoId);
    if (index == -1) return false;
    _cargos[index] = _cargos[index].copyWith(
      status: 'تخصیص یافته',
      assignedDriverName: driverName,
      assignedDriverPhone: driverPhone,
    );
    NotificationService().pushLocal('بار «${_cargos[index].title}» پذیرفته شد');
    notifyListeners();
    return true;
  }

  Future<bool> updateCargoStatus(String cargoId, String status) async {
    if (!ApiConfig.shouldUseMock) {
      await _api.patch(
        ApiConfig.cargoStatusPath.replaceFirst('{id}', cargoId),
        body: {'status': status},
      );
      notifyListeners();
      return true;
    }

    await Future<void>.delayed(const Duration(milliseconds: 400));
    final index = _cargos.indexWhere((c) => c.id == cargoId);
    if (index == -1) return false;
    _cargos[index] = _cargos[index].copyWith(status: status);
    NotificationService().pushLocal('وضعیت بار به «$status» تغییر کرد');
    notifyListeners();
    return true;
  }

  /// Reports driver GPS to backend (no-op in mock aside from local cache).
  Future<void> reportDriverLocation({
    required double lat,
    required double lng,
  }) async {
    if (!ApiConfig.shouldUseMock) {
      await _api.post(
        ApiConfig.reportLocationPath,
        body: {
          'lat': lat,
          'lng': lng,
          'reported_at': DateTime.now().toIso8601String(),
        },
      );
    }
  }
}
