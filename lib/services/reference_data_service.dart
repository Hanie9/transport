import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../api_config.dart';
import '../models/api_reference_item.dart';
import '../models/cargo.dart';
import 'api_client.dart';
import 'api_response.dart';
import 'transport_api_mapper.dart';

class ReferenceDataService {
  ReferenceDataService({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<ApiReferenceItem>> getProducts() =>
      _fetchList(ApiConfig.productsPath);

  Future<List<ApiReferenceItem>> getMachines() =>
      _fetchList(ApiConfig.machinesPath);

  Future<List<ApiReferenceItem>> getOstans() =>
      _fetchList(ApiConfig.ostansPath);

  Future<List<ApiReferenceItem>> _fetchList(String path) async {
    final data = await _api.get(path);
    return ApiResponse.extractList(
      data,
    ).map(ApiReferenceItem.fromJson).toList();
  }
}

/// Persists driver missions accepted via the live API (no dedicated missions endpoint).
class DriverMissionStore {
  DriverMissionStore._();

  static const _key = 'driver_missions_v1';
  static final DriverMissionStore instance = DriverMissionStore._();

  Future<List<Cargo>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map(
            (e) =>
                TransportApiMapper.cargoFromBar(Map<String, dynamic>.from(e)),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> upsert(Cargo cargo) async {
    final missions = (await load()).toList();
    final index = missions.indexWhere((m) => m.id == cargo.id);
    if (index >= 0) {
      missions[index] = cargo;
    } else {
      missions.insert(0, cargo);
    }
    await _save(missions);
  }

  Future<Cargo?> findById(String id) async {
    final missions = await load();
    for (final mission in missions) {
      if (mission.id == id) return mission;
    }
    return null;
  }

  Future<void> remove(String id) async {
    final missions = (await load()).toList();
    missions.removeWhere((m) => m.id == id);
    await _save(missions);
  }

  Future<void> updateStatus(String id, String status) async {
    final missions = (await load()).toList();
    final index = missions.indexWhere((m) => m.id == id);
    if (index == -1) return;
    missions[index] = missions[index].copyWith(status: status);
    await _save(missions);
  }

  Future<void> replaceAll(List<Cargo> missions) async {
    await _save(missions);
  }

  Future<void> _save(List<Cargo> missions) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = missions
        .map(
          (c) => {
            'id': int.tryParse(c.id) ?? c.id,
            'title': c.title,
            'description': c.description ?? '',
            'price': c.estimatedPrice,
            'status': TransportApiMapper.apiStatusForApp(c.status) ?? 'assign',
            'status_display': c.status,
            'operator_name': c.coordinatorName,
            'product_name': c.goodsType,
            'machine_name': c.cargoType,
            if (c.productId != null) 'product': c.productId,
            if (c.machineId != null) 'machine': c.machineId,
            'address_mabda': c.origin,
            'address_maghsad': c.destination,
            'latitude_mabda': c.originLat,
            'longitude_mabda': c.originLng,
            'latitude_maghsad': c.destinationLat,
            'longitude_maghsad': c.destinationLng,
            'created_at': c.createdAt?.toIso8601String(),
            if (c.assignedDriverName != null)
              'assign_info': {
                'driver_name': c.assignedDriverName,
                'driver_phone': c.assignedDriverPhone,
              },
          },
        )
        .toList();
    await prefs.setString(_key, jsonEncode(payload));
  }
}
