import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/app_router.dart';
import '../theme/app_theme.dart';

class WheelsApp extends StatelessWidget {
  const WheelsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _WheelsAppView());
  }
}

class _WheelsAppView extends StatelessWidget {
  const _WheelsAppView();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Wheels',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
