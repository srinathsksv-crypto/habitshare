import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/presentation/controllers/fcm_controller.dart';
import 'package:habitshare/presentation/providers/auth_provider.dart';

final authControllerProvider = Provider<AuthController>(
  (ref) => AuthController(ref),
);

class AuthController {
  const AuthController(this._ref);

  final Ref _ref;

  Future<void> logout() async {
    // Get current user before signing out
    final auth = _ref.read(authStateProvider);
    final user = auth.value;

    // Delete FCM token before signing out
    if (user != null) {
      final fcmController = _ref.read(fcmControllerProvider);
      await fcmController.deleteFCMToken(user.id);
      await fcmController.unsubscribeFromUserNotifications(user.id);
    }

    await _ref.read(authRepositoryProvider).signOut();
  }
}
