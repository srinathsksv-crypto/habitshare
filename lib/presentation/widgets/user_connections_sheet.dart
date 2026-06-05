import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/core/extensions/context_extensions.dart';
import 'package:habitshare/domain/entities/follow_entity.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/presentation/controllers/social_controller.dart';
import 'package:habitshare/presentation/providers/social_provider.dart';
import 'package:habitshare/presentation/widgets/profile_avatar.dart';

enum ConnectionsSheetType { followers, following }

class UserConnectionsSheet extends ConsumerWidget {
  const UserConnectionsSheet({
    super.key,
    required this.currentUser,
    required this.type,
  });

  final UserEntity currentUser;
  final ConnectionsSheetType type;

  static Future<void> show(
    BuildContext context, {
    required UserEntity currentUser,
    required ConnectionsSheetType type,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => UserConnectionsSheet(
        currentUser: currentUser,
        type: type,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowingList = type == ConnectionsSheetType.following;
    final connections = isFollowingList
        ? ref.watch(followingProvider(currentUser.id))
        : ref.watch(followersProvider(currentUser.id));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Material(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  isFollowingList ? 'Following' : 'Followers',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: connections.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          isFollowingList
                              ? 'Not following anyone yet'
                              : 'No followers yet',
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: list.length,
                      itemBuilder: (_, index) => _ConnectionTile(
                        currentUser: currentUser,
                        follow: list[index],
                        isFollowingList: isFollowingList,
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(
                    child: Text('Failed to load list'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConnectionTile extends ConsumerWidget {
  const _ConnectionTile({
    required this.currentUser,
    required this.follow,
    required this.isFollowingList,
  });

  final UserEntity currentUser;
  final FollowEntity follow;
  final bool isFollowingList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = follow.displayNameForTarget(isFollowingList: isFollowingList);
    final photoUrl = follow.photoUrlForTarget(isFollowingList: isFollowingList);
    final targetId = follow.targetUserId(isFollowingList: isFollowingList);
    final isSelf = targetId == currentUser.id;

    return ListTile(
      leading: ProfileAvatar(
        photoUrl: photoUrl,
        fallbackText: name.isNotEmpty ? name[0].toUpperCase() : '?',
      ),
      title: Text(name),
      trailing: isSelf
          ? null
          : _FollowActionButton(
              currentUserId: currentUser.id,
              targetUserId: targetId,
            ),
    );
  }
}

class _FollowActionButton extends ConsumerWidget {
  const _FollowActionButton({
    required this.currentUserId,
    required this.targetUserId,
  });

  final String currentUserId;
  final String targetUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relationship = ref.watch(
      followRelationshipProvider(
        (followerId: currentUserId, followingId: targetUserId),
      ),
    );

    return relationship.when(
      data: (entity) {
        if (entity == null) {
          return FilledButton.tonal(
            onPressed: () => _sendRequest(context, ref),
            child: const Text('Follow'),
          );
        }
        if (entity.status == FollowStatus.pending) {
          return const Chip(label: Text('Requested'));
        }
        return OutlinedButton(
          onPressed: () => _unfollow(context, ref),
          child: const Text('Unfollow'),
        );
      },
      loading: () => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _sendRequest(BuildContext context, WidgetRef ref) async {
    final error = await ref.read(socialControllerProvider).sendFollowRequest(
          followerId: currentUserId,
          followingId: targetUserId,
        );
    if (context.mounted && error != null) {
      context.showSnackBar(error, isError: true);
    }
  }

  Future<void> _unfollow(BuildContext context, WidgetRef ref) async {
    final error = await ref.read(socialControllerProvider).unfollow(
          followerId: currentUserId,
          followingId: targetUserId,
        );
    if (context.mounted && error != null) {
      context.showSnackBar(error, isError: true);
    }
  }
}

