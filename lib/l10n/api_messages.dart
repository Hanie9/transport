/// User-facing API / backend error strings (no BuildContext required).
abstract final class ApiMessages {
  static String t(String fa, String en, {required bool isEnglish}) =>
      isEnglish ? en : fa;

  static String requestFailed({required bool isEnglish}) =>
      t('درخواست ناموفق بود', 'Request failed', isEnglish: isEnglish);

  static String invalidRequest({required bool isEnglish}) =>
      t('درخواست نامعتبر است.', 'Invalid request.', isEnglish: isEnglish);

  static String invalidCredentials({required bool isEnglish}) =>
      t(
        'نام کاربری یا رمز عبور اشتباه است.',
        'Invalid phone number or password.',
        isEnglish: isEnglish,
      );

  static String accessDenied({required bool isEnglish}) =>
      t('دسترسی مجاز نیست.', 'Access denied.', isEnglish: isEnglish);

  static String notFound({required bool isEnglish}) =>
      t('آدرس درخواست یافت نشد.', 'Requested resource was not found.', isEnglish: isEnglish);

  static String requestTimeout({required bool isEnglish}) =>
      t('زمان درخواست به پایان رسید.', 'Request timed out.', isEnglish: isEnglish);

  static String tooManyRequests({required bool isEnglish}) =>
      t(
        'تعداد درخواست‌ها زیاد است. کمی بعد دوباره تلاش کنید.',
        'Too many requests. Please try again later.',
        isEnglish: isEnglish,
      );

  static String serverError({required bool isEnglish}) =>
      t('خطای داخلی سرور.', 'Internal server error.', isEnglish: isEnglish);

  static String serverUnavailable({required bool isEnglish}) =>
      t(
        'سرور در دسترس نیست. لطفاً بعداً دوباره تلاش کنید.',
        'Server is unavailable. Please try again later.',
        isEnglish: isEnglish,
      );

  static String serverUnavailableRetry({required bool isEnglish}) =>
      t(
        'سرور در دسترس نیست. لطفاً چند دقیقه بعد دوباره تلاش کنید.',
        'Server is unavailable. Please try again in a few minutes.',
        isEnglish: isEnglish,
      );

  static String gatewayTimeout({required bool isEnglish}) =>
      t('زمان پاسخ سرور به پایان رسید.', 'Server response timed out.', isEnglish: isEnglish);

  static String badGateway({required bool isEnglish}) =>
      t('سرور موقتاً در دسترس نیست.', 'Server is temporarily unavailable.', isEnglish: isEnglish);

  static String invalidServerResponse({required bool isEnglish}) =>
      t('پاسخ نامعتبر از سرور دریافت شد.', 'Invalid response from server.', isEnglish: isEnglish);

  static String noInternet({required bool isEnglish}) =>
      t('اتصال به اینترنت برقرار نیست.', 'No internet connection.', isEnglish: isEnglish);

  static String loginTokenMissing({required bool isEnglish}) =>
      t('توکن ورود دریافت نشد.', 'Login token was not received.', isEnglish: isEnglish);

  static String invalidPassword({required bool isEnglish}) =>
      t('رمز عبور نامعتبر است.', 'Invalid password.', isEnglish: isEnglish);

  static String sessionExpired({required bool isEnglish}) =>
      t(
        'نشست شما منقضی شده است. دوباره وارد شوید.',
        'Your session has expired. Please sign in again.',
        isEnglish: isEnglish,
      );

  static String? messageForStatusCode(int? statusCode, {required bool isEnglish}) {
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
  static String localizeBackendDetail(String message, {required bool isEnglish}) {
    final normalized = message.trim().toLowerCase();

    const englishToFa = {
      'no active account found with the given credentials':
          'نام کاربری یا رمز عبور اشتباه است.',
      'authentication credentials were not provided.': 'احراز هویت انجام نشده است.',
      'given token not valid for any token type': 'نشست منقضی شده است. دوباره وارد شوید.',
      'token is invalid or expired': 'نشست منقضی شده است. دوباره وارد شوید.',
      'user not found': 'کاربر یافت نشد.',
      'invalid phone number': 'شماره موبایل نامعتبر است.',
      'this field is required.': 'این فیلد الزامی است.',
      'this field may not be blank.': 'این فیلد نمی‌تواند خالی باشد.',
      'enter a valid email address.': 'ایمیل نامعتبر است.',
      'a user with that phone number already exists.': 'این شماره موبایل قبلاً ثبت شده است.',
      'a user with that username already exists.': 'این کاربر قبلاً ثبت شده است.',
      'incorrect password': 'رمز عبور فعلی اشتباه است.',
      'old password': 'رمز عبور فعلی اشتباه است.',
    };

    const persianToEn = {
      'نام کاربری یا رمز عبور اشتباه است': 'Invalid phone number or password.',
      'احراز هویت انجام نشده است': 'Authentication credentials were not provided.',
      'نشست منقضی شده است': 'Session expired. Please sign in again.',
      'کاربر یافت نشد': 'User not found.',
      'شماره موبایل نامعتبر است': 'Invalid phone number.',
      'این فیلد الزامی است': 'This field is required.',
      'رمز عبور فعلی اشتباه است': 'Current password is incorrect.',
      'این شماره موبایل قبلاً ثبت شده است': 'This phone number is already registered.',
    };

    if (isEnglish) {
      for (final entry in persianToEn.entries) {
        if (normalized.contains(entry.key)) return entry.value;
      }
      return message;
    }

    for (final entry in englishToFa.entries) {
      if (normalized.contains(entry.key)) return entry.value;
    }

    return message;
  }

  static String localizeFieldName(String field, {required bool isEnglish}) {
    if (isEnglish) return field;
    return switch (field) {
      'phone' => 'شماره موبایل',
      'password' => 'رمز عبور',
      'current_password' => 'رمز عبور فعلی',
      'new_password' => 'رمز عبور جدید',
      'full_name' => 'نام کامل',
      'email' => 'ایمیل',
      'role' => 'نقش',
      'detail' => 'خطا',
      'non_field_errors' => 'خطا',
      _ => field,
    };
  }
}
