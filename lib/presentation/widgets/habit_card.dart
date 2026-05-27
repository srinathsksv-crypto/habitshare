import 'package:flutter/material.dart';
import 'package:habitshare/core/utils/date_utils.dart';
import 'package:habitshare/domain/entities/habit_entity.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/presentation/screens/habit_details_screen.dart';

class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.user,
    this.onTap,
  });

  final HabitEntity habit;
  final UserEntity user;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = habit.startDate ?? habit.createdAt;
    final end = habit.endDate;
    final durationLabel = habit.durationInDays != null
        ? '${habit.durationInDays} days'
        : 'Ongoing';

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
              Text(
                '${habit.targetPerPeriod}x ${habit.frequency.name}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
