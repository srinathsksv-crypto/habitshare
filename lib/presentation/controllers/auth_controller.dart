import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/presentation/providers/auth_provider.dart';

final authControllerProvider = Provider<AuthController>(
  (ref) => AuthController(ref),
);

class AuthController {
  const AuthController(this._ref);

  final Ref _ref;

  Future<void> logout() async {
    await _ref.read(authRepositoryProvider).signOut();
  }
}
