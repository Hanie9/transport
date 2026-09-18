import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../api_config.dart';
import '../l10n/api_messages.dart';
import '../models/cargo.dart';
import '../models/driver_bar_query.dart';
import '../models/driver_profile.dart';
import '../models/paginated_result.dart';
import 'api_client.dart';
import 'api_response.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'reference_data_service.dart';
import 'settings_service.dart';
import 'transport_api_mapper.dart';

/// Cargo / driver facade — configured Transport REST API (or mock).
class CargoService extends ChangeNotifier {
  CargoService._({ApiClient? apiClient, LocationService? locationService})
    : _api = apiClient ?? ApiClient(),
      _location = locationService ?? LocationService();

  /// Test-only constructor with injected API client.
  CargoService.withClient(
    ApiClient apiClient, {
    LocationService? locationService,
  }) : _api = apiClient,
       _location = locationService ?? LocationService();

  static final CargoService _instance = CargoService._();
  factory CargoService() => _instance;

  final ApiClient _api;
  final LocationService _location;

  String? _lastError;
  String? get lastError => _lastError;

  void _clearError() => _lastError = null;

  void _setError(Object error) {
    final isEnglish = SettingsService().isEnglish;
    if (error is ApiException) {
      _lastError = error.message;
      return;
    }

    final text = error.toString();
    if (text.contains('SocketException') ||
        text.contains('Failed host lookup') ||
        text.contains('Network is unreachable') ||
        text.contains('Connection refused')) {
      _lastError = ApiMessages.noInternet(isEnglish: isEnglish);
      return;
    }

    if (error is FormatException) {
      _lastError = ApiMessages.invalidServerResponse(isEnglish: isEnglish);
      return;
    }

    _lastError = ApiResponse.httpErrorMessage(
      rawBody: text,
      isEnglish: isEnglish,
    );
  }

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
      status: 'تخصیص یافته',
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

  Future<List<Cargo>> getAllCargos({Map<String, String>? query}) async {
    _clearError();
    try {
      if (!ApiConfig.shouldUseMock) {
        final data = await _api.get(ApiConfig.operatorBarsPath, query: query);
        final list = ApiResponse.extractList(data);
        return list.map(TransportApiMapper.cargoFromBar).toList();
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return List.unmodifiable(_cargos);
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Future<PaginatedResult<Cargo>> getDriverBarsPage({
    DriverBarQuery? query,
    int page = 1,
  }) async {
    if (!ApiConfig.shouldUseMock) {
      try {
        final params = {...?query?.toQueryParameters(), 'page': '$page'};
        final data = await _api.get(ApiConfig.driverBarsPath, query: params);
        final list = ApiResponse.extractList(data);
        final meta = ApiResponse.extractPagination(data);
        return PaginatedResult(
          items: list.map(TransportApiMapper.cargoFromBar).toList(),
          count: meta.count,
          currentPage: meta.currentPage,
          totalPages: meta.totalPages,
          hasNext: meta.hasNext,
        );
      } catch (e) {
        _setError(e);
        return const PaginatedResult(
          items: [],
          count: 0,
          currentPage: 1,
          totalPages: 1,
          hasNext: false,
        );
      }
    }

    final all = await getCargosForDriver('');
    return PaginatedResult(
      items: all,
      count: all.length,
      currentPage: 1,
      totalPages: 1,
      hasNext: false,
    );
  }

  Future<List<Cargo>> getCargosForDriver(
    String cargoType, {
    DriverBarQuery? query,
  }) async {
    if (!ApiConfig.shouldUseMock) {
      try {
        final page = await getDriverBarsPage(query: query);
        return page.items;
      } catch (e) {
        _setError(e);
        return const [];
      }
    }

    final all = await getAllCargos();
    return all
        .where(
          (c) => c.cargoType == cargoType && c.status == 'در انتظار راننده',
        )
        .toList();
  }

  Future<List<Cargo>> getNearbyCargos({
    String? cargoType,
    double radiusKm = nearbyRadiusKm,
    LatLng? driverPosition,
  }) async {
    _clearError();
    final pos =
        driverPosition ??
        await _location.getCurrentPosition(requestIfNeeded: false);
    if (pos == null) return const [];

    if (!ApiConfig.shouldUseMock) {
      try {
        final open = await getCargosForDriver(cargoType ?? '');
        final pos =
            driverPosition ??
            await _location.getCurrentPosition(requestIfNeeded: false);
        if (pos == null) {
          return open.map((c) => c.copyWith(isNearby: true)).toList();
        }

        final results = <Cargo>[];
        for (final cargo in open) {
          if (!cargo.hasOriginCoords) continue;
          final km = _location.distanceKm(
            pos,
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
          (a, b) =>
              (a.nearbyDistanceKm ?? 0).compareTo(b.nearbyDistanceKm ?? 0),
        );
        return results;
      } catch (e) {
        _setError(e);
        return const [];
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 350));

    final results = <Cargo>[];
    for (final cargo in _cargos) {
      if (cargo.status != 'در انتظار راننده') continue;
      if (cargoType != null && cargo.cargoType != cargoType) continue;
      if (!cargo.hasOriginCoords) continue;

      final km = _location.distanceKm(
        pos,
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

  /// Coordinator cargos — backend filters by authenticated user (`mine=true`).
  Future<List<Cargo>> getCoordinatorCargos() async {
    if (!ApiConfig.shouldUseMock) {
      try {
        final data = await _api.get(ApiConfig.operatorBarsPath);
        final list = ApiResponse.extractList(data);
        return list.map(TransportApiMapper.cargoFromBar).toList();
      } catch (e) {
        _setError(e);
        return const [];
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_cargos);
  }

  Future<Cargo?> _findOpenDriverBar(String id, {DriverBarQuery? query}) async {
    var page = 1;
    while (true) {
      final result = await getDriverBarsPage(query: query, page: page);
      for (final cargo in result.items) {
        if (cargo.id == id) return cargo;
      }
      if (!result.hasNext) break;
      page += 1;
    }
    return null;
  }

  Future<Cargo?> getCargoById(String id) async {
    _clearError();
    try {
      if (!ApiConfig.shouldUseMock) {
        try {
          final data = await _api.get(ApiConfig.operatorBarDetailPath(id));
          return TransportApiMapper.cargoFromBar(
            ApiResponse.extractObject(data),
          );
        } catch (_) {}

        final open = await _findOpenDriverBar(id);
        if (open != null) return open;

        return DriverMissionStore.instance.findById(id);
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
      try {
        return _cargos.firstWhere((c) => c.id == id);
      } catch (_) {
        return null;
      }
    } catch (e) {
      _setError(e);
      return null;
    }
  }

  Future<List<DriverProfile>> getActiveDrivers() async {
    _clearError();
    if (!ApiConfig.shouldUseMock) {
      return const [];
    }
    try {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return _drivers.where((d) => d.isActive).toList();
    } catch (e) {
      _setError(e);
      return const [];
    }
  }

  Future<List<DriverProfile>> getNearbyDrivers({
    double? originLat,
    double? originLng,
    double radiusKm = nearbyRadiusKm,
  }) async {
    _clearError();
    if (!ApiConfig.shouldUseMock) {
      return const [];
    }

    await Future<void>.delayed(const Duration(milliseconds: 350));
    final LatLng? center;
    if (originLat != null && originLng != null) {
      center = LatLng(originLat, originLng);
    } else {
      center = await _location.getCurrentPosition(requestIfNeeded: false);
    }
    if (center == null) return const [];

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
    _clearError();
    if (!ApiConfig.shouldUseMock) {
      final base = 5000000;
      final distanceFactor = (origin.length + destination.length) * 150000;
      final weightFactor = (weightTons * 200000).toInt();
      return base + distanceFactor + weightFactor;
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
    String? coordinatorName,
    String? description,
    int? productId,
    int? machineId,
    int? ostanMabdaId,
    int? ostanMaghsadId,
    double? originLat,
    double? originLng,
    double? destinationLat,
    double? destinationLng,
  }) async {
    _clearError();
    if (!ApiConfig.shouldUseMock) {
      final data = await _api.post(
        ApiConfig.operatorBarCreatePath,
        body: TransportApiMapper.barPayload(
          title: title,
          description: TransportApiMapper.descriptionWithWeight(
            description ?? goodsType,
            weightTons,
          ),
          price: estimatedPrice,
          productId: productId,
          machineId: machineId,
          ostanMabdaId: ostanMabdaId,
          ostanMaghsadId: ostanMaghsadId,
          addressMabda: origin,
          addressMaghsad: destination,
          originLat: originLat,
          originLng: originLng,
          destinationLat: destinationLat,
          destinationLng: destinationLng,
        ),
      );
      final cargo = TransportApiMapper.cargoFromBar(
        ApiResponse.extractObject(data),
      );
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
      coordinatorName: coordinatorName ?? '',
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
    String? driverPhone,
    String? driverName,
  }) async {
    _clearError();
    if (!ApiConfig.shouldUseMock) {
      final missions = await DriverMissionStore.instance.load();
      final filtered = missions.where((mission) {
        if (driverPhone == null && driverName == null) return true;
        if (driverPhone != null && mission.assignedDriverPhone == driverPhone) {
          return true;
        }
        return driverName != null && mission.assignedDriverName == driverName;
      }).toList();
      filtered.sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
      return filtered;
    }

    final all = await getAllCargos();
    return all
        .where(
          (c) =>
              c.status != 'در انتظار راننده' &&
              c.status != 'لغو شده' &&
              (driverPhone == null ||
                  c.assignedDriverPhone == driverPhone ||
                  (driverName != null && c.assignedDriverName == driverName)),
        )
        .toList()
      ..sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
  }

  Future<bool> acceptCargo(
    String cargoId,
    String driverName,
    String driverPhone, {
    int? driverMachineId,
  }) async {
    _clearError();
    try {
      if (!ApiConfig.shouldUseMock) {
        final existing = await getCargoById(cargoId);
        if (existing != null &&
            existing.machineId != null &&
            driverMachineId != null &&
            existing.machineId != driverMachineId) {
          throw ApiException(
            ApiMessages.machineMismatch(
              isEnglish: SettingsService().isEnglish,
              requiredMachine: existing.cargoType,
            ),
          );
        }

        final response = ApiResponse.extractObject(
          await _api.post(ApiConfig.driverBarAcceptPath(cargoId)),
        );
        if (response['error'] != null) {
          throw ApiException(response['error'].toString());
        }

        final assign = response['assign_info'];
        Map<String, dynamic>? assignMap;
        if (assign is Map) {
          assignMap = Map<String, dynamic>.from(assign);
        }

        final mission =
            (existing ??
                    Cargo(
                      id: cargoId,
                      title: '',
                      origin: '',
                      destination: '',
                      cargoType: '',
                      goodsType: '',
                      weightTons: 0,
                      estimatedPrice: 0,
                      status: 'تخصیص یافته',
                      coordinatorName: '',
                    ))
                .copyWith(
                  status: 'تخصیص یافته',
                  createdAt:
                      existing?.createdAt ??
                      DateTime.tryParse('${assignMap?['created_at'] ?? ''}'),
                  assignedDriverName:
                      assignMap?['driver_name']?.toString() ?? driverName,
                  assignedDriverPhone:
                      assignMap?['driver_phone']?.toString() ?? driverPhone,
                );
        await DriverMissionStore.instance.upsert(mission);
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
      NotificationService().pushLocal(
        'بار «${_cargos[index].title}» پذیرفته شد',
      );
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  Future<bool> deleteCargo(String cargoId) async {
    _clearError();
    try {
      if (!ApiConfig.shouldUseMock) {
        await _api.delete(ApiConfig.operatorBarDeletePath(cargoId));
        await DriverMissionStore.instance.remove(cargoId);
        notifyListeners();
        return true;
      }

      await Future<void>.delayed(const Duration(milliseconds: 300));
      _cargos.removeWhere((c) => c.id == cargoId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  Future<bool> updateCargo({
    required String cargoId,
    String? title,
    String? description,
    int? price,
    int? productId,
    int? machineId,
    int? ostanMabdaId,
    int? ostanMaghsadId,
    String? addressMabda,
    String? addressMaghsad,
    double? originLat,
    double? originLng,
    double? destinationLat,
    double? destinationLng,
    String? status,
    bool fullReplace = false,
  }) async {
    _clearError();
    try {
      if (!ApiConfig.shouldUseMock) {
        final body = TransportApiMapper.barPayload(
          title: title,
          description: description,
          price: price,
          productId: productId,
          machineId: machineId,
          ostanMabdaId: ostanMabdaId,
          ostanMaghsadId: ostanMaghsadId,
          addressMabda: addressMabda,
          addressMaghsad: addressMaghsad,
          originLat: originLat,
          originLng: originLng,
          destinationLat: destinationLat,
          destinationLng: destinationLng,
          status: status,
        );
        if (fullReplace) {
          await _api.put(ApiConfig.operatorBarUpdatePath(cargoId), body: body);
        } else {
          await _api.patch(
            ApiConfig.operatorBarUpdatePath(cargoId),
            body: body,
          );
        }
        if (status != null) {
          await DriverMissionStore.instance.updateStatus(cargoId, status);
        }
        notifyListeners();
        return true;
      }

      await Future<void>.delayed(const Duration(milliseconds: 300));
      final index = _cargos.indexWhere((c) => c.id == cargoId);
      if (index == -1) return false;
      _cargos[index] = _cargos[index].copyWith(
        title: title,
        description: description,
        estimatedPrice: price,
        status: status,
      );
      if (status != null) {
        NotificationService().pushLocal('وضعیت بار به «$status» تغییر کرد');
      }
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  Future<bool> updateCargoStatus(String cargoId, String status) async {
    return updateCargo(cargoId: cargoId, status: status);
  }

  Future<void> reportDriverLocation({
    required double lat,
    required double lng,
  }) async {
    if (ApiConfig.shouldUseMock) return;
  }
}
