import '../models/cargo.dart';

/// Maps Transport API (`bars`, `accounts`) payloads to app models.
abstract final class TransportApiMapper {
  static String appStatus(Map<String, dynamic> json) {
    switch (json['status']?.toString()) {
      case 'open':
        return 'در انتظار راننده';
      case 'assign':
        return 'تخصیص یافته';
      case 'done':
        return 'تحویل شده';
      case 'cancal':
        return 'لغو شده';
      default:
        final display = json['status_display']?.toString().trim();
        if (display != null && display.isNotEmpty) return display;
        return json['status']?.toString() ?? '';
    }
  }

  static String? apiStatusForApp(String status) {
    switch (status) {
      case 'در انتظار راننده':
        return 'open';
      case 'تخصیص یافته':
        return 'assign';
      case 'تحویل شده':
        return 'done';
      case 'لغو شده':
        return 'cancal';
      default:
        return null;
    }
  }

  static bool isOpenStatus(String status) =>
      status == 'open' || status == 'در انتظار راننده' || status == 'باز';

  static Cargo cargoFromBar(Map<String, dynamic> json) {
    double? d(dynamic v) => v == null ? null : double.tryParse('$v');

    final assign = json['assign_info'];
    Map<String, dynamic>? assignMap;
    if (assign is Map) {
      assignMap = Map<String, dynamic>.from(assign);
    }

    final origin = _locationLabel(
      address: json['address_mabda']?.toString(),
      ostan: json['ostan_mabda_name']?.toString(),
    );
    final destination = _locationLabel(
      address: json['address_maghsad']?.toString(),
      ostan: json['ostan_maghsad_name']?.toString(),
    );

    return Cargo(
      id: '${json['id'] ?? ''}',
      title: (json['title'] ?? '').toString(),
      origin: origin,
      destination: destination,
      cargoType: (json['machine_name'] ?? '').toString(),
      goodsType: (json['product_name'] ?? '').toString(),
      weightTons: 0,
      estimatedPrice: int.tryParse('${json['price'] ?? 0}') ?? 0,
      status: appStatus(json),
      coordinatorName: (json['operator_name'] ?? '').toString(),
      assignedDriverName: assignMap?['driver_name']?.toString(),
      assignedDriverPhone: assignMap?['driver_phone']?.toString(),
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
      originLat: d(json['latitude_mabda']),
      originLng: d(json['longitude_mabda']),
      destinationLat: d(json['latitude_maghsad']),
      destinationLng: d(json['longitude_maghsad']),
      description: json['description']?.toString(),
      productId: int.tryParse('${json['product']}'),
      machineId: int.tryParse('${json['machine']}'),
      ostanMabdaId: int.tryParse('${json['ostan_mabda']}'),
      ostanMaghsadId: int.tryParse('${json['ostan_maghsad']}'),
    );
  }

  static String _locationLabel({String? address, String? ostan}) {
    final a = address?.trim();
    if (a != null && a.isNotEmpty) return a;
    final o = ostan?.trim();
    if (o != null && o.isNotEmpty) return o;
    return '';
  }

  /// Builds JSON body for `BarCreateUpdate` / `PatchedBarCreateUpdate`.
  static Map<String, dynamic> barPayload({
    String? title,
    String? description,
    int? price,
    int? productId,
    int? machineId,
    int? ostanMabdaId,
    int? ostanMaghsadId,
    String? addressMabda,
    String? addressMaghsad,
    double? originLat,
    double? originLng,
    double? destinationLat,
    double? destinationLng,
    String? status,
  }) {
    return {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
      if (productId != null) 'product': productId,
      if (machineId != null) 'machine': machineId,
      if (ostanMabdaId != null) 'ostan_mabda': ostanMabdaId,
      if (ostanMaghsadId != null) 'ostan_maghsad': ostanMaghsadId,
      if (addressMabda != null) 'address_mabda': addressMabda,
      if (addressMaghsad != null) 'address_maghsad': addressMaghsad,
      if (originLat != null) 'latitude_mabda': originLat.toString(),
      if (originLng != null) 'longitude_mabda': originLng.toString(),
      if (destinationLat != null) 'latitude_maghsad': destinationLat.toString(),
      if (destinationLng != null) 'longitude_maghsad': destinationLng.toString(),
      if (status != null) 'status': apiStatusForApp(status) ?? status,
    };
  }
}
