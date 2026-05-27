import 'package:go_router/go_router.dart';
import 'package:habitshare/presentation/pages/auth/login_page.dart';
import 'package:habitshare/presentation/pages/home/main_shell_page.dart';
import 'package:habitshare/presentation/pages/splash/splash_page.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
}

GoRouter createAppRouter({
  required bool isAuthenticated,
  required bool isLoading,
}) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const MainShellPage(),
      ),
    ],
    redirect: (context, state) {
      if (isLoading) {
        return null;
      }

      final path = state.fullPath;
      final onSplash = path == AppRoutes.splash;
      final onLogin = path == AppRoutes.login;

      if (isAuthenticated) {
        if (onSplash || onLogin) {
          return AppRoutes.home;
        }
      } else {
        if (onSplash || !onLogin) {
          return AppRoutes.login;
        }
      }
      return null;
    },
  );
}
