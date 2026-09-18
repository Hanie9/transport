class IranianPlateLetters {
  static const List<String> letters = [
    'الف',
    'ب',
    'پ',
    'ت',
    'ث',
    'ج',
    'چ',
    'ح',
    'خ',
    'د',
    'ذ',
    'ر',
    'ز',
    'ژ',
    'س',
    'ش',
    'ص',
    'ض',
    'ط',
    'ظ',
    'ع',
    'غ',
    'ف',
    'ق',
    'ک',
    'گ',
    'ل',
    'م',
    'ن',
    'و',
    'ه',
    'ی',
  ];
}

class IranianPlateData {
  const IranianPlateData({
    this.twoDigits = '',
    this.letter = '',
    this.threeDigits = '',
    this.provinceCode = '',
  });

  final String twoDigits;
  final String letter;
  final String threeDigits;
  final String provinceCode;

  bool get isComplete =>
      twoDigits.length == 2 &&
      letter.isNotEmpty &&
      threeDigits.length == 3 &&
      provinceCode.length == 2;

  bool get isEmpty =>
      twoDigits.isEmpty &&
      letter.isEmpty &&
      threeDigits.isEmpty &&
      provinceCode.isEmpty;

  String toStorageString() {
    if (isEmpty) return '';
    return '${_toPersian(twoDigits)} $letter ${_toPersian(threeDigits)} ایران ${_toPersian(provinceCode)}';
  }

  String toApiString() =>
      '${_toEnglish(twoDigits)}$letter${_toEnglish(threeDigits)}${_toEnglish(provinceCode)}';

  IranianPlateData copyWith({
    String? twoDigits,
    String? letter,
    String? threeDigits,
    String? provinceCode,
  }) {
    return IranianPlateData(
      twoDigits: twoDigits ?? this.twoDigits,
      letter: letter ?? this.letter,
      threeDigits: threeDigits ?? this.threeDigits,
      provinceCode: provinceCode ?? this.provinceCode,
    );
  }

  static IranianPlateData? parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    final normalized = _toEnglish(raw.trim());
    final match = RegExp(
      r'^(\d{2})\s*([^\d\s]+)\s*(\d{3})\s*(?:ایران\s*)?(\d{2})$',
    ).firstMatch(normalized);

    if (match == null) return null;

    return IranianPlateData(
      twoDigits: match.group(1)!,
      letter: _extractLetter(raw, match.group(2)!),
      threeDigits: match.group(3)!,
      provinceCode: match.group(4)!,
    );
  }

  static String _extractLetter(String original, String normalizedLetter) {
    final letterPattern = RegExp(r'[\u0600-\u06FF]+');
    final fromOriginal = letterPattern.firstMatch(
      original.replaceAll(RegExp(r'[\d۰-۹0-9\s]'), ' '),
    );
    if (fromOriginal != null && fromOriginal.group(0)!.trim().isNotEmpty) {
      final letter = fromOriginal.group(0)!.trim();
      if (IranianPlateLetters.letters.contains(letter)) return letter;
    }
    for (final l in IranianPlateLetters.letters) {
      if (normalizedLetter.contains(_toEnglish(l))) return l;
    }
    return normalizedLetter.trim();
  }

  static String _toEnglish(String input) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    var result = input;
    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(persian[i], '$i').replaceAll(arabic[i], '$i');
    }
    return result;
  }

  static String _toPersian(String input) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    return input.replaceAllMapped(
      RegExp(r'\d'),
      (m) => persian[int.parse(m.group(0)!)],
    );
  }
}
