import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/core/di/service_locator.dart';
import 'package:habitshare/domain/entities/habit_entity.dart';
import 'package:habitshare/domain/repositories/habit_repository.dart';

final habitRepositoryProvider = Provider<IHabitRepository>(
  (ref) => sl<IHabitRepository>(),
);

final habitsProvider = FutureProvider.family<List<HabitEntity>, String>((
  ref,
  userId,
) async {
  final result = await ref.watch(habitRepositoryProvider).getHabits(userId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (habits) => habits,
  );
});

final habitsStreamProvider = StreamProvider.family<List<HabitEntity>, String>((
  ref,
  userId,
) {
  return ref.watch(habitRepositoryProvider).watchHabits(userId);
});
