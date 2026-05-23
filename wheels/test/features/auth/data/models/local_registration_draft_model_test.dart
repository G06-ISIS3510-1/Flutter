import 'package:flutter_test/flutter_test.dart';
import 'package:wheels/features/auth/data/models/local_registration_draft_model.dart';

void main() {
  group('LocalRegistrationDraftModel', () {
    test('round-trips through json', () {
      final draft = LocalRegistrationDraftModel.create(
        firstName: 'Maria',
        lastName: 'Gonzalez',
        username: 'm.gonzalez',
        role: 'passenger',
      );

      final restored = LocalRegistrationDraftModel.fromJson(draft.toJson());

      expect(restored.version, LocalRegistrationDraftModel.currentVersion);
      expect(restored.firstName, 'Maria');
      expect(restored.lastName, 'Gonzalez');
      expect(restored.username, 'm.gonzalez');
      expect(restored.role, 'passenger');
    });

    test('isEmpty returns true when user fields are blank', () {
      final draft = LocalRegistrationDraftModel.create(
        firstName: '',
        lastName: ' ',
        username: '',
        role: 'passenger',
      );

      expect(draft.isEmpty, isTrue);
    });

    test('throws when cache version is unsupported', () {
      final json = LocalRegistrationDraftModel.create(
        firstName: 'Maria',
        lastName: 'Gonzalez',
        username: 'm.gonzalez',
        role: 'passenger',
      ).toJson()..['version'] = 99;

      expect(
        () => LocalRegistrationDraftModel.fromJson(json),
        throwsFormatException,
      );
    });
  });
}
