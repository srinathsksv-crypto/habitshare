import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/presentation/providers/auth_provider.dart';
import 'package:habitshare/presentation/providers/habit_provider.dart';
import 'package:habitshare/presentation/widgets/habit_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Not signed in')));
        }
        final habits = ref.watch(habitsProvider(user.id));
        return Scaffold(
          appBar: AppBar(title: const Text('Your Habits')),
          body: habits.when(
            data: (items) {
              if (items.isEmpty) {
                return const Center(child: Text('No habits yet'));
              }
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, index) =>
                    HabitCard(habit: items[index], user: user),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Failed to load habits')),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Scaffold(
        body: Center(child: Text('Failed to load profile')),
      ),
    );
  }
}
