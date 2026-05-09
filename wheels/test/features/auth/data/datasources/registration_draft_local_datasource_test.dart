import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wheels/features/auth/data/datasources/registration_draft_local_datasource.dart';
import 'package:wheels/features/auth/data/models/local_registration_draft_model.dart';
import 'package:wheels/shared/storage/app_hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;
  late Box<String> draftsBox;
  late RegistrationDraftLocalDataSource dataSource;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'registration-draft-test',
    );
    Hive.init(hiveDirectory.path);
    draftsBox = await Hive.openBox<String>(AppHiveBoxes.registrationDrafts);
  });

  setUp(() {
    dataSource = const RegistrationDraftLocalDataSource();
  });

  tearDown(() async {
    await draftsBox.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  group('RegistrationDraftLocalDataSource', () {
    test('returns null when there is no draft', () async {
      final restored = await dataSource.loadDraft();

      expect(restored, isNull);
    });

    test('saves and restores a registration draft', () async {
      final draft = LocalRegistrationDraftModel.create(
        firstName: 'Maria',
        lastName: 'Gonzalez',
        username: 'm.gonzalez',
        role: 'driver',
      );

      await dataSource.saveDraft(draft);
      final restored = await dataSource.loadDraft();

      expect(restored, isNotNull);
      expect(restored!.firstName, 'Maria');
      expect(restored.role, 'driver');
    });

    test('clears invalid stored drafts and returns null', () async {
      await draftsBox.put('latest_registration_draft', '{"bad":');

      final restored = await dataSource.loadDraft();

      expect(restored, isNull);
      expect(draftsBox.get('latest_registration_draft'), isNull);
    });

    test('empty draft clears storage instead of saving', () async {
      final draft = LocalRegistrationDraftModel.create(
        firstName: '',
        lastName: '',
        username: '',
        role: 'passenger',
      );

      await dataSource.saveDraft(draft);

      expect(await dataSource.loadDraft(), isNull);
    });

    test('clearDraft removes a saved draft', () async {
      final draft = LocalRegistrationDraftModel.create(
        firstName: 'Maria',
        lastName: 'Gonzalez',
        username: 'm.gonzalez',
        role: 'passenger',
      );

      await dataSource.saveDraft(draft);
      await dataSource.clearDraft();

      expect(await dataSource.loadDraft(), isNull);
    });
  });
}
