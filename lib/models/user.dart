import 'user_role.dart';

class User {
  const User({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.role,
    this.email,
    this.vehicleInfo,
  });

  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final UserRole role;
  final VehicleInfo? vehicleInfo;

  User copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    UserRole? role,
    VehicleInfo? vehicleInfo,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
    );
  }
}

class VehicleInfo {
  const VehicleInfo({
    required this.plateNumber,
    required this.cargoType,
    required this.vehicleModel,
    this.capacityTons,
  });

  final String plateNumber;
  final String cargoType;
  final String vehicleModel;
  final double? capacityTons;
}
