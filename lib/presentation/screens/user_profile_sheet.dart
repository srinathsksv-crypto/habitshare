import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/core/extensions/context_extensions.dart';
import 'package:habitshare/domain/entities/follow_entity.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/presentation/controllers/social_controller.dart';
import 'package:habitshare/presentation/providers/social_provider.dart';
import 'package:habitshare/presentation/providers/user_profile_provider.dart';

class UserProfileSheet {
  const UserProfileSheet._();

  static Future<void> show({
    required BuildContext context,
    required UserEntity currentUser,
    required String targetUserId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _UserProfileSheet(
        currentUser: currentUser,
        targetUserId: targetUserId,
      ),
    );
  }
}

class _UserProfileSheet extends ConsumerWidget {
  const _UserProfileSheet({
    required this.currentUser,
    required this.targetUserId,
  });

  final UserEntity currentUser;
  final String targetUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider(targetUserId));
    final relationship = ref.watch(
      followRelationshipProvider(
        (followerId: currentUser.id, followingId: targetUserId),
      ),
    );

    return profile.when(
      data: (user) {
        final resolved = user;
        if (resolved == null) {
          return const SizedBox.shrink();
        }

        final isSelf = resolved.id == currentUser.id;
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: resolved.photoUrl != null
                        ? NetworkImage(resolved.photoUrl!)
                        : null,
                    child: resolved.photoUrl == null
                        ? Text(
                            resolved.name.isNotEmpty
                                ? resolved.name[0].toUpperCase()
                                : '?',
                            style: Theme.of(context).textTheme.headlineMedium,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resolved.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if ((resolved.bio ?? '').isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.colors.primaryContainer.withValues(
                      alpha: 0.35,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    resolved.bio!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              const SizedBox(height: 16),
              if (!isSelf)
                relationship.when(
                  data: (entity) => _FollowButton(
                    relationship: entity,
                    followerId: currentUser.id,
                    followingId: resolved.id,
                  ),
                  loading: () => const SizedBox(
                    height: 44,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox(
                    height: 44,
                    child: Center(child: Text('Unable to load relationship')),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox(
        height: 200,
        child: Center(child: Text('Failed to load profile')),
      ),
    );
  }
}

class _FollowButton extends ConsumerWidget {
  const _FollowButton({
    required this.relationship,
    required this.followerId,
    required this.followingId,
  });

  final FollowEntity? relationship;
  final String followerId;
  final String followingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(socialControllerProvider);

    if (relationship == null) {
      return FilledButton.tonal(
        onPressed: () async {
          final error = await controller.sendFollowRequest(
            followerId: followerId,
            followingId: followingId,
          );
          if (!context.mounted) return;
          if (error != null) {
            context.showSnackBar(error, isError: true);
          } else {
            context.showSnackBar('Follow request sent');
          }
        },
        child: const Text('Follow'),
      );
    }

    if (relationship!.status == FollowStatus.pending) {
      return const Chip(label: Text('Requested'));
    }

    return OutlinedButton(
      onPressed: () async {
        final error = await controller.unfollow(
          followerId: followerId,
          followingId: followingId,
        );
        if (!context.mounted) return;
        if (error != null) {
          context.showSnackBar(error, isError: true);
        } else {
          context.showSnackBar('Unfollowed');
        }
      },
      child: const Text('Unfollow'),
    );
  }
}

