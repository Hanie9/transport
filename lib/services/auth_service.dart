import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../models/user_role.dart';

/// Mock auth service — replace with API calls later.
class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  Future<bool> login({
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 800));

    _currentUser = User(
      id: role == UserRole.driver ? 'driver-1' : 'coord-1',
      fullName: role == UserRole.driver ? 'علی محمدی' : 'رضا کریمی',
      phone: phone,
      role: role,
      vehicleInfo: role == UserRole.driver
          ? const VehicleInfo(
              plateNumber: '۱۲ ب ۳۴۵ ایران ۶۶',
              cargoType: 'کفی',
              vehicleModel: 'ولوو FH460',
              capacityTons: 24,
            )
          : null,
    );

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> signup({
    required String fullName,
    required String phone,
    required String password,
    required UserRole role,
    String? email,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 1000));

    _currentUser = User(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      phone: phone,
      email: email,
      role: role,
    );

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> updateVehicleInfo(VehicleInfo info) async {
    if (_currentUser == null) return;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _currentUser = _currentUser!.copyWith(vehicleInfo: info);
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
