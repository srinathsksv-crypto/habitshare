import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/config/router/app_router.dart';
import 'package:habitshare/config/theme/app_theme.dart';
import 'package:habitshare/presentation/controllers/fcm_controller.dart';
import 'package:habitshare/presentation/providers/auth_provider.dart';

final _fcmInitProvider = Provider<void>((ref) {
  ref.listen(
    authStateProvider,
    (previous, next) {
      next.whenData((user) {
        if (user != null) {
          final fcmController = ref.read(fcmControllerProvider);
          fcmController.initializeFCM(user.id);
          fcmController.subscribeToUserNotifications(user.id);
        }
      });
    },
    fireImmediately: true,
  );
});

class HabitShareApp extends ConsumerWidget {
  const HabitShareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final isLoading = auth.isLoading && !auth.hasValue;
    final isAuthenticated = auth.maybeWhen(
      data: (user) => user != null,
      orElse: () => false,
    );

    // Initialize FCM when user authenticates (supports fireImmediately)
    ref.watch(_fcmInitProvider);

    final router = createAppRouter(
      isAuthenticated: isAuthenticated,
      isLoading: isLoading,
    );

    return AdaptiveTheme(
      light: AppTheme.light(),
      dark: AppTheme.dark(),
      initial: AdaptiveThemeMode.system,
      builder: (theme, darkTheme) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: theme,
          darkTheme: darkTheme,
          routerConfig: router,
        );
      },
    );
  }
}
