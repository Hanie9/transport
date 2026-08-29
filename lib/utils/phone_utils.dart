/// Normalizes Iranian mobile numbers for API calls (09xxxxxxxxx).
String normalizeIranPhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('98') && digits.length >= 12) {
    digits = '0${digits.substring(2)}';
  }
  if (digits.length == 10 && digits.startsWith('9')) {
    digits = '0$digits';
  }
  return digits;
}
