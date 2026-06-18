import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/core/extensions/context_extensions.dart';
import 'package:habitshare/core/utils/date_utils.dart';
import 'package:habitshare/domain/entities/habit_entity.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/presentation/controllers/habit_controller.dart';
import 'package:habitshare/presentation/pages/habit_form_page.dart';

class HabitDetailsScreen extends ConsumerStatefulWidget {
  const HabitDetailsScreen({
    super.key,
    required this.habit,
    required this.user,
  });

  final HabitEntity habit;
  final UserEntity user;

  @override
  ConsumerState<HabitDetailsScreen> createState() => _HabitDetailsScreenState();
}

class _HabitDetailsScreenState extends ConsumerState<HabitDetailsScreen> {
  late HabitEntity _habit;

  @override
  void initState() {
    super.initState();
    _habit = widget.habit;
  }

  Future<void> _confirmQuit(BuildContext context) async {
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
    final error = await ref.read(habitControllerProvider).quitHabit(_habit);
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

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete habit?'),
        content: const Text(
          'This will permanently delete this habit and all its posts. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final error = await ref.read(habitControllerProvider).deleteHabit(_habit);
    if (!context.mounted) {
      return;
    }
    if (error != null) {
      context.showSnackBar(error, isError: true);
      return;
    }
    context.showSnackBar('Habit deleted');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final start = _habit.startDate ?? _habit.createdAt;
    final end = _habit.endDate;
    final duration = _habit.durationInDays;

    return Scaffold(
      appBar: AppBar(
        title: Text(_habit.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final updatedHabit = await Navigator.push<HabitEntity>(
                context,
                MaterialPageRoute(
                  builder: (_) => HabitFormPage(
                    user: widget.user,
                    habit: _habit,
                  ),
                ),
              );
              if (updatedHabit != null && mounted) {
                setState(() {
                  _habit = updatedHabit;
                });
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!_habit.isActive)
            Card(
              color: context.colors.errorContainer,
              child: const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('This habit is no longer active'),
              ),
            ),
          if (_habit.description?.isNotEmpty == true) ...[
            Text(_habit.description!, style: context.textTheme.bodyLarge),
            const SizedBox(height: 20),
          ],
          _InfoRow(
            label: 'Frequency',
            value: '${_habit.targetPerPeriod}x ${_habit.frequency.name}',
          ),
          if (_habit.frequency == HabitFrequency.timesPerWeek) ...[
            _InfoRow(
              label: 'Target',
              value: '${_habit.targetCount} times per week',
            ),
            _InfoRow(
              label: 'Progress',
              value:
                  '${_habit.currentPeriodCompletionCount}/${_habit.targetCount} this week',
            ),
          ],
          _InfoRow(label: 'Start', value: AppDateUtils.formatDay(start)),
          if (end != null)
            _InfoRow(label: 'End', value: AppDateUtils.formatDay(end)),
          if (duration != null)
            _InfoRow(label: 'Duration', value: '$duration days'),
          _InfoRow(label: 'Status', value: _habit.status.name),
          const SizedBox(height: 24),
          if (_habit.isActive) ...[
            FilledButton.tonal(
              onPressed: () => _confirmQuit(context),
              child: const Text('Quit habit'),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.error,
              side: BorderSide(color: context.colors.error),
            ),
            onPressed: () => _confirmDelete(context),
            child: const Text('Delete habit'),
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
