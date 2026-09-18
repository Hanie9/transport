import 'user_role.dart';

class User {
  const User({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.role,
    this.email,
    this.nationalCode,
    this.vehicleInfo,
  });

  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String? nationalCode;
  final UserRole role;
  final VehicleInfo? vehicleInfo;

  User copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    String? nationalCode,
    UserRole? role,
    VehicleInfo? vehicleInfo,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      nationalCode: nationalCode ?? this.nationalCode,
      role: role ?? this.role,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final firstName = (json['first_name'] ?? '').toString().trim();
    final lastName = (json['last_name'] ?? '').toString().trim();
    final apiFullName = [
      firstName,
      lastName,
    ].where((v) => v.isNotEmpty).join(' ');
    final driverInfo = json['driver_info'];
    final embeddedVehicle = json['vehicle'] is Map<String, dynamic>
        ? VehicleInfo.fromJson(json['vehicle'] as Map<String, dynamic>)
        : json['vehicle_info'] is Map<String, dynamic>
        ? VehicleInfo.fromJson(json['vehicle_info'] as Map<String, dynamic>)
        : driverInfo is Map
        ? VehicleInfo.fromJson(Map<String, dynamic>.from(driverInfo))
        : null;
    final topLevelOstanId = int.tryParse('${json['ostan_id'] ?? ''}');
    final topLevelOstanName = json['ostan_name']?.toString();
    return User(
      id: '${json['id'] ?? ''}',
      fullName: (json['full_name'] ?? json['fullName'] ?? apiFullName)
          .toString(),
      phone: (json['phone_number'] ?? json['phone'] ?? '').toString(),
      email: json['email']?.toString(),
      nationalCode: json['national_code']?.toString(),
      role: UserRole.fromApiUser(json),
      vehicleInfo:
          embeddedVehicle ??
          (topLevelOstanId != null || topLevelOstanName?.isNotEmpty == true
              ? VehicleInfo(
                  plateNumber: '',
                  cargoType: '',
                  vehicleModel: '',
                  ostanId: topLevelOstanId,
                  ostanName: topLevelOstanName,
                )
              : null),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'phone': phone,
    if (email != null) 'email': email,
    if (nationalCode != null) 'national_code': nationalCode,
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
    this.machineId,
    this.ostanId,
    this.ostanName,
  });

  final String plateNumber;
  final String cargoType;
  final String vehicleModel;
  final double? capacityTons;
  final int? machineId;
  final int? ostanId;
  final String? ostanName;

  bool get isCompleteForCargoAcceptance =>
      plateNumber.trim().isNotEmpty &&
      vehicleModel.trim().isNotEmpty &&
      cargoType.trim().isNotEmpty;

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      plateNumber: (json['plate_number'] ?? json['plateNumber'] ?? '')
          .toString(),
      cargoType:
          (json['cargo_type'] ??
                  json['cargoType'] ??
                  json['machine_name'] ??
                  '')
              .toString(),
      vehicleModel: (json['vehicle_model'] ?? json['vehicleModel'] ?? '')
          .toString(),
      capacityTons: (json['capacity_tons'] ?? json['capacityTons']) == null
          ? null
          : double.tryParse('${json['capacity_tons'] ?? json['capacityTons']}'),
      machineId: int.tryParse(
        '${json['machine_id'] ?? json['machineId'] ?? ''}',
      ),
      ostanId: int.tryParse('${json['ostan_id'] ?? json['ostanId'] ?? ''}'),
      ostanName: json['ostan_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'plate_number': plateNumber,
    'cargo_type': cargoType,
    'vehicle_model': vehicleModel,
    if (capacityTons != null) 'capacity_tons': capacityTons,
    if (machineId != null) 'machine_id': machineId,
    if (ostanId != null) 'ostan_id': ostanId,
    if (ostanName != null) 'ostan_name': ostanName,
  };
}
