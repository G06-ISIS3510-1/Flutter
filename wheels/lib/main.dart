import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/wheels_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  runApp(const WheelsApp());
}
