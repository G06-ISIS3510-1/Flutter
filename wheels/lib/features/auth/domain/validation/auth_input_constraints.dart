const int kMaxPersonalNameLength = 40;

String? validatePersonalName(
  String? value, {
  String fieldLabel = 'This field',
}) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return '$fieldLabel is required';
  }
  if (trimmed.length > kMaxPersonalNameLength) {
    return '$fieldLabel must be $kMaxPersonalNameLength characters or fewer';
  }
  return null;
}
