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

  /// Calculates the current month index for a habit
  static int _getCurrentMonthIndex(DateTime createdAt, DateTime now) {
    final creationDate =
        DateTime(createdAt.year, createdAt.month, createdAt.day);
    final currentDate = DateTime(now.year, now.month, now.day);

    final yearDiff = currentDate.year - creationDate.year;
    final monthDiff = currentDate.month - creationDate.month;
    return yearDiff * 12 + monthDiff;
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
    } else if (habit.frequency == HabitFrequency.weekdays) {
      // Weekday habits can only be completed on selected weekdays
      if (habit.selectedWeekdays == null || habit.selectedWeekdays!.isEmpty) {
        return false;
      }
      final weekday = now.weekday; // 1 = Monday, 7 = Sunday
      if (!habit.selectedWeekdays!.contains(weekday)) {
        return false;
      }
      // Can only be completed once per scheduled day
      if (habit.lastCompletedAt == null) return true;
      final lastCompletedDay = DateTime(
        habit.lastCompletedAt!.year,
        habit.lastCompletedAt!.month,
        habit.lastCompletedAt!.day,
      );
      return lastCompletedDay.isBefore(today);
    } else if (habit.frequency == HabitFrequency.monthlyDates) {
      // Monthly date habits can only be completed on selected dates
      if (habit.selectedMonthDates == null ||
          habit.selectedMonthDates!.isEmpty) {
        return false;
      }
      final dayOfMonth = now.day;
      if (!habit.selectedMonthDates!.contains(dayOfMonth)) {
        return false;
      }
      // Can only be completed once per scheduled date
      if (habit.lastCompletedAt == null) return true;
      final lastCompletedDay = DateTime(
        habit.lastCompletedAt!.year,
        habit.lastCompletedAt!.month,
        habit.lastCompletedAt!.day,
      );
      // Check if last completion was on a different day or different month
      return lastCompletedDay.year < today.year ||
          lastCompletedDay.month < today.month ||
          lastCompletedDay.day < today.day;
    } else if (habit.frequency == HabitFrequency.timesPerWeek) {
      // Times per week: check if target reached for current week
      // Maximum 1 completion per day
      if (habit.lastCompletedAt == null) return true;
      final lastCompletedDay = DateTime(
        habit.lastCompletedAt!.year,
        habit.lastCompletedAt!.month,
        habit.lastCompletedAt!.day,
      );
      if (!lastCompletedDay.isBefore(today)) {
        // Already completed today
        return false;
      }
      final currentWindowIndex = getCurrentWindowIndex(habit.createdAt, now);
      // Reset count if period changed
      if (currentWindowIndex != habit.lastCompletedWindowIndex) {
        return true;
      }
      // Check if target reached
      final targetCount = habit.targetCount ?? 1;
      return habit.currentPeriodCompletionCount < targetCount;
    } else if (habit.frequency == HabitFrequency.timesPerMonth) {
      // Times per month: check if target reached for current month
      // Maximum 1 completion per day
      if (habit.lastCompletedAt == null) return true;
      final lastCompletedDay = DateTime(
        habit.lastCompletedAt!.year,
        habit.lastCompletedAt!.month,
        habit.lastCompletedAt!.day,
      );
      if (!lastCompletedDay.isBefore(today)) {
        // Already completed today
        return false;
      }
      final currentMonthIndex = _getCurrentMonthIndex(habit.createdAt, now);
      // Reset count if period changed
      if (currentMonthIndex != habit.lastCompletedWindowIndex) {
        return true;
      }
      // Check if target reached
      final targetCount = habit.targetCount ?? 1;
      return habit.currentPeriodCompletionCount < targetCount;
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
    } else if (habit.frequency == HabitFrequency.weekdays) {
      // Weekday habits: streak based on consecutive scheduled days completed
      // For simplicity, treat similar to daily for now
      if (habit.lastCompletedAt == null) {
        return 1;
      }

      final lastCompletedDay = DateTime(
        habit.lastCompletedAt!.year,
        habit.lastCompletedAt!.month,
        habit.lastCompletedAt!.day,
      );
      final daysSinceLastCompletion = today.difference(lastCompletedDay).inDays;

      // If it's the next scheduled day, increment streak
      // Otherwise reset
      if (daysSinceLastCompletion <= 7) {
        return habit.streakCount + 1;
      } else {
        return 1;
      }
    } else if (habit.frequency == HabitFrequency.monthlyDates) {
      // Monthly date habits: streak based on consecutive months where all dates completed
      // For simplicity, increment on completion
      if (habit.lastCompletedAt == null) {
        return 1;
      }
      return habit.streakCount + 1;
    } else if (habit.frequency == HabitFrequency.timesPerWeek) {
      // Times per week: streak based on consecutive weeks where target met
      if (habit.lastCompletedAt == null) {
        return 1;
      }

      final currentWindowIndex = getCurrentWindowIndex(habit.createdAt, now);

      if (currentWindowIndex == habit.lastCompletedWindowIndex + 1) {
        return habit.streakCount + 1;
      } else if (currentWindowIndex > habit.lastCompletedWindowIndex + 1) {
        return 1;
      } else {
        return habit.streakCount;
      }
    } else if (habit.frequency == HabitFrequency.timesPerMonth) {
      // Times per month: streak based on consecutive months where target met
      if (habit.lastCompletedAt == null) {
        return 1;
      }

      final currentMonthIndex = _getCurrentMonthIndex(habit.createdAt, now);

      if (currentMonthIndex == habit.lastCompletedWindowIndex + 1) {
        return habit.streakCount + 1;
      } else if (currentMonthIndex > habit.lastCompletedWindowIndex + 1) {
        return 1;
      } else {
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
      } else if (habit.frequency == HabitFrequency.weekly) {
        return 'Completed This Week';
      } else if (habit.frequency == HabitFrequency.weekdays) {
        return 'Completed Today';
      } else if (habit.frequency == HabitFrequency.monthlyDates) {
        return 'Completed This Date';
      } else if (habit.frequency == HabitFrequency.timesPerWeek) {
        // Check if target reached first
        final targetCount = habit.targetCount ?? 1;
        if (habit.currentPeriodCompletionCount >= targetCount) {
          return 'Completed This Week';
        }
        // Then check if completed today
        if (habit.lastCompletedAt != null) {
          final lastCompletedDay = DateTime(
            habit.lastCompletedAt!.year,
            habit.lastCompletedAt!.month,
            habit.lastCompletedAt!.day,
          );
          final today = DateTime(now.year, now.month, now.day);
          if (!lastCompletedDay.isBefore(today)) {
            return 'Completed Today';
          }
        }
        return 'Completed This Week';
      } else if (habit.frequency == HabitFrequency.timesPerMonth) {
        // Check if target reached first
        final targetCount = habit.targetCount ?? 1;
        if (habit.currentPeriodCompletionCount >= targetCount) {
          return 'Completed This Month';
        }
        // Then check if completed today
        if (habit.lastCompletedAt != null) {
          final lastCompletedDay = DateTime(
            habit.lastCompletedAt!.year,
            habit.lastCompletedAt!.month,
            habit.lastCompletedAt!.day,
          );
          final today = DateTime(now.year, now.month, now.day);
          if (!lastCompletedDay.isBefore(today)) {
            return 'Completed Today';
          }
        }
        return 'Completed This Month';
      }
    }
    return 'Mark Complete';
  }

  /// Gets the eligibility message for when a habit cannot be completed
  static String getCompletionEligibilityMessage(
      HabitEntity habit, DateTime now) {
    if (canCompleteHabit(habit, now)) {
      return '';
    }

    final weekday = now.weekday; // 1 = Monday, 7 = Sunday
    final dayOfMonth = now.day;
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    if (habit.frequency == HabitFrequency.daily) {
      // Check if completed today
      if (habit.lastCompletedAt != null) {
        final lastCompletedDay = DateTime(
          habit.lastCompletedAt!.year,
          habit.lastCompletedAt!.month,
          habit.lastCompletedAt!.day,
        );
        final today = DateTime(now.year, now.month, now.day);
        if (!lastCompletedDay.isBefore(today)) {
          return 'Completed Today';
        }
      }
    } else if (habit.frequency == HabitFrequency.weekdays) {
      if (habit.selectedWeekdays == null || habit.selectedWeekdays!.isEmpty) {
        return 'No weekdays selected';
      }
      if (!habit.selectedWeekdays!.contains(weekday)) {
        final futureWeekdays =
            habit.selectedWeekdays!.where((d) => d >= weekday).toList();
        if (futureWeekdays.isNotEmpty) {
          final nextWeekday = futureWeekdays.reduce((a, b) => a < b ? a : b);
          return 'Available on ${dayNames[nextWeekday - 1]}';
        } else {
          final firstWeekday =
              habit.selectedWeekdays!.reduce((a, b) => a < b ? a : b);
          return 'Available on ${dayNames[firstWeekday - 1]}';
        }
      }
      // Check if completed today (today is a scheduled weekday)
      if (habit.lastCompletedAt != null) {
        final lastCompletedDay = DateTime(
          habit.lastCompletedAt!.year,
          habit.lastCompletedAt!.month,
          habit.lastCompletedAt!.day,
        );
        final today = DateTime(now.year, now.month, now.day);
        if (!lastCompletedDay.isBefore(today)) {
          return 'Completed Today';
        }
      }
    } else if (habit.frequency == HabitFrequency.monthlyDates) {
      if (habit.selectedMonthDates == null ||
          habit.selectedMonthDates!.isEmpty) {
        return 'No dates selected';
      }
      if (!habit.selectedMonthDates!.contains(dayOfMonth)) {
        final futureDates =
            habit.selectedMonthDates!.where((d) => d >= dayOfMonth).toList();
        if (futureDates.isNotEmpty) {
          final nextDate = futureDates.reduce((a, b) => a < b ? a : b);
          return 'Available on the ${nextDate}${_getOrdinalSuffix(nextDate)}';
        } else {
          final firstDate =
              habit.selectedMonthDates!.reduce((a, b) => a < b ? a : b);
          return 'Available on the ${firstDate}${_getOrdinalSuffix(firstDate)}';
        }
      }
      // Check if completed today (today is a scheduled date)
      if (habit.lastCompletedAt != null) {
        final lastCompletedDay = DateTime(
          habit.lastCompletedAt!.year,
          habit.lastCompletedAt!.month,
          habit.lastCompletedAt!.day,
        );
        final today = DateTime(now.year, now.month, now.day);
        if (!lastCompletedDay.isBefore(today)) {
          return 'Completed Today';
        }
      }
    } else if (habit.frequency == HabitFrequency.timesPerWeek) {
      // Check if target reached
      final targetCount = habit.targetCount ?? 1;
      if (habit.currentPeriodCompletionCount >= targetCount) {
        return 'Weekly Target Reached';
      }
      // Check if completed today
      if (habit.lastCompletedAt != null) {
        final lastCompletedDay = DateTime(
          habit.lastCompletedAt!.year,
          habit.lastCompletedAt!.month,
          habit.lastCompletedAt!.day,
        );
        final today = DateTime(now.year, now.month, now.day);
        if (!lastCompletedDay.isBefore(today)) {
          return 'Completed Today';
        }
      }
    } else if (habit.frequency == HabitFrequency.timesPerMonth) {
      // Check if target reached
      final targetCount = habit.targetCount ?? 1;
      if (habit.currentPeriodCompletionCount >= targetCount) {
        return 'Monthly Target Reached';
      }
      // Check if completed today
      if (habit.lastCompletedAt != null) {
        final lastCompletedDay = DateTime(
          habit.lastCompletedAt!.year,
          habit.lastCompletedAt!.month,
          habit.lastCompletedAt!.day,
        );
        final today = DateTime(now.year, now.month, now.day);
        if (!lastCompletedDay.isBefore(today)) {
          return 'Completed Today';
        }
      }
    }

    return 'Not available';
  }

  static String _getOrdinalSuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}
