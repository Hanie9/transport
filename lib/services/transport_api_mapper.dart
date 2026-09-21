import '../models/cargo.dart';

/// Maps Transport API (`bars`, `accounts`) payloads to app models.
abstract final class TransportApiMapper {
  // Keep a readable suffix until every deployed backend supports `weight`.
  static final _weightSuffix = RegExp(r'(?:\n)?وزن: ([0-9]+(?:\.[0-9]+)?) تن$');

  static double? parseWeightTons(String value) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    var normalized = value.trim().replaceAll('٫', '.');
    for (var i = 0; i < 10; i++) {
      normalized = normalized
          .replaceAll(persian[i], '$i')
          .replaceAll(arabic[i], '$i');
    }
    final weight = double.tryParse(normalized);
    return weight != null && weight.isFinite && weight > 0 ? weight : null;
  }

  static String descriptionWithWeight(String description, double weightTons) {
    final base = description.replaceFirst(_weightSuffix, '').trimRight();
    final tons = apiWeight(weightTons);
    if (tons == null) return base;
    return '${base.isEmpty ? '' : '$base\n'}وزن: $tons تن';
  }

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
      weightTons:
          d(json['weight'] ?? json['weight_tons'] ?? json['weightTons']) ??
          double.tryParse(
            _weightSuffix
                    .firstMatch(json['description']?.toString() ?? '')
                    ?.group(1) ??
                '',
          ) ??
          0,
      estimatedPrice: int.tryParse('${json['price'] ?? 0}') ?? 0,
      status: appStatus(json),
      coordinatorName: (json['operator_name'] ?? '').toString(),
      assignedDriverName: assignMap?['driver_name']?.toString(),
      assignedDriverPhone: assignMap?['driver_phone']?.toString(),
      confirmDriver: assignMap?['confirm_driver'] == true,
      confirmOperator: assignMap?['confirm_operator'] == true,
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
      originLat: d(
        json['latitude_mabda'] ??
            json['lat_mabda'] ??
            json['origin_lat'] ??
            json['originLat'] ??
            (json['mabda'] is Map
                ? (json['mabda']['latitude'] ??
                      json['mabda']['lat'] ??
                      json['mabda']['latitude_mabda'])
                : null),
      ),
      originLng: d(
        json['longitude_mabda'] ??
            json['lng_mabda'] ??
            json['lon_mabda'] ??
            json['origin_lng'] ??
            json['originLng'] ??
            (json['mabda'] is Map
                ? (json['mabda']['longitude'] ??
                      json['mabda']['lng'] ??
                      json['mabda']['lon'] ??
                      json['mabda']['longitude_mabda'])
                : null),
      ),
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

  /// OpenAPI `BarCreateUpdate.weight` is an integer (tons).
  static int? apiWeight(double? weight) {
    if (weight == null || !weight.isFinite || weight <= 0) return null;
    final rounded = weight.round();
    return rounded > 0 ? rounded : null;
  }

  /// OpenAPI decimal fields allow at most 3 integer digits and 6 decimals.
  static String? apiDecimal(double? value) {
    if (value == null || !value.isFinite) return null;
    var text = value.toStringAsFixed(6);
    if (text.contains('.')) {
      text = text.replaceFirst(RegExp(r'0+$'), '');
      if (text.endsWith('.')) {
        text = text.substring(0, text.length - 1);
      }
    }
    return text;
  }

  /// Builds JSON body for `BarCreateUpdate` / `PatchedBarCreateUpdate`.
  static Map<String, dynamic> barPayload({
    String? title,
    String? description,
    int? price,
    double? weight,
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
    final weightTons = apiWeight(weight);
    final latitudeMabda = apiDecimal(originLat);
    final longitudeMabda = apiDecimal(originLng);
    final latitudeMaghsad = apiDecimal(destinationLat);
    final longitudeMaghsad = apiDecimal(destinationLng);
    return {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
      if (weightTons != null) 'weight': weightTons,
      if (productId != null) 'product': productId,
      if (machineId != null) 'machine': machineId,
      if (ostanMabdaId != null) 'ostan_mabda': ostanMabdaId,
      if (ostanMaghsadId != null) 'ostan_maghsad': ostanMaghsadId,
      if (addressMabda != null) 'address_mabda': addressMabda,
      if (addressMaghsad != null) 'address_maghsad': addressMaghsad,
      if (latitudeMabda != null) 'latitude_mabda': latitudeMabda,
      if (longitudeMabda != null) 'longitude_mabda': longitudeMabda,
      if (latitudeMaghsad != null) 'latitude_maghsad': latitudeMaghsad,
      if (longitudeMaghsad != null) 'longitude_maghsad': longitudeMaghsad,
      if (status != null) 'status': apiStatusForApp(status) ?? status,
    };
  }
}
