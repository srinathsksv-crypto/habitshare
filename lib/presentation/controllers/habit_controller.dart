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
    HabitFrequency frequency = HabitFrequency.daily,
    List<int>? selectedWeekdays,
    List<int>? selectedMonthDates,
    int? targetCount,
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
      frequency: frequency,
      selectedWeekdays: selectedWeekdays,
      selectedMonthDates: selectedMonthDates,
      targetCount: targetCount,
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
    final result =
        await _ref.read(habitRepositoryProvider).updateHabit(updated);
    return result.fold(
      (failure) => failure.message,
      (_) {
        _invalidateHabits(habit.userId);
        return null;
      },
    );
  }

  Future<String?> updateHabit({
    required HabitEntity habit,
    required String title,
    String? description,
    HabitFrequency? frequency,
    List<int>? selectedWeekdays,
    List<int>? selectedMonthDates,
    int? targetCount,
    DateTime? startDate,
    DateTime? endDate,
    String? colorHex,
  }) async {
    final effectiveStart = startDate ?? habit.startDate ?? habit.createdAt;
    if (endDate != null && endDate.isBefore(effectiveStart)) {
      return 'End date must be on or after start date';
    }

    // Construct directly to avoid copyWith null coalescing issue
    final updated = HabitEntity(
      id: habit.id,
      userId: habit.userId,
      title: title.trim(),
      description: description?.trim(),
      categoryId: habit.categoryId,
      colorHex: colorHex ?? habit.colorHex,
      frequency: frequency ?? habit.frequency,
      targetPerPeriod: habit.targetPerPeriod,
      selectedWeekdays: selectedWeekdays,
      selectedMonthDates: selectedMonthDates,
      targetCount: targetCount,
      isArchived: habit.isArchived,
      status: habit.status,
      startDate: effectiveStart,
      endDate: endDate,
      streakCount: habit.streakCount,
      lastCompletedAt: habit.lastCompletedAt,
      lastCompletedWindowIndex: habit.lastCompletedWindowIndex,
      currentPeriodCompletionCount: habit.currentPeriodCompletionCount,
      createdAt: habit.createdAt,
      updatedAt: DateTime.now(),
    );

    final result =
        await _ref.read(habitRepositoryProvider).updateHabit(updated);
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

  Future<String?> completeHabit({
    required String userId,
    required String habitId,
  }) async {
    final result = await _ref.read(habitRepositoryProvider).completeHabit(
          userId: userId,
          habitId: habitId,
        );
    return result.fold(
      (failure) => failure.message,
      (_) {
        _invalidateHabits(userId);
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
