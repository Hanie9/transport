import '../models/user_role.dart';

/// User-facing API / backend error strings (no BuildContext required).
abstract final class ApiMessages {
  static String t(String fa, String en, {required bool isEnglish}) =>
      isEnglish ? en : fa;

  static String requestFailed({required bool isEnglish}) =>
      t('درخواست ناموفق بود', 'Request failed', isEnglish: isEnglish);

  static String invalidRequest({required bool isEnglish}) =>
      t('درخواست نامعتبر است.', 'Invalid request.', isEnglish: isEnglish);

  static String invalidCredentials({required bool isEnglish}) => t(
    'نام کاربری یا رمز عبور اشتباه است.',
    'Invalid phone number or password.',
    isEnglish: isEnglish,
  );

  static String accessDenied({required bool isEnglish}) =>
      t('دسترسی مجاز نیست.', 'Access denied.', isEnglish: isEnglish);

  static String notFound({required bool isEnglish}) => t(
    'آدرس درخواست یافت نشد.',
    'Requested resource was not found.',
    isEnglish: isEnglish,
  );

  static String requestTimeout({required bool isEnglish}) => t(
    'زمان درخواست به پایان رسید.',
    'Request timed out.',
    isEnglish: isEnglish,
  );

  static String tooManyRequests({required bool isEnglish}) => t(
    'تعداد درخواست‌ها زیاد است. کمی بعد دوباره تلاش کنید.',
    'Too many requests. Please try again later.',
    isEnglish: isEnglish,
  );

  static String serverError({required bool isEnglish}) =>
      t('خطای داخلی سرور.', 'Internal server error.', isEnglish: isEnglish);

  static String serverUnavailable({required bool isEnglish}) => t(
    'سرور در دسترس نیست. لطفاً بعداً دوباره تلاش کنید.',
    'Server is unavailable. Please try again later.',
    isEnglish: isEnglish,
  );

  static String serverUnavailableRetry({required bool isEnglish}) => t(
    'سرور در دسترس نیست. لطفاً چند دقیقه بعد دوباره تلاش کنید.',
    'Server is unavailable. Please try again in a few minutes.',
    isEnglish: isEnglish,
  );

  static String gatewayTimeout({required bool isEnglish}) => t(
    'زمان پاسخ سرور به پایان رسید.',
    'Server response timed out.',
    isEnglish: isEnglish,
  );

  static String badGateway({required bool isEnglish}) => t(
    'سرور موقتاً در دسترس نیست.',
    'Server is temporarily unavailable.',
    isEnglish: isEnglish,
  );

  static String invalidServerResponse({required bool isEnglish}) => t(
    'پاسخ نامعتبر از سرور دریافت شد.',
    'Invalid response from server.',
    isEnglish: isEnglish,
  );

  static String noInternet({required bool isEnglish}) => t(
    'اتصال به اینترنت برقرار نیست.',
    'No internet connection.',
    isEnglish: isEnglish,
  );

  static String loginTokenMissing({required bool isEnglish}) => t(
    'توکن ورود دریافت نشد.',
    'Login token was not received.',
    isEnglish: isEnglish,
  );

  static String signupUnavailable({required bool isEnglish}) => t(
    'ثبت‌نام از طریق اپ فعلاً امکان‌پذیر نیست. با پشتیبانی تماس بگیرید.',
    'Sign-up via the app is not available yet. Please contact support.',
    isEnglish: isEnglish,
  );

  static String roleMismatch({
    required bool isEnglish,
    required UserRole role,
  }) {
    final fa = role == UserRole.driver
        ? 'این حساب برای نقش راننده مجاز نیست.'
        : 'این حساب برای نقش متصدی مجاز نیست.';
    final en = role == UserRole.driver
        ? 'This account is not authorized as a driver.'
        : 'This account is not authorized as a coordinator.';
    return t(fa, en, isEnglish: isEnglish);
  }

  static String featureUnavailable({required bool isEnglish}) => t(
    'این قابلیت در سرور فعال نیست.',
    'This feature is not available on the server.',
    isEnglish: isEnglish,
  );

  static String invalidPassword({required bool isEnglish}) =>
      t('رمز عبور نامعتبر است.', 'Invalid password.', isEnglish: isEnglish);

  static String machineMismatch({
    required bool isEnglish,
    required String requiredMachine,
  }) => t(
    'این بار برای ماشین «$requiredMachine» است و با ماشین ثبت‌شده شما هم‌خوانی ندارد.',
    'This cargo requires a "$requiredMachine" and does not match your registered machine.',
    isEnglish: isEnglish,
  );

  static String serverMachineNote({required bool isEnglish}) => t(
    'بارهای قابل مشاهده توسط سرور بر اساس ماشین حساب شما فیلتر می‌شوند. '
        'در صورت عدم تطابق، با پشتیبانی تماس بگیرید.',
    'Visible cargos are filtered by the machine linked to your account on the server. '
        'Contact support if they do not match.',
    isEnglish: isEnglish,
  );

  static String sessionExpired({required bool isEnglish}) => t(
    'نشست شما منقضی شده است. دوباره وارد شوید.',
    'Your session has expired. Please sign in again.',
    isEnglish: isEnglish,
  );

  static String? messageForStatusCode(
    int? statusCode, {
    required bool isEnglish,
  }) {
    switch (statusCode) {
      case 400:
        return invalidRequest(isEnglish: isEnglish);
      case 401:
        return invalidCredentials(isEnglish: isEnglish);
      case 403:
        return accessDenied(isEnglish: isEnglish);
      case 404:
        return notFound(isEnglish: isEnglish);
      case 408:
        return requestTimeout(isEnglish: isEnglish);
      case 429:
        return tooManyRequests(isEnglish: isEnglish);
      case 500:
        return serverError(isEnglish: isEnglish);
      case 502:
        return badGateway(isEnglish: isEnglish);
      case 503:
        return serverUnavailable(isEnglish: isEnglish);
      case 504:
        return gatewayTimeout(isEnglish: isEnglish);
      default:
        return null;
    }
  }

  /// Maps common Django REST / backend messages to the active app language.
  static String localizeBackendDetail(
    String message, {
    required bool isEnglish,
  }) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return trimmed;
    final normalized = trimmed.toLowerCase();

    final maxLength = RegExp(
      r'ensure this field has no more than (\d+) characters',
    ).firstMatch(normalized);
    if (maxLength != null) {
      final n = maxLength.group(1)!;
      return t(
        'حداکثر $n نویسه مجاز است.',
        'This field may have at most $n characters.',
        isEnglish: isEnglish,
      );
    }
    final maxLengthFa = RegExp(r'حداکثر (\d+) نویسه').firstMatch(trimmed);
    if (maxLengthFa != null && isEnglish) {
      return 'This field may have at most ${maxLengthFa.group(1)} characters.';
    }

    final decimalPlaces = RegExp(
      r'ensure that there are no more than (\d+) decimal places',
    ).firstMatch(normalized);
    if (decimalPlaces != null) {
      final n = decimalPlaces.group(1)!;
      return t(
        'حداکثر $n رقم اعشار مجاز است.',
        'No more than $n decimal places are allowed.',
        isEnglish: isEnglish,
      );
    }

    const englishToFa = {
      'no active account found with the given credentials':
          'نام کاربری یا رمز عبور اشتباه است.',
      'authentication credentials were not provided.':
          'احراز هویت انجام نشده است.',
      'given token not valid for any token type':
          'نشست منقضی شده است. دوباره وارد شوید.',
      'token is invalid or expired': 'نشست منقضی شده است. دوباره وارد شوید.',
      'user not found': 'کاربر یافت نشد.',
      'invalid phone number': 'شماره موبایل نامعتبر است.',
      'this field is required.': 'این فیلد الزامی است.',
      'this field may not be blank.': 'این فیلد نمی‌تواند خالی باشد.',
      'this field may not be null.': 'این فیلد نمی‌تواند خالی باشد.',
      'enter a valid email address.': 'ایمیل نامعتبر است.',
      'a user with that phone number already exists.':
          'این شماره موبایل قبلاً ثبت شده است.',
      'a user with that username already exists.':
          'این کاربر قبلاً ثبت شده است.',
      'incorrect password': 'رمز عبور فعلی اشتباه است.',
      'old password': 'رمز عبور فعلی اشتباه است.',
      'a valid integer is required.': 'مقدار باید عدد صحیح باشد.',
      'a valid number is required.': 'مقدار باید عدد معتبر باشد.',
      'enter a valid number.': 'مقدار باید عدد معتبر باشد.',
      'select a valid choice.': 'گزینهٔ انتخاب‌شده نامعتبر است.',
      'object does not exist.': 'مورد انتخاب‌شده در سامانه وجود ندارد.',
      'invalid pk': 'شناسهٔ انتخاب‌شده نامعتبر است.',
    };

    const persianToEn = {
      'نام کاربری یا رمز عبور اشتباه است': 'Invalid phone number or password.',
      'احراز هویت انجام نشده است':
          'Authentication credentials were not provided.',
      'نشست منقضی شده است': 'Session expired. Please sign in again.',
      'کاربر یافت نشد': 'User not found.',
      'شماره موبایل نامعتبر است': 'Invalid phone number.',
      'این فیلد الزامی است': 'This field is required.',
      'این فیلد نمی‌تواند خالی باشد': 'This field may not be blank.',
      'رمز عبور فعلی اشتباه است': 'Current password is incorrect.',
      'این شماره موبایل قبلاً ثبت شده است':
          'This phone number is already registered.',
      'باید عدد صحیح باشد': 'A valid integer is required.',
      'باید عدد معتبر باشد': 'A valid number is required.',
      'گزینهٔ انتخاب‌شده نامعتبر است': 'Select a valid choice.',
      'مورد انتخاب‌شده در سامانه وجود ندارد':
          'The selected item does not exist.',
      'شناسهٔ انتخاب‌شده نامعتبر است': 'The selected id is invalid.',
    };

    if (isEnglish) {
      for (final entry in persianToEn.entries) {
        if (normalized.contains(entry.key)) return entry.value;
      }
      return trimmed;
    }

    for (final entry in englishToFa.entries) {
      if (normalized.contains(entry.key)) return entry.value;
    }

    return trimmed;
  }

  static String localizeFieldName(String field, {required bool isEnglish}) {
    const labels = <String, (String fa, String en)>{
      'phone': ('شماره موبایل', 'Phone number'),
      'phone_number': ('شماره موبایل', 'Phone number'),
      'password': ('رمز عبور', 'Password'),
      'password_confirm': ('تکرار رمز عبور', 'Confirm password'),
      'current_password': ('رمز عبور فعلی', 'Current password'),
      'old_password': ('رمز عبور فعلی', 'Current password'),
      'new_password': ('رمز عبور جدید', 'New password'),
      'full_name': ('نام کامل', 'Full name'),
      'first_name': ('نام', 'First name'),
      'last_name': ('نام خانوادگی', 'Last name'),
      'email': ('ایمیل', 'Email'),
      'role': ('نقش', 'Role'),
      'user_type': ('نقش', 'Role'),
      'title': ('عنوان', 'Title'),
      'description': ('توضیحات', 'Description'),
      'price': ('قیمت', 'Price'),
      'weight': ('وزن', 'Weight'),
      'product': ('نوع کالا', 'Goods type'),
      'machine': ('نوع بارگیر', 'Trailer type'),
      'ostan_mabda': ('استان مبدأ', 'Origin province'),
      'ostan_maghsad': ('استان مقصد', 'Destination province'),
      'address_mabda': ('نشانی مبدأ', 'Origin address'),
      'address_maghsad': ('نشانی مقصد', 'Destination address'),
      'latitude_mabda': ('عرض جغرافیایی مبدأ', 'Origin latitude'),
      'longitude_mabda': ('طول جغرافیایی مبدأ', 'Origin longitude'),
      'latitude_maghsad': ('عرض جغرافیایی مقصد', 'Destination latitude'),
      'longitude_maghsad': ('طول جغرافیایی مقصد', 'Destination longitude'),
      'status': ('وضعیت', 'Status'),
      'detail': ('خطا', 'Error'),
      'non_field_errors': ('خطا', 'Error'),
    };

    final label = labels[field];
    if (label == null) return field;
    return isEnglish ? label.$2 : label.$1;
  }
}
