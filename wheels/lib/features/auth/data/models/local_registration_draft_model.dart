class LocalRegistrationDraftModel {
  const LocalRegistrationDraftModel({
    required this.version,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.role,
    required this.savedAt,
  });

  static const int currentVersion = 1;

  final int version;
  final String firstName;
  final String lastName;
  final String username;
  final String role;
  final DateTime savedAt;

  factory LocalRegistrationDraftModel.create({
    required String firstName,
    required String lastName,
    required String username,
    required String role,
  }) {
    return LocalRegistrationDraftModel(
      version: currentVersion,
      firstName: firstName,
      lastName: lastName,
      username: username,
      role: role,
      savedAt: DateTime.now().toUtc(),
    );
  }

  factory LocalRegistrationDraftModel.fromJson(Map<String, dynamic> json) {
    final version = _readRequiredInt(json['version'], 'version');
    if (version != currentVersion) {
      throw FormatException('Unsupported registration draft version: $version');
    }

    return LocalRegistrationDraftModel(
      version: version,
      firstName: _readRequiredString(json['firstName'], 'firstName'),
      lastName: _readRequiredString(json['lastName'], 'lastName'),
      username: _readRequiredString(json['username'], 'username'),
      role: _readRequiredString(json['role'], 'role'),
      savedAt: _parseRequiredDateTime(json['savedAt'], 'savedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'role': role,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  bool get isEmpty {
    return firstName.trim().isEmpty &&
        lastName.trim().isEmpty &&
        username.trim().isEmpty;
  }
}

String _readRequiredString(Object? rawValue, String fieldName) {
  if (rawValue is String) {
    return rawValue;
  }
  throw FormatException('Invalid $fieldName value.');
}

int _readRequiredInt(Object? rawValue, String fieldName) {
  if (rawValue is num) {
    return rawValue.toInt();
  }
  throw FormatException('Invalid $fieldName value.');
}

DateTime _parseRequiredDateTime(Object? rawValue, String fieldName) {
  if (rawValue is! String) {
    throw FormatException('Invalid $fieldName value.');
  }

  final parsed = DateTime.tryParse(rawValue);
  if (parsed == null) {
    throw FormatException('Invalid $fieldName value.');
  }
  return parsed;
}
