class Cargo {
  const Cargo({
    required this.id,
    required this.title,
    required this.origin,
    required this.destination,
    required this.cargoType,
    required this.goodsType,
    required this.weightTons,
    required this.estimatedPrice,
    required this.status,
    required this.coordinatorName,
    this.distanceKm,
    this.assignedDriverName,
    this.assignedDriverPhone,
    this.createdAt,
    this.isNearby = false,
    this.nearbyDistanceKm,
  });

  final String id;
  final String title;
  final String origin;
  final String destination;
  final String cargoType;
  final String goodsType;
  final double weightTons;
  final int estimatedPrice;
  final String status;
  final String coordinatorName;
  final double? distanceKm;
  final String? assignedDriverName;
  final String? assignedDriverPhone;
  final DateTime? createdAt;
  final bool isNearby;
  final double? nearbyDistanceKm;

  String get routeLabel => '$origin ← $destination';

  Cargo copyWith({
    String? id,
    String? title,
    String? origin,
    String? destination,
    String? cargoType,
    String? goodsType,
    double? weightTons,
    int? estimatedPrice,
    String? status,
    String? coordinatorName,
    double? distanceKm,
    String? assignedDriverName,
    String? assignedDriverPhone,
    DateTime? createdAt,
    bool? isNearby,
    double? nearbyDistanceKm,
  }) {
    return Cargo(
      id: id ?? this.id,
      title: title ?? this.title,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      cargoType: cargoType ?? this.cargoType,
      goodsType: goodsType ?? this.goodsType,
      weightTons: weightTons ?? this.weightTons,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      status: status ?? this.status,
      coordinatorName: coordinatorName ?? this.coordinatorName,
      distanceKm: distanceKm ?? this.distanceKm,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      assignedDriverPhone: assignedDriverPhone ?? this.assignedDriverPhone,
      createdAt: createdAt ?? this.createdAt,
      isNearby: isNearby ?? this.isNearby,
      nearbyDistanceKm: nearbyDistanceKm ?? this.nearbyDistanceKm,
    );
  }
}
