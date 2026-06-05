import 'package:flutter/material.dart';
import 'package:habitshare/core/utils/date_utils.dart';
import 'package:habitshare/domain/entities/habit_entity.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/domain/services/habit_streak_service.dart';
import 'package:habitshare/presentation/screens/habit_details_screen.dart';

class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.user,
    this.onTap,
    this.onComplete,
  });

  final HabitEntity habit;
  final UserEntity user;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = habit.startDate ?? habit.createdAt;
    final end = habit.endDate;
    final durationLabel = habit.durationInDays != null
        ? '${habit.durationInDays} days'
        : 'Ongoing';
    final now = DateTime.now();
    final canComplete = HabitStreakService.canCompleteHabit(habit, now);
    final completionStatus = HabitStreakService.getCompletionStatus(habit, now);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ??
            () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => HabitDetailsScreen(habit: habit, user: user),
                ),
              );
            },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      habit.title,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (!habit.isActive)
                    Chip(
                      label: Text(habit.status.name),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              if (habit.description?.isNotEmpty == true) ...[
                const SizedBox(height: 6),
                Text(
                  habit.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.date_range_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      end != null
                          ? '${AppDateUtils.formatDay(start)} → ${AppDateUtils.formatDay(end)}'
                          : 'Since ${AppDateUtils.formatDay(start)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    durationLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${habit.targetPerPeriod}x ${habit.frequency.name}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (habit.streakCount > 1)
                    Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          '${habit.streakCount}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (onComplete != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canComplete ? onComplete : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canComplete
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceVariant,
                      foregroundColor: canComplete
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    child: Text(completionStatus),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
