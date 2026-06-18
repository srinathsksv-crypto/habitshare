import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/config/constants/app_constants.dart';
import 'package:habitshare/core/extensions/context_extensions.dart';
import 'package:habitshare/domain/entities/follow_entity.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/presentation/controllers/auth_controller.dart';
import 'package:habitshare/presentation/controllers/social_controller.dart';
import 'package:habitshare/presentation/providers/user_profile_provider.dart';
import 'package:habitshare/presentation/providers/social_provider.dart';
import 'package:habitshare/presentation/widgets/app_notification_button.dart';
import 'package:habitshare/presentation/widgets/user_connections_sheet.dart';
import 'package:habitshare/presentation/widgets/profile_avatar.dart';
import 'package:image_picker/image_picker.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key, required this.user});

  final UserEntity user;

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  @override
  Widget build(BuildContext context) {
    final followersCount = ref.watch(followersCountProvider(widget.user.id));
    final followingCount = ref.watch(followingCountProvider(widget.user.id));
    final pendingRequests = ref.watch(
      pendingFollowRequestsProvider(widget.user.id),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          AppNotificationButton(user: widget.user),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => ref.read(authControllerProvider).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileHeader(user: widget.user),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _CountButton(
                  label: 'Followers',
                  countAsync: followersCount,
                  onTap: () => UserConnectionsSheet.show(
                    context,
                    currentUser: widget.user,
                    type: ConnectionsSheetType.followers,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CountButton(
                  label: 'Following',
                  countAsync: followingCount,
                  onTap: () => UserConnectionsSheet.show(
                    context,
                    currentUser: widget.user,
                    type: ConnectionsSheetType.following,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          pendingRequests.when(
            data: (requests) {
              if (requests.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Follow requests',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...requests.map(
                    (request) => _FollowRequestTile(
                      request: request,
                      currentUser: widget.user,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends ConsumerStatefulWidget {
  const _ProfileHeader({required this.user});

  final UserEntity user;

  @override
  ConsumerState<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends ConsumerState<_ProfileHeader> {
  final _bioController = TextEditingController();
  bool _editingBio = false;
  bool _savingBio = false;
  bool _uploadingPhoto = false;

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _uploadingPhoto = true);
    final currentProfile = ref.read(userProfileProvider(widget.user.id)).value;
    final oldPhotoUrl = currentProfile?.photoUrl ?? widget.user.photoUrl;

    final error = await ref.read(socialControllerProvider).uploadProfilePhoto(
          userId: widget.user.id,
          file: File(picked.path),
          oldPhotoUrl: oldPhotoUrl,
        );
    if (mounted) {
      setState(() => _uploadingPhoto = false);
      if (error != null) {
        context.showSnackBar(error, isError: true);
      } else {
        context.showSnackBar('Profile photo updated');
      }
    }
  }

  Future<void> _saveBio() async {
    final bio = _bioController.text.trim();
    if (bio.length > AppConstants.maxBioLength) {
      context.showSnackBar(
        'Bio must be ${AppConstants.maxBioLength} characters or less',
        isError: true,
      );
      return;
    }
    setState(() => _savingBio = true);
    final error = await ref.read(socialControllerProvider).updateBio(
          userId: widget.user.id,
          bio: bio,
        );
    if (!mounted) {
      return;
    }
    setState(() {
      _savingBio = false;
      _editingBio = false;
    });
    if (error != null) {
      context.showSnackBar(error, isError: true);
    } else {
      context.showSnackBar('Bio updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider(widget.user.id));
    final displayUser = profile.maybeWhen(
      data: (stored) => stored ?? widget.user,
      orElse: () => widget.user,
    );
    final photoUrl = displayUser.photoUrl;
    final bio = displayUser.bio ?? '';

    if (!_editingBio && _bioController.text != bio) {
      _bioController.text = bio;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Stack(
              children: [
                ProfileAvatar(
                  photoUrl: photoUrl,
                  fallbackText: widget.user.name.isNotEmpty
                      ? widget.user.name[0].toUpperCase()
                      : '?',
                  radius: 36,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      minimumSize: const Size(32, 32),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: _uploadingPhoto ? null : _pickProfilePhoto,
                    icon: _uploadingPhoto
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.user.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('Bio', style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            if (!_editingBio)
              TextButton(
                onPressed: () => setState(() => _editingBio = true),
                child: const Text('Edit'),
              ),
          ],
        ),
        if (_editingBio) ...[
          TextField(
            controller: _bioController,
            maxLength: AppConstants.maxBioLength,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Tell others about yourself...',
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _savingBio
                    ? null
                    : () => setState(() {
                          _editingBio = false;
                          _bioController.text = bio;
                        }),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: _savingBio ? null : _saveBio,
                child: _savingBio
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ] else if (bio.isNotEmpty)
          Text(bio)
        else
          Text(
            'Add a short bio',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
      ],
    );
  }
}

class _CountButton extends StatelessWidget {
  const _CountButton({
    required this.label,
    required this.countAsync,
    required this.onTap,
  });

  final String label;
  final AsyncValue<int> countAsync;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        children: [
          countAsync.when(
            data: (count) => Text(
              '$count',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            loading: () => const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => const Text('0'),
          ),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}

class _FollowRequestTile extends ConsumerWidget {
  const _FollowRequestTile({
    required this.request,
    required this.currentUser,
  });

  final FollowEntity request;
  final UserEntity currentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = request.followerName ?? 'User';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ProfileAvatar(
          photoUrl: request.followerPhotoUrl,
          fallbackText: name.isNotEmpty ? name[0].toUpperCase() : '?',
        ),
        title: Text(name),
        subtitle: const Text('wants to follow you'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () async {
                final error = await ref
                    .read(socialControllerProvider)
                    .rejectFollowRequest(
                      currentUserId: currentUser.id,
                      followerId: request.followerId,
                    );
                if (!context.mounted) {
                  return;
                }
                if (error != null) {
                  context.showSnackBar(error, isError: true);
                } else {
                  context.showSnackBar('Request declined');
                }
              },
              child: const Text('Decline'),
            ),
            FilledButton(
              onPressed: () async {
                final error = await ref
                    .read(socialControllerProvider)
                    .acceptFollowRequest(
                      currentUserId: currentUser.id,
                      followerId: request.followerId,
                      followingName: currentUser.name,
                      followingPhotoUrl: currentUser.photoUrl,
                    );
                if (!context.mounted) {
                  return;
                }
                if (error != null) {
                  context.showSnackBar(error, isError: true);
                } else {
                  context.showSnackBar('Follow request accepted');
                }
              },
              child: const Text('Accept'),
            ),
          ],
        ),
      ),
    );
  }
}
