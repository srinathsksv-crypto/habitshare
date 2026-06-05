import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/core/extensions/context_extensions.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/presentation/controllers/habit_controller.dart';
import 'package:habitshare/presentation/providers/habit_provider.dart';
import 'package:habitshare/presentation/widgets/app_notification_button.dart';
import 'package:habitshare/presentation/widgets/create_habit_dialog.dart';
import 'package:habitshare/presentation/widgets/habit_card.dart';

class HabitsTab extends ConsumerWidget {
  const HabitsTab({super.key, required this.user});

  final UserEntity user;

  Future<void> _openCreateDialog(BuildContext context, WidgetRef ref) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => CreateHabitDialog(user: user),
    );
    if (created == true && context.mounted) {
      context.showSnackBar('Habit created!');
    }
  }

  Future<void> _completeHabit(
      BuildContext context, WidgetRef ref, String habitId) async {
    final error = await ref.read(habitControllerProvider).completeHabit(
          userId: user.id,
          habitId: habitId,
        );
    if (context.mounted) {
      if (error != null) {
        context.showSnackBar(error, isError: true);
      } else {
        context.showSnackBar('Habit completed!');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsStreamProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Habits'),
        actions: [
          IconButton(
            tooltip: 'Add habit',
            onPressed: () => _openCreateDialog(context, ref),
            icon: const Icon(Icons.add),
          ),
          AppNotificationButton(user: user),
        ],
      ),
      body: habits.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.self_improvement_outlined,
                      size: 64,
                      color: context.colors.primary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No habits yet',
                      style: context.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to create your first habit and share it as a post.',
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _openCreateDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Habit'),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(habitsStreamProvider(user.id));
              ref.invalidate(habitsProvider(user.id));
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (_, index) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: HabitCard(
                  habit: items[index],
                  user: user,
                  onComplete: () =>
                      _completeHabit(context, ref, items[index].id),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load habits'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(habitsStreamProvider(user.id)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'habits_add_habit_${user.id}',
        onPressed: () => _openCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Habit'),
      ),
    );
  }
}
