import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/domain/entities/auth_entity.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/engagement/presentation/providers/engagement_providers.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';

/// Root widget that wires Riverpod, theme state, auth recovery, and router setup.
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

class _WheelsAppViewState extends ConsumerState<_WheelsAppView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() async {
      // Recover push notifications and persisted auth before the user navigates.
      await ref.read(engagementServiceProvider).initializeMessaging();
      await ref.read(authSessionControllerProvider).restoreSession();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    // Re-register device metadata when the app comes back from background.
    final user = ref.read(authUserProvider);
    if (user == null) {
      return;
    }

    Future.microtask(() async {
      await ref.read(engagementServiceProvider).registerDeviceToken(user.uid);
      await ref.read(engagementServiceProvider).recordConnection(user.uid);
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
        // Keep local Riverpod state aligned with Firebase auth stream updates.
        ref.read(authSessionControllerProvider).syncFromStream(authEntity);
        if (authEntity == null) {
          return;
        }
        Future.microtask(() async {
          await ref.read(engagementServiceProvider).registerDeviceToken(
            authEntity.uid,
          );
          await ref.read(engagementServiceProvider).recordConnection(
            authEntity.uid,
          );
        });
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
