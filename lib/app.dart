import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/config/router/app_router.dart';
import 'package:habitshare/config/theme/app_theme.dart';
import 'package:habitshare/presentation/providers/auth_provider.dart';

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
