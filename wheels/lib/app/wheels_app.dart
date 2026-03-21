import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/domain/entities/auth_entity.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
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

class _WheelsAppView extends ConsumerStatefulWidget {
  const _WheelsAppView();

  @override
  ConsumerState<_WheelsAppView> createState() => _WheelsAppViewState();
}

class _WheelsAppViewState extends ConsumerState<_WheelsAppView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(authSessionControllerProvider).restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ref.watch(themeControllerProvider);

    ref.listen<AsyncValue<AuthEntity?>>(authSessionStreamProvider, (
      previous,
      next,
    ) {
      next.whenData((authEntity) {
        ref.read(authSessionControllerProvider).syncFromStream(authEntity);
      });
    });

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
