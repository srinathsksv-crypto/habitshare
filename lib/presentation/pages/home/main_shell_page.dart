import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/presentation/controllers/auth_controller.dart';
import 'package:habitshare/presentation/pages/home/tabs/feed_tab.dart';
import 'package:habitshare/presentation/pages/home/tabs/find_people_tab.dart';
import 'package:habitshare/presentation/pages/home/tabs/habits_tab.dart';
import 'package:habitshare/presentation/pages/home/tabs/profile_tab.dart';
import 'package:habitshare/presentation/providers/auth_provider.dart';
import 'package:habitshare/presentation/providers/social_provider.dart';

class MainShellPage extends ConsumerStatefulWidget {
  const MainShellPage({
    super.key,
    this.initialTabIndex,
    this.postId,
    this.postOwnerId,
  });

  final int? initialTabIndex;
  final String? postId;
  final String? postOwnerId;

  @override
  ConsumerState<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends ConsumerState<MainShellPage> {
  late int _currentIndex;
  bool _profileSynced = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);

    return auth.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Not signed in')),
          );
        }

        if (!_profileSynced) {
          _profileSynced = true;
          ref.read(socialRepositoryProvider).upsertUserProfile(user);
        }

        final tabs = [
          HabitsTab(user: user),
          FeedTab(
            user: user,
            postId: widget.postId,
            postOwnerId: widget.postOwnerId,
          ),
          FindPeopleTab(user: user),
          ProfileTab(user: user),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: tabs,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.check_circle_outline),
                selectedIcon: Icon(Icons.check_circle),
                label: 'Habits',
              ),
              NavigationDestination(
                icon: Icon(Icons.dynamic_feed_outlined),
                selectedIcon: Icon(Icons.dynamic_feed),
                label: 'Feed',
              ),
              NavigationDestination(
                icon: Icon(Icons.search),
                selectedIcon: Icon(Icons.search),
                label: 'Find People',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load profile'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.read(authControllerProvider).logout(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
