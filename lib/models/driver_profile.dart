class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.cargoType,
    required this.plateNumber,
    required this.vehicleModel,
    required this.isActive,
    this.rating,
    this.completedTrips,
    this.distanceKm,
    this.currentLocation,
    this.lat,
    this.lng,
  });

  final String id;
  final String fullName;
  final String phone;
  final String cargoType;
  final String plateNumber;
  final String vehicleModel;
  final bool isActive;
  final double? rating;
  final int? completedTrips;
  final double? distanceKm;
  final String? currentLocation;
  final double? lat;
  final double? lng;

  bool get hasCoords => lat != null && lng != null;

  DriverProfile copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? cargoType,
    String? plateNumber,
    String? vehicleModel,
    bool? isActive,
    double? rating,
    int? completedTrips,
    double? distanceKm,
    String? currentLocation,
    double? lat,
    double? lng,
  }) {
    return DriverProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      cargoType: cargoType ?? this.cargoType,
      plateNumber: plateNumber ?? this.plateNumber,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      isActive: isActive ?? this.isActive,
      rating: rating ?? this.rating,
      completedTrips: completedTrips ?? this.completedTrips,
      distanceKm: distanceKm ?? this.distanceKm,
      currentLocation: currentLocation ?? this.currentLocation,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    double? d(dynamic v) => v == null ? null : double.tryParse('$v');
    return DriverProfile(
      id: '${json['id'] ?? ''}',
      fullName: (json['full_name'] ?? json['fullName'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      cargoType: (json['cargo_type'] ?? json['cargoType'] ?? '').toString(),
      plateNumber: (json['plate_number'] ?? json['plateNumber'] ?? '').toString(),
      vehicleModel:
          (json['vehicle_model'] ?? json['vehicleModel'] ?? '').toString(),
      isActive: json['is_active'] == true || json['isActive'] == true,
      rating: d(json['rating']),
      completedTrips:
          int.tryParse('${json['completed_trips'] ?? json['completedTrips'] ?? ''}'),
      distanceKm: d(json['distance_km'] ?? json['distanceKm']),
      currentLocation:
          (json['current_location'] ?? json['currentLocation'])?.toString(),
      lat: d(json['lat'] ?? json['latitude']),
      lng: d(json['lng'] ?? json['longitude']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'phone': phone,
        'cargo_type': cargoType,
        'plate_number': plateNumber,
        'vehicle_model': vehicleModel,
        'is_active': isActive,
        if (rating != null) 'rating': rating,
        if (completedTrips != null) 'completed_trips': completedTrips,
        if (distanceKm != null) 'distance_km': distanceKm,
        if (currentLocation != null) 'current_location': currentLocation,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      };
}
