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
}
