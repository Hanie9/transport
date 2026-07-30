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
    this.originLat,
    this.originLng,
    this.destinationLat,
    this.destinationLng,
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
  final double? originLat;
  final double? originLng;
  final double? destinationLat;
  final double? destinationLng;

  bool get hasOriginCoords => originLat != null && originLng != null;

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
    double? originLat,
    double? originLng,
    double? destinationLat,
    double? destinationLng,
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
      originLat: originLat ?? this.originLat,
      originLng: originLng ?? this.originLng,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
    );
  }

  factory Cargo.fromJson(Map<String, dynamic> json) {
    double? d(dynamic v) => v == null ? null : double.tryParse('$v');
    return Cargo(
      id: '${json['id'] ?? ''}',
      title: (json['title'] ?? '').toString(),
      origin: (json['origin'] ?? '').toString(),
      destination: (json['destination'] ?? '').toString(),
      cargoType: (json['cargo_type'] ?? json['cargoType'] ?? '').toString(),
      goodsType: (json['goods_type'] ?? json['goodsType'] ?? '').toString(),
      weightTons: d(json['weight_tons'] ?? json['weightTons']) ?? 0,
      estimatedPrice: int.tryParse('${json['estimated_price'] ?? json['estimatedPrice'] ?? 0}') ?? 0,
      status: (json['status'] ?? '').toString(),
      coordinatorName:
          (json['coordinator_name'] ?? json['coordinatorName'] ?? '').toString(),
      distanceKm: d(json['distance_km'] ?? json['distanceKm']),
      assignedDriverName:
          (json['assigned_driver_name'] ?? json['assignedDriverName'])?.toString(),
      assignedDriverPhone:
          (json['assigned_driver_phone'] ?? json['assignedDriverPhone'])?.toString(),
      createdAt: DateTime.tryParse('${json['created_at'] ?? json['createdAt'] ?? ''}'),
      isNearby: json['is_nearby'] == true || json['isNearby'] == true,
      nearbyDistanceKm: d(json['nearby_distance_km'] ?? json['nearbyDistanceKm']),
      originLat: d(json['origin_lat'] ?? json['originLat']),
      originLng: d(json['origin_lng'] ?? json['originLng']),
      destinationLat: d(json['destination_lat'] ?? json['destinationLat']),
      destinationLng: d(json['destination_lng'] ?? json['destinationLng']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'origin': origin,
        'destination': destination,
        'cargo_type': cargoType,
        'goods_type': goodsType,
        'weight_tons': weightTons,
        'estimated_price': estimatedPrice,
        'status': status,
        'coordinator_name': coordinatorName,
        if (distanceKm != null) 'distance_km': distanceKm,
        if (assignedDriverName != null) 'assigned_driver_name': assignedDriverName,
        if (assignedDriverPhone != null) 'assigned_driver_phone': assignedDriverPhone,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        'is_nearby': isNearby,
        if (nearbyDistanceKm != null) 'nearby_distance_km': nearbyDistanceKm,
        if (originLat != null) 'origin_lat': originLat,
        if (originLng != null) 'origin_lng': originLng,
        if (destinationLat != null) 'destination_lat': destinationLat,
        if (destinationLng != null) 'destination_lng': destinationLng,
      };
}
