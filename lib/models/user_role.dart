enum UserRole {
  driver('راننده'),
  coordinator('متصدی حمل‌ونقل');

  const UserRole(this.label);
  final String label;

  static UserRole fromApi(String? value) {
    switch (value?.toLowerCase()) {
      case 'coordinator':
      case 'متصدی':
      case 'متصدی حمل‌ونقل':
        return UserRole.coordinator;
      default:
        return UserRole.driver;
    }
  }

  String get apiValue => name;
}
