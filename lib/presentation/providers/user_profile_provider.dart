import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/presentation/providers/social_provider.dart';

final userProfileProvider =
    FutureProvider.family<UserEntity?, String>((ref, userId) async {
  final repo = ref.read(socialRepositoryProvider);
  final result = await repo.getUserProfile(userId);
  return result.fold((_) => null, (user) => user);
});

