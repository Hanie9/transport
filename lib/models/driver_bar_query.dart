/// Query parameters supported by `GET /api/driver/bars/`.
class DriverBarQuery {
  const DriverBarQuery({
    this.ostanMabda,
    this.ostanMaghsad,
    this.priceMin,
    this.priceMax,
    this.page,
  });

  final int? ostanMabda;
  final int? ostanMaghsad;
  final int? priceMin;
  final int? priceMax;
  final int? page;

  Map<String, String> toQueryParameters() {
    return {
      if (ostanMabda != null) 'ostan_mabda': '$ostanMabda',
      if (ostanMaghsad != null) 'ostan_maghsad': '$ostanMaghsad',
      if (priceMin != null) 'price_min': '$priceMin',
      if (priceMax != null) 'price_max': '$priceMax',
      if (page != null) 'page': '$page',
    };
  }

  bool get isEmpty =>
      ostanMabda == null &&
      ostanMaghsad == null &&
      priceMin == null &&
      priceMax == null &&
      page == null;
}
