import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/domain/entities/habit_entity.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/presentation/providers/habit_provider.dart';
import 'package:habitshare/presentation/providers/social_provider.dart';
import 'package:uuid/uuid.dart';

final habitControllerProvider = Provider<HabitController>(
  (ref) => HabitController(ref),
);

class HabitController {
  const HabitController(this._ref);

  final Ref _ref;
  static const _uuid = Uuid();

  Future<String?> createHabit({
    required UserEntity user,
    required String title,
    String? description,
    bool shareAsPost = true,
    String? postMessage,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now();
    final effectiveStart = startDate ?? now;
    if (endDate != null && endDate.isBefore(effectiveStart)) {
      return 'End date must be on or after start date';
    }

    final habit = HabitEntity(
      id: _uuid.v4(),
      userId: user.id,
      title: title.trim(),
      description: description?.trim(),
      createdAt: now,
      startDate: effectiveStart,
      endDate: endDate,
      status: HabitStatus.active,
    );

    final habitResult =
        await _ref.read(habitRepositoryProvider).createHabit(habit);

    return await habitResult.fold(
      (failure) async => failure.message,
      (created) async {
        if (shareAsPost) {
          final postResult =
              await _ref.read(socialRepositoryProvider).createPost(
                    userId: user.id,
                    habitId: created.id,
                    title: created.title,
                    description: created.description,
                    message: postMessage?.trim(),
                    authorName: user.name,
                    authorPhotoUrl: user.photoUrl,
                  );
          final postError = postResult.fold((f) => f.message, (_) => null);
          if (postError != null) {
            return postError;
          }
        }

        _invalidateHabits(user.id);
        return null;
      },
    );
  }

  Future<String?> quitHabit(HabitEntity habit) async {
    final updated = habit.copyWith(
      status: HabitStatus.quit,
      isArchived: true,
      updatedAt: DateTime.now(),
    );
    final result = await _ref.read(habitRepositoryProvider).updateHabit(updated);
    return result.fold(
      (failure) => failure.message,
      (_) {
        _invalidateHabits(habit.userId);
        return null;
      },
    );
  }

  Future<String?> deleteHabit(HabitEntity habit) async {
    final result = await _ref.read(habitRepositoryProvider).deleteHabit(
          userId: habit.userId,
          habitId: habit.id,
        );
    return result.fold(
      (failure) => failure.message,
      (_) {
        _invalidateHabits(habit.userId);
        return null;
      },
    );
  }

  void _invalidateHabits(String userId) {
    _ref.invalidate(habitsProvider(userId));
    _ref.invalidate(habitsStreamProvider(userId));
    _ref.invalidate(feedProvider(userId));
  }
}
