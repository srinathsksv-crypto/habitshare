import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/core/extensions/context_extensions.dart';
import 'package:habitshare/domain/entities/follow_entity.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/presentation/controllers/social_controller.dart';
import 'package:habitshare/presentation/providers/social_provider.dart';
import 'package:habitshare/presentation/widgets/profile_avatar.dart';
import 'package:habitshare/presentation/widgets/user_tile.dart';

class FindPeopleTab extends ConsumerStatefulWidget {
  const FindPeopleTab({super.key, required this.user});

  final UserEntity user;

  @override
  ConsumerState<FindPeopleTab> createState() => _FindPeopleTabState();
}

class _FindPeopleTabState extends ConsumerState<FindPeopleTab> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(
      userSearchProvider((query: _query, userId: widget.user.id)),
    );
    final suggestedConnections = ref.watch(
      suggestedConnectionsProvider(widget.user.id),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find People'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 8),
          if (_query.trim().isEmpty) ...[
            suggestedConnections.when(
              data: (connections) {
                if (connections.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suggested Connections',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...connections.map(
                      (connection) => _SuggestedConnectionTile(
                        currentUser: widget.user,
                        connection: connection,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ] else ...[
            searchResults.when(
              data: (users) {
                if (users.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No users found'),
                  );
                }
                return Column(
                  children: users
                      .map(
                        (target) => _SearchUserTile(
                          currentUser: widget.user,
                          target: target,
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const Text('Search failed'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuggestedConnectionTile extends ConsumerWidget {
  const _SuggestedConnectionTile({
    required this.currentUser,
    required this.connection,
  });

  final UserEntity currentUser;
  final SuggestedConnection connection;

  String _getFollowedByText() {
    final names = connection.followedByNames;
    if (names.isEmpty) {
      return 'Followed by ${connection.followedByCount} people you follow';
    }
    if (names.length == 1) {
      return 'Followed by ${names[0]}';
    }
    if (names.length == 2) {
      return 'Followed by ${names[0]} and ${names[1]}';
    }
    return 'Followed by ${names[0]} and ${connection.followedByCount - 1} others';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relationship = ref.watch(
      followRelationshipProvider(
        (followerId: currentUser.id, followingId: connection.user.id),
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ProfileAvatar(
          photoUrl: connection.user.photoUrl,
          fallbackText: connection.user.name.isNotEmpty
              ? connection.user.name[0].toUpperCase()
              : '?',
        ),
        title: Text(connection.user.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              connection.user.email,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              _getFollowedByText(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
        trailing: relationship.when(
          data: (entity) {
            if (entity == null) {
              return FilledButton.tonal(
                onPressed: () async {
                  final error = await ref
                      .read(socialControllerProvider)
                      .sendFollowRequest(
                        followerId: currentUser.id,
                        followingId: connection.user.id,
                      );
                  if (context.mounted && error != null) {
                    context.showSnackBar(error, isError: true);
                  }
                },
                child: const Text('Follow'),
              );
            }
            if (entity.status == FollowStatus.pending) {
              return const Chip(label: Text('Requested'));
            }
            return OutlinedButton(
              onPressed: () async {
                final error = await ref.read(socialControllerProvider).unfollow(
                      followerId: currentUser.id,
                      followingId: connection.user.id,
                    );
                if (context.mounted && error != null) {
                  context.showSnackBar(error, isError: true);
                }
              },
              child: const Text('Unfollow'),
            );
          },
          loading: () => const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _SearchUserTile extends ConsumerWidget {
  const _SearchUserTile({
    required this.currentUser,
    required this.target,
  });

  final UserEntity currentUser;
  final UserEntity target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relationship = ref.watch(
      followRelationshipProvider(
        (followerId: currentUser.id, followingId: target.id),
      ),
    );

    return UserTile(
      user: target,
      trailing: relationship.when(
        data: (entity) {
          if (entity == null) {
            return FilledButton.tonal(
              onPressed: () async {
                final error =
                    await ref.read(socialControllerProvider).sendFollowRequest(
                          followerId: currentUser.id,
                          followingId: target.id,
                        );
                if (context.mounted && error != null) {
                  context.showSnackBar(error, isError: true);
                }
              },
              child: const Text('Follow'),
            );
          }
          if (entity.status == FollowStatus.pending) {
            return const Chip(label: Text('Requested'));
          }
          return OutlinedButton(
            onPressed: () async {
              final error = await ref.read(socialControllerProvider).unfollow(
                    followerId: currentUser.id,
                    followingId: target.id,
                  );
              if (context.mounted && error != null) {
                context.showSnackBar(error, isError: true);
              }
            },
            child: const Text('Unfollow'),
          );
        },
        loading: () => const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}
