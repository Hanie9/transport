import 'package:legestic/generated/neshan_secrets.g.dart';

/// Neshan API key from panel (`service.xxx` for REST).
String get neshanApiKey {
  const fromDefine = String.fromEnvironment('NESHAN_API_KEY');
  if (fromDefine.trim().isNotEmpty) return fromDefine.trim();
  return embeddedNeshanApiKey.trim();
}

/// Neshan **mobile** key (`mobile.xxx`) for MapLibre map tiles only — not REST.
String get neshanAndroidApiKey {
  const fromDefine = String.fromEnvironment('NESHAN_ANDROID_KEY');
  if (fromDefine.trim().isNotEmpty) return fromDefine.trim();
  return embeddedNeshanAndroidKey.trim();
}

String get neshanMapKey {
  const fromDefine = String.fromEnvironment('NESHAN_MAP_KEY');
  if (fromDefine.trim().isNotEmpty) return fromDefine.trim();
  if (embeddedNeshanMapKey.trim().isNotEmpty) return embeddedNeshanMapKey.trim();
  return neshanAndroidApiKey;
}

/// Geocoding Plus — matches «تبدیل آدرس به نقطه پلاس» in panel.
const String neshanGeocodingBaseUrl = 'https://api.neshan.org/geocoding/v1/plus';

/// Place search — requires «جستجوی مکان‌مبنا» on the Neshan key (optional).
const String neshanSearchBaseUrl = 'https://api.neshan.org/v1/search';

/// Most accounts only have Geocoding Plus. Set `NESHAN_SEARCH_ENABLED=true`
/// after activating «جستجوی مکان‌مبنا» in the Neshan panel.
bool get neshanSearchEnabled {
  const fromDefine = String.fromEnvironment('NESHAN_SEARCH_ENABLED');
  if (fromDefine.trim().isNotEmpty) {
    return fromDefine.trim().toLowerCase() == 'true';
  }
  return false;
}

/// Routing with live traffic — matches «مسیریابی با ترافیک» in panel.
const String neshanDirectionBaseUrl = 'https://api.neshan.org/v4/direction';

/// Domain Referer required by the scoped `service.*` key (same as uzita proxy).
/// Without this header Neshan returns 484 ApiWhiteListError from the device.
const String neshanApiReferer = String.fromEnvironment(
  'NESHAN_API_REFERER',
  defaultValue: 'https://device-control.liara.run/',
);

/// Routing without live traffic — baseline for segment traffic coloring.
const String neshanNoTrafficDirectionBaseUrl =
    'https://api.neshan.org/v4/direction/no-traffic';

/// Typical traffic pattern routing — fallback baseline when no-traffic fails.
const String neshanTypicalDirectionBaseUrl =
    'https://api.neshan.org/v4/direction/typical';

/// Static arc map — matches «نقشه استاتیک منحنی‌دار» in panel.
const String neshanStaticArcUrl = 'https://api.neshan.org/v4/static/arc';

bool get hasNeshanApiKey => neshanApiKey.trim().isNotEmpty;

bool get hasNeshanAndroidKey => neshanAndroidApiKey.trim().isNotEmpty;

/// REST / services-sdk key — must be `service.xxx` (not `mobile.xxx`).
String get neshanDirectApiKey {
  final service = neshanApiKey.trim();
  if (service.startsWith('service.')) return service;
  final android = neshanAndroidApiKey.trim();
  // `mobile.*` is MapLibre-only (HTTP 483 on direction/geocode).
  if (android.isNotEmpty && !android.startsWith('mobile.')) return android;
  return service;
}

bool get hasDirectNeshanKey => neshanDirectApiKey.trim().isNotEmpty;

String get effectiveNeshanMapKey => neshanMapKey.trim();

/// Static arc map works with the same service key.
bool get canShowNeshanStaticMap =>
    hasNeshanApiKey || hasNeshanAndroidKey || hasDirectNeshanKey;
