import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/wheels_app.dart';
import 'features/help/data/seed/help_articles_seed_runner.dart';
import 'firebase_options.dart';
import 'shared/storage/app_hive.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeAppHive();
  await const HelpArticlesSeedRunner().seedIfNeeded();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  final initialThemeUserId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
  final initialThemePreference = await ThemeController.loadSavedPreference(
    userId: initialThemeUserId,
  );

  runApp(
    WheelsApp(
      initialThemePreference: initialThemePreference,
      initialThemeUserId: initialThemeUserId,
    ),
  );
}
