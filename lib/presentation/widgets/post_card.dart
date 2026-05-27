import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/core/extensions/context_extensions.dart';
import 'package:habitshare/domain/entities/habit_post_entity.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/presentation/controllers/social_controller.dart';
import 'package:habitshare/presentation/widgets/post_comments_sheet.dart';
import 'package:habitshare/presentation/screens/user_profile_sheet.dart';
import 'package:intl/intl.dart';

class PostCard extends ConsumerStatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.currentUser,
  });

  final HabitPostEntity post;
  final UserEntity currentUser;

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _isLiking = false;

  Future<void> _toggleLike() async {
    setState(() => _isLiking = true);
    final error = await ref.read(socialControllerProvider).toggleLike(
          post: widget.post,
          user: widget.currentUser,
        );
    if (mounted) {
      setState(() => _isLiking = false);
      if (error != null) {
        context.showSnackBar(error, isError: true);
      }
    }
  }

  void _openComments() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PostCommentsSheet(
        post: widget.post,
        currentUser: widget.currentUser,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post;
    final author = post.authorName ?? 'User';
    final time = DateFormat.MMMd().add_jm().format(post.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () {
                    UserProfileSheet.show(
                      context: context,
                      currentUser: widget.currentUser,
                      targetUserId: post.userId,
                    );
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: CircleAvatar(
                    backgroundImage: post.authorPhotoUrl != null
                        ? CachedNetworkImageProvider(post.authorPhotoUrl!)
                        : null,
                    child: post.authorPhotoUrl == null
                        ? Text(
                            author.isNotEmpty ? author[0].toUpperCase() : '?',
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      UserProfileSheet.show(
                        context: context,
                        currentUser: widget.currentUser,
                        targetUserId: post.userId,
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(author, style: theme.textTheme.titleMedium),
                        Text(
                          time,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Icon(Icons.track_changes, color: theme.colorScheme.primary),
              ],
            ),
            const SizedBox(height: 12),
            Text(post.title, style: theme.textTheme.titleLarge),
            if (post.description?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(post.description!),
            ],
            if (post.imageUrl != null) ...[
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 4 / 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
            ],
            if (post.message?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.35,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(post.message!),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: _isLiking ? null : _toggleLike,
                  icon: Icon(
                    post.isLikedByCurrentUser
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: post.isLikedByCurrentUser
                        ? theme.colorScheme.error
                        : null,
                  ),
                ),
                Text('${post.likeCount}'),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _openComments,
                  icon: const Icon(Icons.chat_bubble_outline),
                ),
                Text('${post.commentCount}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
