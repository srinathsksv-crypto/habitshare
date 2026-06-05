import '../entities/habit_entity.dart';

class HabitStreakService {
  /// Calculates the current weekly window index for a habit
  /// Window index 0 starts from the habit creation date
  static int getCurrentWindowIndex(DateTime createdAt, DateTime now) {
    final creationDate =
        DateTime(createdAt.year, createdAt.month, createdAt.day);
    final currentDate = DateTime(now.year, now.month, now.day);

    final daysSinceCreation = currentDate.difference(creationDate).inDays;
    return daysSinceCreation ~/ 7;
  }

  /// Calculates the date range for a given window index
  static (DateTime start, DateTime end) getWindowDateRange(
    DateTime createdAt,
    int windowIndex,
  ) {
    final creationDate =
        DateTime(createdAt.year, createdAt.month, createdAt.day);
    final windowStart = creationDate.add(Duration(days: windowIndex * 7));
    final windowEnd = windowStart.add(const Duration(days: 6));
    return (windowStart, windowEnd);
  }

  /// Checks if a habit can be completed today based on its frequency and completion history
  static bool canCompleteHabit(HabitEntity habit, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);

    if (habit.frequency == HabitFrequency.daily) {
      // Daily habits can only be completed once per day
      if (habit.lastCompletedAt == null) return true;
      final lastCompletedDay = DateTime(
        habit.lastCompletedAt!.year,
        habit.lastCompletedAt!.month,
        habit.lastCompletedAt!.day,
      );
      return lastCompletedDay.isBefore(today);
    } else if (habit.frequency == HabitFrequency.weekly) {
      // Weekly habits can only be completed once per 7-day window
      if (habit.lastCompletedAt == null) return true;
      final currentWindowIndex = getCurrentWindowIndex(habit.createdAt, now);
      return currentWindowIndex > habit.lastCompletedWindowIndex;
    }

    return true;
  }

  /// Calculates the new streak count when a habit is completed
  static int calculateNewStreak(HabitEntity habit, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);

    if (habit.frequency == HabitFrequency.daily) {
      if (habit.lastCompletedAt == null) {
        // First completion ever
        return 1;
      }

      final lastCompletedDay = DateTime(
        habit.lastCompletedAt!.year,
        habit.lastCompletedAt!.month,
        habit.lastCompletedAt!.day,
      );
      final daysSinceLastCompletion = today.difference(lastCompletedDay).inDays;

      if (daysSinceLastCompletion == 1) {
        // Consecutive day - increment streak
        return habit.streakCount + 1;
      } else if (daysSinceLastCompletion > 1) {
        // Day skipped - reset streak
        return 1;
      } else {
        // Same day (shouldn't happen due to canCompleteHabit check)
        return habit.streakCount;
      }
    } else if (habit.frequency == HabitFrequency.weekly) {
      if (habit.lastCompletedAt == null) {
        // First completion ever
        return 1;
      }

      final currentWindowIndex = getCurrentWindowIndex(habit.createdAt, now);

      if (currentWindowIndex == habit.lastCompletedWindowIndex + 1) {
        // Consecutive window - increment streak
        return habit.streakCount + 1;
      } else if (currentWindowIndex > habit.lastCompletedWindowIndex + 1) {
        // Window skipped - reset streak
        return 1;
      } else {
        // Same window (shouldn't happen due to canCompleteHabit check)
        return habit.streakCount;
      }
    }

    return habit.streakCount;
  }

  /// Gets the completion status text for display
  static String getCompletionStatus(HabitEntity habit, DateTime now) {
    if (!canCompleteHabit(habit, now)) {
      if (habit.frequency == HabitFrequency.daily) {
        return 'Completed Today';
      } else {
        return 'Completed This Week';
      }
    }
    return 'Mark Complete';
  }
}
