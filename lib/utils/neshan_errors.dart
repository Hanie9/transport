import '../l10n/app_localizations.dart';
import '../services/neshan_service.dart';
import 'neshan_error_codes.dart';

/// Maps Neshan API error statuses to user-facing localized messages.
String localizeNeshanError(AppLocalizations l, NeshanApiException error) {
  switch (error.neshanStatus) {
    case 'ApiServiceListError':
      return l.neshanErrorServiceList;
    case 'ApiKeyTypeError':
      return l.neshanErrorKeyType;
    case 'ApiWhiteListError':
      return l.neshanErrorWhitelist;
    case 'BackendProxyNotFound':
    case 'BackendKeyMissing':
      return l.neshanErrorBackendProxy;
    case NeshanErrorCodes.backendUnauthorized:
      return l.neshanErrorBackendUnauthorized;
    case NeshanErrorCodes.backendProxyFailed:
      return l.neshanErrorBackendFailed;
    case 'KeyNotFound':
      return l.neshanErrorKeyNotFound;
    case 'LimitExceeded':
      return l.neshanErrorLimit;
    case 'RateExceeded':
      return l.neshanErrorRate;
    case NeshanErrorCodes.addressEmpty:
      return l.neshanErrorAddressEmpty;
    case NeshanErrorCodes.geocodingNotFound:
      return l.neshanErrorGeocodingNotFound;
    case NeshanErrorCodes.invalidGeocodingLocation:
    case NeshanErrorCodes.invalidGeocodingCoordinates:
    case NeshanErrorCodes.sdkInvalidCoordinates:
      return l.neshanErrorGeocodingInvalid;
    case NeshanErrorCodes.geocodingRequestFailed:
      return l.neshanErrorGeocodingFailed;
    case NeshanErrorCodes.routingNotFound:
      return l.neshanErrorRoutingNotFound;
    case NeshanErrorCodes.invalidRoutingResponse:
      return l.neshanErrorRoutingInvalid;
    case NeshanErrorCodes.routingNoLegs:
    case NeshanErrorCodes.routingNoValidLegs:
      return l.neshanErrorRoutingNoLegs;
    case NeshanErrorCodes.routingRequestFailed:
      return l.neshanErrorRoutingFailed;
    case NeshanErrorCodes.sdkEmptyResponse:
      return l.neshanErrorSdkResponse;
    case NeshanErrorCodes.invalidArgument:
    case NeshanErrorCodes.coordinateParseError:
      return l.neshanErrorInvalidArgument;
    default:
      return error.message.isNotEmpty ? error.message : l.neshanErrorGeneric;
  }
}
