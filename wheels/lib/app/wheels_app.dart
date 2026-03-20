import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';

class WheelsApp extends StatelessWidget {
  const WheelsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _WheelsAppView());
  }
}

class _WheelsAppView extends ConsumerWidget {
  const _WheelsAppView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeController = ref.watch(themeControllerProvider);

    return MaterialApp.router(
      title: 'Wheels',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeController.themeMode,
      themeAnimationCurve: Curves.easeInOut,
      themeAnimationDuration: const Duration(milliseconds: 280),
      routerConfig: AppRouter.router,
    );
  }
}
