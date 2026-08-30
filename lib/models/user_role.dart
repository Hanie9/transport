enum UserRole {
  driver('راننده'),
  coordinator('متصدی حمل‌ونقل');

  const UserRole(this.label);
  final String label;

  static UserRole fromApi(String? value) {
    switch (value?.toLowerCase()) {
      case 'coordinator':
      case 'operator':
      case 'متصدی':
      case 'متصدی حمل‌ونقل':
        return UserRole.coordinator;
      default:
        return UserRole.driver;
    }
  }

  static UserRole fromApiUser(Map<String, dynamic> json) {
    if (json['is_operator'] == true) return UserRole.coordinator;
    if (json['is_driver'] == true) return UserRole.driver;
    return fromApi(json['role']?.toString());
  }

  static bool matchesApiUser(Map<String, dynamic> json, UserRole role) {
    return switch (role) {
      UserRole.driver => json['is_driver'] == true,
      UserRole.coordinator => json['is_operator'] == true,
    };
  }

  String get apiValue => name;
}
