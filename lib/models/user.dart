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

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: '${json['id'] ?? ''}',
      fullName: (json['full_name'] ?? json['fullName'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: json['email']?.toString(),
      role: UserRole.fromApi((json['role'] ?? json['user_type'])?.toString()),
      vehicleInfo: json['vehicle'] is Map<String, dynamic>
          ? VehicleInfo.fromJson(json['vehicle'] as Map<String, dynamic>)
          : json['vehicle_info'] is Map<String, dynamic>
              ? VehicleInfo.fromJson(json['vehicle_info'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'phone': phone,
        if (email != null) 'email': email,
        'role': role.apiValue,
        if (vehicleInfo != null) 'vehicle': vehicleInfo!.toJson(),
      };
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

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      plateNumber: (json['plate_number'] ?? json['plateNumber'] ?? '').toString(),
      cargoType: (json['cargo_type'] ?? json['cargoType'] ?? '').toString(),
      vehicleModel: (json['vehicle_model'] ?? json['vehicleModel'] ?? '').toString(),
      capacityTons: (json['capacity_tons'] ?? json['capacityTons']) == null
          ? null
          : double.tryParse('${json['capacity_tons'] ?? json['capacityTons']}'),
    );
  }

  Map<String, dynamic> toJson() => {
        'plate_number': plateNumber,
        'cargo_type': cargoType,
        'vehicle_model': vehicleModel,
        if (capacityTons != null) 'capacity_tons': capacityTons,
      };
}
