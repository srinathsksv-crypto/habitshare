import '../entities/habit_entity.dart';

class HabitSchedulerService {
  /// Determines whether a habit should appear in today's habit list
  static bool shouldShowHabitToday(HabitEntity habit, DateTime now) {
    final weekday = now.weekday; // 1 = Monday, 7 = Sunday
    final dayOfMonth = now.day;

    switch (habit.frequency) {
      case HabitFrequency.daily:
        // Show every day
        return true;

      case HabitFrequency.weekly:
        // Show according to existing weekly rules
        // For now, treat weekly as daily (can be refined later)
        return true;

      case HabitFrequency.weekdays:
        // Show only on selected weekdays
        if (habit.selectedWeekdays == null || habit.selectedWeekdays!.isEmpty) {
          return false;
        }
        return habit.selectedWeekdays!.contains(weekday);

      case HabitFrequency.monthlyDates:
        // Show only on selected month dates
        if (habit.selectedMonthDates == null ||
            habit.selectedMonthDates!.isEmpty) {
          return false;
        }
        return habit.selectedMonthDates!.contains(dayOfMonth);

      case HabitFrequency.timesPerWeek:
        // Show until weekly target is reached
        // This requires checking completion count in current week
        // For now, always show (completion logic will handle limits)
        return true;

      case HabitFrequency.timesPerMonth:
        // Show until monthly target is reached
        // This requires checking completion count in current month
        // For now, always show (completion logic will handle limits)
        return true;
    }
  }

  /// Calculates the current week index for a habit (for timesPerWeek)
  static int getCurrentWeekIndex(DateTime createdAt, DateTime now) {
    final creationDate =
        DateTime(createdAt.year, createdAt.month, createdAt.day);
    final currentDate = DateTime(now.year, now.month, now.day);
    final daysSinceCreation = currentDate.difference(creationDate).inDays;
    return daysSinceCreation ~/ 7;
  }

  /// Calculates the current month index for a habit (for timesPerMonth)
  static int getCurrentMonthIndex(DateTime createdAt, DateTime now) {
    final creationDate =
        DateTime(createdAt.year, createdAt.month, createdAt.day);
    final currentDate = DateTime(now.year, now.month, now.day);

    final yearDiff = currentDate.year - creationDate.year;
    final monthDiff = currentDate.month - creationDate.month;
    return yearDiff * 12 + monthDiff;
  }

  /// Gets the display text for the frequency type
  static String getFrequencyDisplayText(HabitEntity habit) {
    switch (habit.frequency) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.weekly:
        return 'Weekly';
      case HabitFrequency.weekdays:
        if (habit.selectedWeekdays == null || habit.selectedWeekdays!.isEmpty) {
          return 'Specific Weekdays';
        }
        final weekdays = habit.selectedWeekdays!;
        final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final selectedDays = weekdays.map((d) => dayNames[d - 1]).toList()
          ..sort((a, b) => weekdays
              .indexOf(dayNames.indexOf(a) + 1)
              .compareTo(weekdays.indexOf(dayNames.indexOf(b) + 1)));
        return selectedDays.join(', ');
      case HabitFrequency.monthlyDates:
        if (habit.selectedMonthDates == null ||
            habit.selectedMonthDates!.isEmpty) {
          return 'Specific Dates';
        }
        final dates = List<int>.from(habit.selectedMonthDates!)..sort();
        return dates.map((d) => '${d}${_getOrdinalSuffix(d)}').join(', ');
      case HabitFrequency.timesPerWeek:
        return '${habit.targetCount ?? 1} times per week';
      case HabitFrequency.timesPerMonth:
        return '${habit.targetCount ?? 1} times per month';
    }
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
