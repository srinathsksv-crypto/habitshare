import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/core/di/service_locator.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<IAuthRepository>(
  (ref) => sl<IAuthRepository>(),
);

final authStateProvider = StreamProvider<UserEntity?>(
  (ref) => ref.watch(authRepositoryProvider).watchAuthState(),
);
