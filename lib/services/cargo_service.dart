import 'package:flutter/foundation.dart';

import '../models/cargo.dart';
import '../models/driver_profile.dart';

/// Mock cargo service — replace with API calls later.
class CargoService extends ChangeNotifier {
  CargoService._();
  static final CargoService _instance = CargoService._();
  factory CargoService() => _instance;
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
      isNearby: true,
      nearbyDistanceKm: 8.5,
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
      isNearby: true,
      nearbyDistanceKm: 15.2,
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
      distanceKm: 5.2,
      currentLocation: 'تهران، آزادی',
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
      distanceKm: 12.8,
      currentLocation: 'کرج، مهرشهر',
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
      distanceKm: 25.0,
      currentLocation: 'ورامین',
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
      distanceKm: 8.1,
      currentLocation: 'تهران، شهرک صنعتی',
    ),
  ];

  Future<List<Cargo>> getAllCargos() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable(_cargos);
  }

  Future<List<Cargo>> getCargosForDriver(String cargoType) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _cargos
        .where((c) => c.cargoType == cargoType && c.status == 'در انتظار راننده')
        .toList();
  }

  Future<List<Cargo>> getNearbyCargos({String? cargoType}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _cargos
        .where(
          (c) =>
              c.isNearby &&
              c.status == 'در انتظار راننده' &&
              (cargoType == null || c.cargoType == cargoType),
        )
        .toList()
      ..sort((a, b) => (a.nearbyDistanceKm ?? 0).compareTo(b.nearbyDistanceKm ?? 0));
  }

  Future<List<Cargo>> getCoordinatorCargos(String coordinatorName) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _cargos.where((c) => c.coordinatorName == coordinatorName).toList();
  }

  Future<Cargo?> getCargoById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    try {
      return _cargos.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<DriverProfile>> getActiveDrivers() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _drivers.where((d) => d.isActive).toList();
  }

  Future<List<DriverProfile>> getNearbyDrivers() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _drivers
        .where((d) => d.isActive && (d.distanceKm ?? 100) < 20)
        .toList()
      ..sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
  }

  Future<int> estimatePrice({
    required String origin,
    required String destination,
    required String cargoType,
    required String goodsType,
    required double weightTons,
  }) async {
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
  }) async {
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
    );
    _cargos.insert(0, cargo);
    return cargo;
  }

  Future<List<Cargo>> getDriverMissions({
    required String driverPhone,
    String? driverName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _cargos
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

  Future<bool> acceptCargo(String cargoId, String driverName, String driverPhone) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final index = _cargos.indexWhere((c) => c.id == cargoId);
    if (index == -1) return false;
    _cargos[index] = _cargos[index].copyWith(
      status: 'تخصیص یافته',
      assignedDriverName: driverName,
      assignedDriverPhone: driverPhone,
    );
    notifyListeners();
    return true;
  }
}
