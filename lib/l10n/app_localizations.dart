import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('fa', 'IR'), Locale('en', 'US')];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  bool get isFa => locale.languageCode == 'fa';

  String _t(String fa, String en) => isFa ? fa : en;

  String get appName => _t('لجستیک', 'Logistics');
  String get appTagline => _t(
    'سامانه هوشمند حمل‌ونقل بار جاده‌ای',
    'Smart road freight management system',
  );
  String get pressBackAgainToExit =>
      _t('برای خروج، دوباره دکمه بازگشت را بزنید', 'Press back again to exit');

  // Settings
  String get settings => _t('تنظیمات', 'Settings');
  String get language => _t('زبان', 'Language');
  String get languagePersian => _t('فارسی', 'Persian');
  String get languageEnglish => _t('انگلیسی', 'English');
  String get darkMode => _t('حالت تاریک', 'Dark mode');
  String get darkModeSubtitle =>
      _t('نمایش رابط کاربری با تم تیره', 'Use a dark color theme');
  String get settingsSubtitle => _t(
    'شخصی‌سازی ظاهر و زبان اپلیکیشن',
    'Customize app appearance and language',
  );
  String get helpSubtitle =>
      _t('راهنمای بخش‌های اپلیکیشن', 'App section guide');
  String helpRoleSubtitle(String role) => role == 'driver'
      ? _t('راهنمای استفاده برای رانندگان', 'Usage guide for drivers')
      : _t(
          'راهنمای استفاده برای متصدیان حمل‌ونقل',
          'Usage guide for transport coordinators',
        );
  String get appearance => _t('ظاهر', 'Appearance');
  String get localization => _t('زبان و منطقه', 'Language & region');

  // Drawer menu
  String get aboutUs => _t('درباره ما', 'About us');
  String get help => _t('راهنما', 'Help');
  String get support => _t('پشتیبانی', 'Support');
  String get changePassword => _t('تغییر رمز عبور', 'Change password');
  String get drawerOperations => _t('عملیات حمل‌ونقل', 'TRANSPORT OPERATIONS');
  String get drawerAccount => _t('حساب و تنظیمات', 'ACCOUNT & SETTINGS');
  String get drawerAssistance => _t('راهنمایی و ارتباط', 'HELP & CONTACT');
  String get accountActive => _t('حساب فعال', 'Active account');
  String get coordinatorOverview =>
      _t('نمای کلی عملکرد', 'Performance overview');
  String get completedCargos => _t('تکمیل‌شده', 'Completed');
  String get totalCargoValue => _t('ارزش کل بارها', 'Total cargo value');
  String get accountInformation => _t('اطلاعات حساب', 'Account information');
  String get transportTools => _t('ابزارهای مدیریت حمل', 'Transport tools');
  String get manageCargos => _t('مدیریت بارها', 'Manage cargos');
  String get createNewCargo => _t('ایجاد بار جدید', 'Create new cargo');
  String get secureAccount => _t('امنیت حساب', 'Account security');
  String get supportQuickHelp => _t(
    'پاسخ سریع برای مشکلات حساب، بار، راننده و مسیریابی',
    'Fast help for account, cargo, driver, and navigation issues',
  );
  String get copiedToClipboard =>
      _t('در کلیپ‌بورد کپی شد', 'Copied to clipboard');
  String get commonQuestions => _t('پرسش‌های پرتکرار', 'Common questions');
  String get supportBeforeContact => _t(
    'پیش از تماس، شماره موبایل حساب و شناسه بار را آماده داشته باشید.',
    'Before contacting support, have your account phone and cargo ID ready.',
  );
  String get faqCargoIssueTitle =>
      _t('چرا بار نمایش داده نمی‌شود؟', 'Why is a cargo not visible?');
  String get faqCargoIssueBody => _t(
    'اتصال اینترنت، فیلترهای فعال و نوع ماشین ثبت‌شده را بررسی کنید. راننده فقط بارهای باز و متناسب با ماشین خود را می‌بیند.',
    'Check connectivity, active filters, and the registered vehicle type. Drivers only see open cargos matching their vehicle.',
  );
  String get faqAccountIssueTitle =>
      _t('مشکل ورود یا انقضای نشست', 'Sign-in or expired session');
  String get faqAccountIssueBody => _t(
    'شماره را با قالب 09 وارد کنید. اگر نشست منقضی شد دوباره وارد شوید و در صورت تداوم مشکل با پشتیبانی تماس بگیرید.',
    'Enter the phone in 09 format. If the session expires, sign in again and contact support if the issue continues.',
  );
  String get faqNavigationIssueTitle =>
      _t('نقشه یا GPS کار نمی‌کند', 'Map or GPS is not working');
  String get faqNavigationIssueBody => _t(
    'دسترسی موقعیت، روشن بودن GPS و اتصال اینترنت را بررسی کنید؛ سپس صفحه مسیر را دوباره باز کنید.',
    'Check location permission, GPS, and connectivity, then reopen the route screen.',
  );
  String get transportSafetyTitle =>
      _t('ایمنی در اولویت است', 'Safety comes first');
  String get transportSafetyBody => _t(
    'هنگام رانندگی با برنامه کار نکنید. پیش از حرکت، مشخصات بار، مبدا، مقصد و اطلاعات طرف مقابل را کنترل کنید.',
    'Do not operate the app while driving. Before departure, verify cargo, origin, destination, and counterparty details.',
  );
  String get platformCapabilities =>
      _t('امکانات سامانه', 'Platform capabilities');
  String get platformValues => _t('اصول کاری ما', 'Our principles');
  String get platformValuesBody => _t(
    'شفافیت اطلاعات، امنیت حساب، انتخاب هوشمند بار و ارتباط سریع میان راننده و متصدی، پایه‌های این سامانه هستند.',
    'Information transparency, account security, smart cargo matching, and fast driver–coordinator communication are the foundation of this platform.',
  );
  String get aboutDescription => _t(
    'لجستیک سامانه‌ای هوشمند برای مدیریت حمل‌ونقل بار جاده‌ای است که رانندگان و متصدیان حمل‌ونقل را به یکدیگر متصل می‌کند.',
    'Logistics is a smart road freight platform that connects drivers and transport coordinators.',
  );
  String versionLabel(String version) =>
      _t('نسخه $version', 'Version $version');
  String get supportTitle => _t('تماس با پشتیبانی', 'Contact support');
  String get supportSubtitle => _t(
    'تیم پشتیبانی ما آماده پاسخگویی به سوالات شماست.',
    'Our support team is ready to help with your questions.',
  );
  String get supportPhone => _t('تلفن پشتیبانی', 'Support phone');
  String get supportHours => _t('ساعات پاسخگویی', 'Support hours');
  String get supportHoursValue =>
      _t('شنبه تا پنجشنبه ۸ تا ۱۸', 'Sat–Thu 8 AM – 6 PM');
  String get changePasswordHint => _t(
    'برای امنیت بیشتر، رمز عبور قوی انتخاب کنید.',
    'Choose a strong password for better security.',
  );
  String get currentPassword => _t('رمز عبور فعلی', 'Current password');
  String get newPassword => _t('رمز عبور جدید', 'New password');
  String get savePassword => _t('ذخیره رمز عبور', 'Save password');
  String get passwordChanged =>
      _t('رمز عبور با موفقیت تغییر کرد', 'Password changed successfully');
  String get helpAcceptCargoTitle => _t('پذیرش بار', 'Accepting cargo');
  String get helpAcceptCargoBody => _t(
    'از بخش بارها، بار مناسب را انتخاب و جزئیات آن را بررسی کنید. سپس با پذیرش بار، ماموریت در تب ماموریت‌ها نمایش داده می‌شود.',
    'From Cargos, pick a suitable load and review its details. After accepting, the mission appears in the Missions tab.',
  );
  String get helpGpsTitle => _t('فعال‌سازی GPS', 'Enabling GPS');
  String get helpGpsBody => _t(
    'با فعال کردن GPS در صفحه بارها، پیشنهادهای نزدیک‌تر و متناسب‌تر دریافت می‌کنید.',
    'Enable GPS on the Cargos page to receive closer and more relevant suggestions.',
  );
  String get helpVehicleTitle =>
      _t('ثبت اطلاعات خودرو', 'Vehicle registration');
  String get helpVehicleBody => _t(
    'در پروفایل، اطلاعات خودرو و نوع بارگیر را ثبت کنید تا بارهای متناسب پیشنهاد شوند.',
    'Add your vehicle and trailer type in Profile so matching cargos can be suggested.',
  );

  // Help — driver
  String get helpDriverHomeTitle => _t('خانه', 'Home');
  String get helpDriverHomeBody => _t(
    'پس از ورود، ابتدا به صفحه خانه می‌روید. در این صفحه خلاصه وضعیت (بارهای نزدیک، بارهای موجود و ماموریت‌های فعال)، دسترسی سریع به بخش‌ها و چند بار پیشنهادی را می‌بینید. منوی همبرگر و نوار پایین هم همیشه در دسترس هستند.',
    'After sign-in you land on Home. There you see a status summary (nearby cargos, available loads, and active missions), quick actions, and a few suggested cargos. The hamburger menu and bottom navigation stay available.',
  );
  String get helpDriverCargosTitle => _t('بارها', 'Cargos');
  String get helpDriverCargosBody => _t(
    'در تب بارها، لیست بارهای متناسب با نوع بارگیر خودروی شما نمایش داده می‌شود. با فعال‌سازی GPS، بارهای نزدیک‌تر در بالای لیست قرار می‌گیرند. روی هر بار بزنید تا جزئیات مبدا، مقصد، وزن و فاصله را ببینید.',
    'In the Cargos tab, you see loads that match your trailer type. With GPS enabled, closer loads appear at the top. Tap a load to view origin, destination, weight, and distance.',
  );
  String get helpDriverGpsTitle =>
      _t('GPS و پیشنهاد هوشمند', 'GPS & smart suggestions');
  String get helpDriverGpsBody => _t(
    'با روشن کردن GPS در بالای صفحه بارها، موقعیت شما شناسایی می‌شود و بارهای نزدیک‌تر با فاصله کیلومتری نمایش داده می‌شوند. بدون GPS فقط بارهای متناسب با نوع بارگیر نشان داده می‌شوند.',
    'Turn on GPS at the top of the Cargos page to share your location. Nearby loads are shown with distance in km. Without GPS, only loads matching your trailer type are listed.',
  );
  String get helpDriverAcceptTitle => _t('پذیرش بار', 'Accepting cargo');
  String get helpDriverAcceptBody => _t(
    'در صفحه جزئیات بار، اطلاعات کامل شامل مبدا، مقصد، نوع کالا و متصدی را بررسی کنید. با زدن «پذیرش بار» و تأیید، این بار به ماموریت‌های فعال شما اضافه می‌شود.',
    'On the cargo details screen, review origin, destination, goods type, and coordinator info. Tap Accept cargo and confirm to add it to your active missions.',
  );
  String get helpDriverMissionsTitle => _t('ماموریت‌ها', 'Missions');
  String get helpDriverMissionsBody => _t(
    'در تب ماموریت‌ها، بارهای پذیرفته‌شده را می‌بینید. با فیلترهای فعال، تکمیل‌شده و همه می‌توانید وضعیت ماموریت‌ها را جدا کنید. از هر ماموریت می‌توانید به صفحه مسیریابی بروید.',
    'In the Missions tab, view accepted cargos. Use Active, Completed, and All filters to sort missions. From each mission you can open the navigation screen.',
  );
  String get helpDriverNavigationTitle => _t('مسیریابی', 'Navigation');
  String get helpDriverNavigationBody => _t(
    'در صفحه مسیریابی، نقشه نشان مسیر تا مبدا و سپس تا مقصد را نمایش می‌دهد. می‌توانید ناوبری را شروع کنید، موقعیت خود را روی نقشه ببینید و در صورت نیاز نقشه را در اپ نشان باز کنید.',
    'On the navigation screen, Neshan Map shows the route to the origin and then to the destination. Start navigation, see your live position on the map, or open the route in the Neshan app.',
  );
  String get helpDriverProfileTitle =>
      _t('پروفایل و خودرو', 'Profile & vehicle');
  String get helpDriverProfileBody => _t(
    'در تب پروفایل، نام و اطلاعات حساب خود را می‌بینید. اطلاعات خودرو شامل پلاک، مدل، نوع بارگیر و ظرفیت را ثبت یا ویرایش کنید تا بارهای مناسب‌تر پیشنهاد شوند. از همین بخش می‌توانید از حساب خارج شوید.',
    'In Profile, view your name and account info. Add or edit vehicle details — plate, model, trailer type, and capacity — for better cargo matches. You can also sign out from here.',
  );
  String get helpDriverMenuTitle => _t('منو و تنظیمات', 'Menu & settings');
  String get helpDriverMenuBody => _t(
    'از منوی کناری (آیکون همبرگر) به تنظیمات، تغییر رمز عبور، راهنما، پشتیبانی و درباره ما دسترسی دارید. در تنظیمات می‌توانید زبان (فارسی/انگلیسی) و حالت تاریک را تغییر دهید.',
    'From the side menu (hamburger icon), open Settings, Change password, Help, Support, and About. In Settings you can switch language (Persian/English) and dark mode.',
  );

  // Help — coordinator
  String get helpCoordinatorHomeTitle => _t('خانه', 'Home');
  String get helpCoordinatorHomeBody => _t(
    'پس از ورود، ابتدا به صفحه خانه می‌روید. آمار کلی بارها و رانندگان، میانبر ثبت بار و آخرین بارها در این صفحه نمایش داده می‌شود. منوی همبرگر و نوار پایین نیز در دسترس هستند.',
    'After sign-in you land on Home. See overall cargo and driver stats, a shortcut to add cargo, and your recent cargos. The hamburger menu and bottom navigation stay available.',
  );
  String get helpCoordinatorCargosTitle =>
      _t('مدیریت بارها', 'Cargo management');
  String get helpCoordinatorCargosBody => _t(
    'در تب بارها، همه بارهای ثبت‌شده توسط شما نمایش داده می‌شوند. وضعیت هر بار (در انتظار، در حال حمل، تکمیل‌شده و ...) و راننده تخصیص‌یافته در کارت بار قابل مشاهده است. روی هر بار بزنید تا جزئیات کامل را ببینید.',
    'In the Cargos tab, see all cargos you registered. Each card shows status (pending, in transit, completed, etc.) and the assigned driver. Tap a cargo for full details.',
  );
  String get helpCoordinatorAddCargoTitle => _t('ثبت بار جدید', 'Adding cargo');
  String get helpCoordinatorAddCargoBody => _t(
    'با دکمه «ثبت بار» در صفحه اصلی، فرم ثبت بار باز می‌شود. مبدا، مقصد، نوع بارگیر، نوع کالا و وزن را وارد کنید. با «برآورد قیمت» هزینه تقریبی محاسبه می‌شود و پس از ثبت، بار در لیست شما ظاهر می‌شود.',
    'Tap Add cargo on the home screen to open the form. Enter origin, destination, trailer type, goods type, and weight. Use Estimate price for an approximate cost, then submit to add the cargo to your list.',
  );
  String get helpCoordinatorCargoDetailTitle =>
      _t('جزئیات بار', 'Cargo details');
  String get helpCoordinatorCargoDetailBody => _t(
    'در صفحه جزئیات بار، مسیر، وزن، وضعیت حمل و اطلاعات راننده تخصیص‌یافته را می‌بینید. اگر راننده‌ای اختصاص نیافته باشد، می‌توانید از «مشاهده رانندگان نزدیک» رانندگان فعال نزدیک مبدا را ببینید.',
    'On cargo details, view the route, weight, shipping progress, and assigned driver. If no driver is assigned yet, use View nearby drivers to see active drivers near the origin.',
  );
  String get helpCoordinatorDriversTitle =>
      _t('رانندگان فعال', 'Active drivers');
  String get helpCoordinatorDriversBody => _t(
    'در تب رانندگان، لیست رانندگانی که در حال حاضر فعال هستند نمایش داده می‌شود. نام، پلاک خودرو، نوع بارگیر و تعداد سفرهای انجام‌شده هر راننده در این بخش قابل مشاهده است.',
    'In the Drivers tab, see drivers who are currently active. Each entry shows name, license plate, trailer type, and completed trip count.',
  );
  String get helpCoordinatorNearbyTitle =>
      _t('رانندگان نزدیک', 'Nearby drivers');
  String get helpCoordinatorNearbyBody => _t(
    'در تب نزدیک، رانندگان فعالی که به مبدا بار نزدیک‌تر هستند پیشنهاد می‌شوند. این بخش برای یافتن سریع راننده مناسب برای بارهای جدید مفید است.',
    'In the Nearby tab, active drivers closer to the cargo origin are suggested. This helps you quickly find a suitable driver for new loads.',
  );
  String get helpCoordinatorEditTitle =>
      _t('ویرایش و حذف بار', 'Editing and deleting cargo');
  String get helpCoordinatorEditBody => _t(
    'از صفحه جزئیات هر بار می‌توانید اطلاعات آن را ویرایش کنید یا در صورت نیاز بار را حذف کنید. پیش از حذف، شناسه و وضعیت بار را دوباره کنترل کنید.',
    'From cargo details, you can edit its information or delete it when needed. Before deletion, verify the cargo ID and status.',
  );
  String get helpCoordinatorSecurityTitle =>
      _t('امنیت و اطلاعات حساب', 'Account information and security');
  String get helpCoordinatorSecurityBody => _t(
    'در پروفایل، نام و کد ملی را به‌روز کنید. از منوی امنیت نیز رمز عبور را تغییر دهید و اطلاعات ورود را در اختیار دیگران قرار ندهید.',
    'Update your name and national code in Profile. Use Security to change your password, and never share sign-in information.',
  );
  String get helpCoordinatorProfileTitle => _t('پروفایل', 'Profile');
  String get helpCoordinatorProfileBody => _t(
    'در تب پروفایل، اطلاعات حساب کاربری شامل نام، شماره تماس و ایمیل نمایش داده می‌شود. از این بخش می‌توانید از حساب خود خارج شوید.',
    'In Profile, view your account details including name, phone, and email. You can sign out from here.',
  );
  String get helpCoordinatorMenuTitle => _t('منو و تنظیمات', 'Menu & settings');
  String get helpCoordinatorMenuBody => _t(
    'از منوی کناری به تنظیمات، تغییر رمز عبور، راهنما، پشتیبانی و درباره ما دسترسی دارید. در تنظیمات زبان اپلیکیشن و حالت تاریک قابل تغییر است.',
    'From the side menu, open Settings, Change password, Help, Support, and About. In Settings you can change the app language and dark mode.',
  );

  // Auth
  String get loginTitle => _t('ورود به حساب کاربری', 'Sign in to your account');
  String get userType => _t('نوع کاربری', 'User type');
  String get phoneNumber => _t('شماره موبایل', 'Phone number');
  String get password => _t('رمز عبور', 'Password');
  String get login => _t('ورود', 'Sign in');
  String get rememberMe => _t('مرا به خاطر بسپار', 'Remember me');
  String get loginBiometric => _t(
    'ورود با اثر انگشت / پین / الگو',
    'Sign in with fingerprint / PIN / pattern',
  );
  String get loginLoginFirst => _t(
    'ابتدا یک‌بار با رمز عبور وارد شوید',
    'Sign in with password once first',
  );
  String get loginAuthReason => _t(
    'با اثر انگشت، پین یا الگوی دستگاه وارد شوید',
    'Authenticate with fingerprint, PIN, or pattern',
  );
  String get loginAccountTitle => _t('ورود به حساب', 'Account sign-in');
  String get loginBiometricHint =>
      _t('انگشت خود را روی حسگر قرار دهید', 'Place your fingerprint');
  String get loginBiometricNotRecognized =>
      _t('اثر انگشت شناسایی نشد', 'Fingerprint not recognized');
  String get loginBiometricRequired =>
      _t('احراز هویت لازم است', 'Authentication required');
  String get loginDeviceLockRequired =>
      _t('قفل دستگاه لازم است', 'Device lock required');
  String get loginEnableDeviceLock => _t(
    'ابتدا قفل صفحه یا اثر انگشت را در تنظیمات دستگاه فعال کنید',
    'Enable screen lock or fingerprint in device settings first',
  );
  String get loginGoToSettings => _t('تنظیمات', 'Settings');
  String get loginNoAuthentication => _t(
    'این دستگاه از احراز هویت پشتیبانی نمی‌کند',
    'This device does not support authentication',
  );
  String get loginNeedPasswordFirst => _t(
    'برای فعال‌سازی ورود سریع، ابتدا با شماره و رمز عبور وارد شوید',
    'Sign in with phone and password first to enable quick login',
  );
  String get loginFingerprintError =>
      _t('خطا در احراز هویت اثر انگشت', 'Fingerprint authentication error');
  String get loginFingerprintNotAvailable => _t(
    'حسگر اثر انگشت در دسترس نیست یا پشتیبانی نمی‌شود',
    'Fingerprint sensor is unavailable or unsupported',
  );
  String get loginFingerprintNotEnrolled => _t(
    'اثر انگشتی ثبت نشده است. ابتدا در تنظیمات دستگاه ثبت کنید',
    'No fingerprints enrolled. Register one in device settings first',
  );
  String get loginFingerprintNotSet => _t(
    'قفل صفحه روی این دستگاه تنظیم نشده است',
    'No screen lock is set on this device',
  );
  String get loginFingerprintLockedOut => _t(
    'به دلیل تلاش‌های ناموفق موقتاً قفل شده است',
    'Temporarily locked due to too many failed attempts',
  );
  String get loginFingerprintPermanentlyLockedOut => _t(
    'احراز هویت به‌طور دائم قفل شده است. از قفل دستگاه استفاده کنید',
    'Authentication is permanently locked. Use device credentials',
  );
  String get noAccount => _t('حساب کاربری ندارید؟', "Don't have an account?");
  String get signup => _t('ثبت‌نام', 'Sign up');
  String get signupTitle => _t('ثبت‌نام', 'Sign up');
  String get fullName => _t('نام و نام خانوادگی', 'Full name');
  String get firstName => _t('نام', 'First name');
  String get lastName => _t('نام خانوادگی', 'Last name');
  String get emailOptional => _t('ایمیل (اختیاری)', 'Email (optional)');
  String get confirmPassword => _t('تکرار رمز عبور', 'Confirm password');
  String get haveAccount =>
      _t('قبلاً ثبت‌نام کرده‌اید؟', 'Already have an account?');
  String get phoneRequired =>
      _t('شماره موبایل الزامی است', 'Phone number is required');
  String get phoneInvalid =>
      _t('شماره موبایل معتبر نیست', 'Invalid phone number');
  String get passwordRequired =>
      _t('رمز عبور الزامی است', 'Password is required');
  String get passwordMinLength => _t(
    'رمز عبور حداقل ۸ کاراکتر باشد',
    'Password must be at least 8 characters',
  );
  String get nameRequired => _t('نام الزامی است', 'Name is required');
  String get firstNameRequired =>
      _t('نام الزامی است', 'First name is required');
  String get lastNameRequired =>
      _t('نام خانوادگی الزامی است', 'Last name is required');
  String get passwordsMismatch =>
      _t('رمز عبور و تکرار آن یکسان نیست', 'Passwords do not match');
  String get createAccount => _t('ایجاد حساب کاربری', 'Create an account');
  String get personalInfo => _t('اطلاعات شخصی', 'Personal information');
  String get securityInfo => _t('امنیت حساب', 'Account security');
  String signupInApp(String appName) =>
      _t('در $appName ثبت‌نام کنید', 'Sign up for $appName');
  String get driverSignupHint =>
      _t('مشاهده و پذیرش بار', 'View and accept cargos');
  String get coordinatorSignupHint =>
      _t('ثبت و مدیریت بار', 'Register and manage cargos');

  // Roles
  String roleLabel(String role) => role == 'driver'
      ? _t('راننده', 'Driver')
      : _t('متصدی حمل‌ونقل', 'Transport coordinator');
  String roleSegmentLabel(String role) =>
      role == 'driver' ? _t('راننده', 'Driver') : _t('متصدی', 'Coordinator');

  // Navigation
  String get home => _t('خانه', 'Home');
  String get cargos => _t('بارها', 'Cargos');
  String get missions => _t('ماموریت‌ها', 'Missions');
  String get profile => _t('پروفایل', 'Profile');
  String get nationalCode => _t('کد ملی', 'National code');
  String get nationalCodeInvalid =>
      _t('کد ملی باید ۱۰ رقمی باشد', 'National code must be 10 digits');
  String get drivers => _t('رانندگان', 'Drivers');
  String get nearby => _t('نزدیک', 'Nearby');
  String get addCargo => _t('ثبت بار', 'Add cargo');

  // Home dashboard
  String get homeDriverSubtitle => _t(
    'بارهای نزدیک و ماموریت‌های فعال را از اینجا پیگیری کنید',
    'Track nearby cargos and active missions from here',
  );
  String get homeCoordinatorSubtitle => _t(
    'بارها و رانندگان را یکجا مدیریت کنید',
    'Manage cargos and drivers in one place',
  );
  String get homeQuickActions => _t('دسترسی سریع', 'Quick actions');
  String get homeSuggestedCargos => _t('بارهای پیشنهادی', 'Suggested cargos');
  String get homeRecentCargos => _t('آخرین بارها', 'Recent cargos');
  String get homeViewAll => _t('مشاهده همه', 'View all');
  String get homeStatNearby => _t('نزدیک', 'Nearby');
  String get homeStatAvailable => _t('قابل پذیرش', 'Available');
  String get homeStatActiveMissions => _t('ماموریت فعال', 'Active');
  String get homeStatTotalCargos => _t('کل بارها', 'Total cargos');
  String get homeStatActiveDrivers => _t('در انتظار', 'Pending');
  String get homeStatNearbyDrivers => _t('تخصیص‌یافته', 'Assigned');
  String get homePendingCargos => _t('در انتظار', 'Pending');
  String get homeInTransit => _t('تخصیص‌یافته', 'Assigned');

  // Driver cargos
  String hello(String name) => _t('سلام $name!', 'Hello $name!');
  String cargoTypeLabel(String type) =>
      _t('نوع بارگیر: $type', 'Trailer type: $type');
  String get notRegistered => _t('ثبت نشده', 'Not set');
  String get province => _t('استان', 'Province');
  String get gpsEnabled => _t('GPS فعال است', 'GPS is on');
  String get gpsDisabled => _t('GPS غیرفعال است', 'GPS is off');
  String get gpsEnabledHint => _t(
    'بارهای نزدیک بر اساس موقعیت شما پیشنهاد می‌شوند',
    'Nearby cargos are suggested based on your location',
  );
  String get gpsDisabledHint => _t(
    'برای دریافت پیشنهاد هوشمند GPS را فعال کنید',
    'Enable GPS for smart cargo suggestions',
  );
  String get gpsUnavailable => _t(
    'موقعیت GPS در دسترس نیست. دسترسی موقعیت را بررسی کنید.',
    'GPS location is unavailable. Check location permission.',
  );
  String get gpsEnableFailed => _t(
    'فعال‌سازی موقعیت انجام نشد. دسترسی و سرویس مکان را بررسی کنید.',
    'Could not enable location. Check permission and location services.',
  );
  String get gpsDisabledSystemHint =>
      _t('GPS در اپ خاموش شد', 'GPS is turned off in the app');
  String get gpsDisableTitle => _t('خاموش کردن GPS', 'Turn off GPS');
  String get gpsDisableMessage => _t(
    'پیشنهاد بارهای نزدیک غیرفعال شد و موقعیت شما دیگر برای این بخش استفاده نمی‌شود. '
        'برای خاموش کردن موقعیت دستگاه می‌توانید به تنظیمات موقعیت بروید.',
    'Nearby cargo suggestions are turned off and your location is no longer used here. '
        'To turn off device location, open location settings.',
  );
  String get gpsDisableConfirm => _t('متوجه شدم', 'Got it');
  String get openLocationSettings => _t('تنظیمات موقعیت', 'Location settings');
  String get locationEnableTitle => _t('فعال‌سازی موقعیت', 'Enable location');
  String get locationEnableAction => _t('فعال‌سازی', 'Enable');
  String get locationEnableNearbyMessage => _t(
    'برای نمایش بارهای نزدیک، دسترسی به موقعیت دستگاه لازم است.',
    'Device location is required to show nearby cargos.',
  );
  String get locationEnableNavigationMessage => _t(
    'برای مسیریابی از موقعیت شما، دسترسی به GPS دستگاه لازم است.',
    'Device GPS is required to navigate from your location.',
  );
  String get locationPermissionDeniedForever => _t(
    'دسترسی موقعیت برای این اپ مسدود شده است. از تنظیمات برنامه آن را فعال کنید.',
    'Location access is blocked for this app. Enable it in app settings.',
  );
  String get openAppSettings => _t('تنظیمات برنامه', 'App settings');
  String get loadingCargos =>
      _t('در حال بارگذاری بارها...', 'Loading cargos...');
  String get noCargoFound => _t('باری یافت نشد', 'No cargo found');
  String get noMatchingCargo => _t(
    'در حال حاضر باری متناسب با نوع بارگیر شما وجود ندارد',
    'No cargo matches your trailer type right now',
  );
  String get enableGpsForNearby => _t(
    'برای مشاهده بارهای نزدیک، GPS را فعال کنید',
    'Enable GPS to see nearby cargos',
  );
  String get nearbyCargos => _t('بارهای نزدیک', 'Nearby cargos');
  String get otherMatchingCargos =>
      _t('سایر بارهای متناسب', 'Other matching cargos');
  String get allMatchingCargos =>
      _t('همه بارهای متناسب', 'All matching cargos');
  String get kmAway => _t('کیلومتر', 'km');
  String kmDistance(num km) => _t('$km کیلومتر', '$km km');

  // Missions
  String get myMissions => _t('ماموریت‌های من', 'My missions');
  String activeMissionsCount(int count) =>
      _t('$count ماموریت فعال', '$count active missions');
  String get missionsSubtitle => _t(
    'بارهای پذیرفته‌شده شما در این بخش نمایش داده می‌شوند',
    'Accepted cargos appear in this section',
  );
  String get filterActive => _t('فعال', 'Active');
  String get filterCompleted => _t('تکمیل‌شده', 'Completed');
  String get filterAll => _t('همه', 'All');
  String get loadingMissions =>
      _t('در حال بارگذاری ماموریت‌ها...', 'Loading missions...');
  String get noActiveMission =>
      _t('ماموریت فعالی ندارید', 'No active missions');
  String get noMissionFound => _t('ماموریتی یافت نشد', 'No missions found');
  String get acceptCargoHint => _t(
    'با پذیرش بار، ماموریت جدید اینجا نمایش داده می‌شود',
    'Accept a cargo to see a new mission here',
  );
  String get navigation => _t('مسیریابی', 'Navigate');

  // Profile
  String get email => _t('ایمیل', 'Email');
  String get logout => _t('خروج از حساب', 'Sign out');
  String get logoutConfirmTitle => _t('خروج از حساب', 'Sign out');
  String get logoutConfirmMessage => _t(
    'آیا مطمئن هستید که می‌خواهید از حساب کاربری خارج شوید؟',
    'Are you sure you want to sign out?',
  );
  String get vehicleInfo => _t('اطلاعات خودرو', 'Vehicle info');
  String get completeVehicleProfile =>
      _t('تکمیل مشخصات خودرو', 'Complete vehicle details');
  String get completeVehicleBeforeAccepting => _t(
    'برای پذیرش بار، به پروفایل بروید و ابتدا پلاک، مدل خودرو و نوع بارگیر خود را وارد کنید.',
    'To accept a cargo, go to your profile and first enter your license plate, vehicle model, and trailer type.',
  );
  String get goToProfile => _t('رفتن به پروفایل', 'Go to profile');
  String get notNow => _t('فعلاً نه', 'Not now');
  String get edit => _t('ویرایش', 'Edit');
  String get save => _t('ذخیره', 'Save');
  String get register => _t('ثبت', 'Add');
  String get vehiclePlate => _t('پلاک خودرو', 'License plate');
  String get vehicleModel => _t('مدل خودرو', 'Vehicle model');
  String get trailerType => _t('نوع بارگیر', 'Trailer type');
  String get capacity => _t('ظرفیت', 'Capacity');
  String tons(num value) => _t('$value تن', '$value tons');
  String get vehicleNotRegistered =>
      _t('اطلاعات خودرو ثبت نشده', 'Vehicle info not set');
  String get vehicleRegisterHint => _t(
    'برای دریافت بارهای متناسب، اطلاعات خودرو را ثبت کنید',
    'Add your vehicle info to receive matching cargos',
  );
  String get vehicleSaved => _t('اطلاعات خودرو ذخیره شد', 'Vehicle info saved');

  // Coordinator
  String get cargoManagement => _t('مدیریت بارها', 'Cargo management');
  String get loading => _t('در حال بارگذاری...', 'Loading...');
  String driverLabel(String name) => _t('راننده: $name', 'Driver: $name');
  String get activeDrivers => _t('رانندگان فعال', 'Active drivers');
  String get nearbyDrivers => _t('رانندگان نزدیک', 'Nearby drivers');
  String get loadingDrivers =>
      _t('در حال بارگذاری رانندگان...', 'Loading drivers...');
  String get searchingNearbyDrivers =>
      _t('جستجوی رانندگان نزدیک...', 'Searching nearby drivers...');
  String get noDriversFound => _t('راننده‌ای یافت نشد', 'No drivers found');
  String get noActiveDrivers =>
      _t('راننده فعالی یافت نشد', 'No active drivers found');
  String get noNearbyDrivers =>
      _t('راننده نزدیکی یافت نشد', 'No nearby drivers found');
  String get nearbyDriversHint => _t(
    'رانندگان فعال نزدیک به مبدا بار به شما پیشنهاد می‌شوند',
    'Active drivers near the cargo origin are suggested to you',
  );
  String get active => _t('فعال', 'Active');
  String tripsCount(num count) => _t('$count سفر', '$count trips');

  // Cargo details
  String get cargoDetails => _t('جزئیات بار', 'Cargo details');
  String get cargoStatusTitle => _t('وضعیت بار', 'Cargo status');
  String get acceptCargo => _t('پذیرش بار', 'Accept cargo');
  String acceptCargoConfirm(String title) => _t(
    'آیا از پذیرش بار «$title» اطمینان دارید؟',
    'Are you sure you want to accept "$title"?',
  );
  String get cargoAccepted =>
      _t('بار با موفقیت پذیرفته شد', 'Cargo accepted successfully');
  String get viewRoute => _t('مشاهده مسیر', 'View route');
  String get origin => _t('مبدا', 'Origin');
  String get destination => _t('مقصد', 'Destination');
  String get distance => _t('فاصله', 'Distance');
  String distanceKm(num km) => _t('$km کیلومتر', '$km km');
  String get goodsType => _t('نوع کالا', 'Goods type');
  String get weight => _t('وزن', 'Weight');
  String get coordinator => _t('متصدی', 'Coordinator');
  String nearbyCargoDistance(num km) => _t(
    'این بار $km کیلومتر از شما فاصله دارد',
    'This cargo is $km km away from you',
  );
  String get assignedDriver => _t('راننده تخصیص‌یافته', 'Assigned driver');
  String get name => _t('نام', 'Name');
  String get phone => _t('تلفن', 'Phone');
  String get shippingProgress => _t('پیشرفت حمل', 'Shipping progress');
  String get viewNearbyDrivers =>
      _t('مشاهده رانندگان نزدیک', 'View nearby drivers');
  String get deleteCargo => _t('حذف بار', 'Delete cargo');
  String deleteCargoConfirm(String title) =>
      _t('آیا از حذف بار «$title» اطمینان دارید؟', 'Delete cargo "$title"?');
  String get delete => _t('حذف', 'Delete');
  String get cargoDeleted => _t('بار حذف شد', 'Cargo deleted');
  String cargoStatusUpdated(String status) =>
      _t('وضعیت به «$status» تغییر کرد', 'Status updated to "$status"');
  String get markCargoDone => _t('ثبت تحویل', 'Mark delivered');
  String get cancelCargo => _t('لغو بار', 'Cancel cargo');
  String get genericError => _t('خطایی رخ داد', 'Something went wrong');
  String get filterCargos => _t('فیلتر بارها', 'Filter cargos');
  String get clearFilters => _t('پاک کردن فیلتر', 'Clear filters');
  String get applyFilters => _t('اعمال فیلتر', 'Apply filters');
  String get minPrice => _t('حداقل قیمت', 'Min price');
  String get maxPrice => _t('حداکثر قیمت', 'Max price');
  String get originOstan => _t('استان مبدا', 'Origin province');
  String get destinationOstan => _t('استان مقصد', 'Destination province');
  String get coordinatesSection => _t('مختصات جغرافیایی', 'Coordinates');
  String get coordinatesOptional => _t(
    'اختیاری — برای نمایش بارهای نزدیک و مسیریابی دقیق‌تر',
    'Optional — improves nearby cargo and routing accuracy',
  );
  String get originLatitude => _t('عرض مبدا', 'Origin latitude');
  String get originLongitude => _t('طول مبدا', 'Origin longitude');
  String get destinationLatitude => _t('عرض مقصد', 'Destination latitude');
  String get destinationLongitude => _t('طول مقصد', 'Destination longitude');
  String get invalidCoordinate =>
      _t('مختصات نامعتبر است', 'Invalid coordinate');
  String get profileRefreshed => _t('پروفایل به‌روز شد', 'Profile updated');
  String get profileRefreshFailed => _t(
    'به‌روزرسانی پروفایل ممکن نبود. از اطلاعات ذخیره‌شده استفاده می‌شود.',
    'Could not refresh profile. Using saved account data.',
  );
  String get refreshProfile => _t('به‌روزرسانی پروفایل', 'Refresh profile');
  String get deliveryMarkedByCoordinator => _t(
    'پس از تحویل، متصدی وضعیت بار را به‌روزرسانی می‌کند',
    'After delivery, the coordinator will update the cargo status',
  );
  String get editCargo => _t('ویرایش بار', 'Edit cargo');
  String get cargoEditMode => _t('نوع ویرایش', 'Edit mode');
  String get partialCargoEdit => _t(
    'ویرایش جزئی — فقط موارد تغییرکرده',
    'Partial edit — changed fields only',
  );
  String get fullCargoEdit =>
      _t('ویرایش کامل — ذخیره همه مشخصات', 'Full edit — save all details');
  String get cargoUpdated => _t('بار به‌روزرسانی شد', 'Cargo updated');
  String get loadMore => _t('بارگذاری بیشتر', 'Load more');
  String get missionsSyncNote => _t(
    'مأموریت‌های پذیرفته‌شده روی این دستگاه ذخیره می‌شوند. '
        'وضعیت نهایی تحویل توسط متصدی ثبت می‌شود.',
    'Accepted missions are stored on this device. '
        'Final delivery status is updated by the coordinator.',
  );
  String get selectMachineType =>
      _t('نوع ماشین را انتخاب کنید', 'Select machine type');
  String get machineId => _t('شناسه ماشین', 'Machine ID');
  String get provinceIdOptional =>
      _t('شناسه استان (اختیاری)', 'Province ID (optional)');
  String get provinceIdInvalid =>
      _t('شناسه استان معتبر نیست', 'Invalid province ID');
  String get signupDriverMachineIdHint => _t(
    'نوع ماشین خود را انتخاب کنید. انتخاب استان اختیاری است.',
    'Select your machine type. Choosing a province is optional.',
  );
  String get provinceOptional => _t('استان (اختیاری)', 'Province (optional)');
  String get provinceNotSelected =>
      _t('بدون انتخاب استان', 'No province selected');
  String get signupReferencesRetry => _t(
    'دریافت لیست ناموفق بود؛ تلاش دوباره',
    'Could not load options; retry',
  );
  String get machineSavedLocally => _t(
    'اطلاعات خودرو روی دستگاه ذخیره شد. تطابق با سرور هنگام پذیرش بار بررسی می‌شود.',
    'Vehicle info saved on device. Server matching is checked when accepting cargo.',
  );

  // Route
  String get routeTitle => _t('مسیریابی', 'Navigation');
  String get loadingRoute => _t('در حال بارگذاری مسیر...', 'Loading route...');
  String get locationRequiredForRoute => _t(
    'برای مسیریابی از موقعیت شما تا مبدا بار، دسترسی به GPS لازم است',
    'GPS access is required to route from your location to the cargo origin',
  );
  String get driverRouteGpsTooFar => _t(
    'موقعیت GPS از این بار خیلی دور است. در شبیه‌ساز Location را نزدیک مسیر تنظیم کنید.',
    'GPS is too far from this trip. In the emulator set Location near the route.',
  );
  String get routeApproximateFallback => _t(
    'مسیر جاده‌ای در دسترس نبود؛ مسیر تقریبی نمایش داده شد',
    'Road route unavailable; showing an approximate path',
  );
  String get routeNotFound => _t('مسیر یافت نشد', 'Route not found');
  String get routeLoadFailed => _t(
    'مسیر جاده‌ای دریافت نشد. اتصال اینترنت و کلید نشان را بررسی کنید و دوباره تلاش کنید.',
    'Could not load the road route. Check internet and Neshan key, then try again.',
  );
  String get routeToOrigin => _t('مسیریابی به مبدا', 'Navigate to origin');
  String get routeToDestination =>
      _t('مسیریابی به مقصد', 'Navigate to destination');
  String get neshanMap => _t('نقشه نشان', 'Neshan Map');
  String get neshanApiNote => _t(
    'اتصال به API نشان در نسخه بعدی',
    'Neshan API integration in the next version',
  );
  String get neshanMapLoadError =>
      _t('بارگذاری نقشه ناموفق بود', 'Could not load map');
  String get openInNeshanMaps =>
      _t('باز کردن در نقشه نشان', 'Open in Neshan Maps');
  String get returnToRoute => _t('بازگشت به مسیر', 'Return to route');
  String get routeThen => _t('سپس', 'Then');
  String get routeRerouting =>
      _t('در حال یافتن مسیر جایگزین...', 'Finding an alternative route...');
  String get routeRerouted =>
      _t('مسیر جایگزین نمایش داده شد', 'Alternative route shown');
  String get neshanErrorGeneric =>
      _t('خطا در سرویس نشان', 'Neshan service error');
  String get neshanErrorServiceList => _t(
    'این سرویس‌ها را روی کلید نشان فعال کنید: Geocoding Plus، مسیریابی با ترافیک و نقشه استاتیک',
    'Enable Geocoding Plus, Routing with traffic, and Static arc map on your Neshan key',
  );
  String get neshanErrorKeyType =>
      _t('نوع کلید نشان نامعتبر است', 'Invalid Neshan API key type');
  String get neshanErrorWhitelist =>
      _t('محدودیت دامنه/پکیج کلید نشان', 'Neshan key scope mismatch');
  String get neshanErrorBackendProxy => _t(
    'پراکسی سرور نشان در دسترس نیست',
    'Neshan server proxy is unavailable',
  );
  String get neshanErrorBackendUnauthorized =>
      _t('نشست منقضی شده است', 'Session expired');
  String get neshanErrorBackendFailed =>
      _t('ارتباط با پراکسی نشان برقرار نشد', 'Could not reach Neshan proxy');
  String get neshanErrorKeyNotFound =>
      _t('کلید API نشان تنظیم نشده است', 'Neshan API key is missing');
  String get neshanErrorLimit => _t(
    'سقف استفاده از API نشان پر شده است',
    'Neshan API usage limit exceeded',
  );
  String get neshanErrorRate =>
      _t('درخواست‌های زیاد به API نشان', 'Too many Neshan API requests');
  String get neshanErrorAddressEmpty => _t('آدرس خالی است', 'Address is empty');
  String get neshanErrorGeocodingNotFound =>
      _t('موقعیتی برای این آدرس یافت نشد', 'No location found for address');
  String get neshanErrorGeocodingInvalid =>
      _t('پاسخ آدرس‌یابی نامعتبر است', 'Invalid geocoding response');
  String get neshanErrorGeocodingFailed =>
      _t('خطا در آدرس‌یابی', 'Geocoding request failed');
  String get neshanErrorRoutingNotFound =>
      _t('مسیری یافت نشد', 'No route found');
  String get neshanErrorRoutingInvalid =>
      _t('پاسخ مسیریابی نامعتبر است', 'Invalid routing response');
  String get neshanErrorRoutingNoLegs =>
      _t('مسیر بخش معتبری ندارد', 'Route has no valid segments');
  String get neshanErrorRoutingFailed =>
      _t('خطا در مسیریابی', 'Routing request failed');
  String get neshanErrorSdkResponse =>
      _t('پاسخ خالی از SDK نشان', 'Empty response from Neshan SDK');
  String get neshanErrorInvalidArgument =>
      _t('پارامترهای درخواست نامعتبر است', 'Invalid request parameters');
  String get cargoOriginPoint => _t('مبدا بار', 'Cargo origin');
  String get cargoDestinationPoint => _t('مقصد بار', 'Cargo destination');
  String get totalDistance => _t('فاصله کل', 'Total distance');
  String get statusLabel => _t('وضعیت', 'Status');
  String startNavigationTo(String destination) =>
      _t('شروع مسیریابی به $destination', 'Start navigation to $destination');
  String get arrivedAtOriginContinue => _t(
    'رسیدم به مبدا — ادامه به مقصد',
    'Arrived at origin — continue to destination',
  );
  String get markDelivered => _t('بار را تحویل دادم', 'Mark as delivered');
  String get cargoDelivered =>
      _t('بار با موفقیت تحویل شد', 'Cargo delivered successfully');
  String navigationToApi(String destination) => _t(
    'مسیریابی به $destination (API نشان)',
    'Navigation to $destination (Neshan API)',
  );

  // Add cargo
  String get addNewCargo => _t('ثبت بار جدید', 'Add new cargo');
  String get cargoTitle => _t('عنوان بار', 'Cargo title');
  String get titleRequired => _t('عنوان الزامی است', 'Title is required');
  String get originRequired => _t('مبدا الزامی است', 'Origin is required');
  String get destinationRequired =>
      _t('مقصد الزامی است', 'Destination is required');
  String get weightRequired => _t('وزن الزامی است', 'Weight is required');
  String get weightInvalid => _t('وزن معتبر نیست', 'Invalid weight');
  String get weightTonsLabel => _t('وزن (تن)', 'Weight (tons)');
  String get selectCargoAndGoods =>
      _t('نوع بارگیر و کالا را انتخاب کنید', 'Select trailer and goods type');
  String get description => _t('توضیحات', 'Description');
  String get descriptionRequired =>
      _t('توضیحات الزامی است', 'Description is required');
  String get originProvince => _t('استان مبدا', 'Origin province');
  String get destinationProvince => _t('استان مقصد', 'Destination province');
  String get price => _t('قیمت (ریال)', 'Price (IRR)');
  String get priceRequired => _t('قیمت الزامی است', 'Price is required');
  String get priceInvalid => _t('قیمت معتبر نیست', 'Invalid price');
  String get fillRouteFields => _t(
    'لطفاً مبدا، مقصد، نوع بارگیر و وزن را وارد کنید',
    'Please enter origin, destination, trailer type, and weight',
  );
  String get cargoRegistered =>
      _t('بار با موفقیت ثبت شد', 'Cargo registered successfully');
  String get estimatePrice => _t('تخمین قیمت حمل', 'Shipping price estimate');
  String get calculate => _t('محاسبه', 'Calculate');
  String get priceEstimateHint => _t(
    'بر اساس فاصله، نوع بار و شرایط مسیر',
    'Based on distance, cargo type, and route conditions',
  );
  String get defaultCoordinatorName => _t('متصدی', 'Coordinator');

  // Vehicle form
  String get selectTrailerType =>
      _t('نوع بارگیر را انتخاب کنید', 'Select a trailer type');
  String get vehicleFormHint => _t(
    'اطلاعات خودرو برای پیشنهاد بارهای متناسب استفاده می‌شود',
    'Vehicle info is used to suggest matching cargos',
  );
  String get plateIncomplete => _t(
    'لطفاً تمام بخش‌های پلاک را کامل کنید',
    'Please complete all plate sections',
  );
  String get modelRequired =>
      _t('مدل خودرو الزامی است', 'Vehicle model is required');
  String get capacityTons => _t('ظرفیت (تن)', 'Capacity (tons)');
  String get saveVehicleInfo => _t('ذخیره اطلاعات خودرو', 'Save vehicle info');
  String get cancel => _t('انصراف', 'Cancel');
  String get confirm => _t('تأیید', 'Confirm');

  // Plate widget
  String get plateNumber => _t('شماره پلاک', 'License plate number');
  String get selectPlateLetter => _t('انتخاب حرف پلاک', 'Select plate letter');
  String get cargoTitleHint =>
      _t('حمل سیمان به اصفهان', 'Cement delivery to Isfahan');
  String get originHint => _t('تهران، شهرک صنعتی', 'Tehran, industrial zone');
  String get destinationHint =>
      _t('اصفهان، شهرک صنعتی', 'Isfahan, industrial zone');
  String get vehicleModelHint => _t('ولوو FH460', 'Volvo FH460');

  // Cargo status
  String cargoStatus(String status) {
    switch (status) {
      case 'در انتظار راننده':
        return _t('در انتظار راننده', 'Awaiting driver');
      case 'تخصیص یافته':
        return _t('تخصیص یافته', 'Assigned');
      case 'در حال حمل':
        return _t('در حال حمل', 'In transit');
      case 'تحویل شده':
        return _t('تحویل شده', 'Delivered');
      case 'لغو شده':
        return _t('لغو شده', 'Cancelled');
      default:
        return status;
    }
  }

  String cargoType(String type) {
    final index = AppConstants.cargoTypes.indexOf(type);
    if (index == -1) return type;
    const enTypes = [
      'Flatbed',
      'Dump truck',
      'Refrigerated',
      'Tanker',
      'Container',
      'Bulk',
      'Crane truck',
    ];
    return isFa ? type : enTypes[index];
  }

  String goodsTypeLabel(String type) {
    final index = AppConstants.goodsTypes.indexOf(type);
    if (index == -1) return type;
    const enTypes = [
      'Building materials',
      'Food products',
      'Agricultural products',
      'Chemicals',
      'Home appliances',
      'Industrial parts',
      'Other',
    ];
    return isFa ? type : enTypes[index];
  }

  String formatPrice(int price) {
    final formatted = price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    if (isFa) {
      return '$formatted تومان';
    }
    return 'IRR $formatted';
  }

  String get currencyToman => _t('تومان', 'IRR');
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['fa', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
