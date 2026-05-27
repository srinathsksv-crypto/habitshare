import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/core/extensions/context_extensions.dart';
import 'package:habitshare/core/utils/date_utils.dart';
import 'package:habitshare/domain/entities/habit_entity.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/presentation/controllers/habit_controller.dart';

class HabitDetailsScreen extends ConsumerWidget {
  const HabitDetailsScreen({
    super.key,
    required this.habit,
    required this.user,
  });

  final HabitEntity habit;
  final UserEntity user;

  Future<void> _confirmQuit(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quit habit?'),
        content: const Text(
          'This will stop tracking progress. Your history stays saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quit'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final error = await ref.read(habitControllerProvider).quitHabit(habit);
    if (!context.mounted) {
      return;
    }
    if (error != null) {
      context.showSnackBar(error, isError: true);
      return;
    }
    context.showSnackBar('Habit marked as quit');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final start = habit.startDate ?? habit.createdAt;
    final end = habit.endDate;
    final duration = habit.durationInDays;

    return Scaffold(
      appBar: AppBar(title: Text(habit.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!habit.isActive)
            Card(
              color: context.colors.errorContainer,
              child: const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('This habit is no longer active'),
              ),
            ),
          if (habit.description?.isNotEmpty == true) ...[
            Text(habit.description!, style: context.textTheme.bodyLarge),
            const SizedBox(height: 20),
          ],
          _InfoRow(
            label: 'Frequency',
            value: '${habit.targetPerPeriod}x ${habit.frequency.name}',
          ),
          _InfoRow(label: 'Start', value: AppDateUtils.formatDay(start)),
          if (end != null) _InfoRow(label: 'End', value: AppDateUtils.formatDay(end)),
          if (duration != null)
            _InfoRow(label: 'Duration', value: '$duration days'),
          _InfoRow(label: 'Status', value: habit.status.name),
          const SizedBox(height: 24),
          if (habit.isActive)
            FilledButton.tonal(
              onPressed: () => _confirmQuit(context, ref),
              child: const Text('Quit habit'),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: context.textTheme.labelLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: context.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
