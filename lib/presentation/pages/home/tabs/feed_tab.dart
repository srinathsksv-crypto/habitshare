import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/presentation/providers/social_provider.dart';
import 'package:habitshare/presentation/widgets/app_notification_button.dart';
import 'package:habitshare/presentation/widgets/create_post_sheet.dart';
import 'package:habitshare/presentation/widgets/post_card.dart';

class FeedTab extends ConsumerWidget {
  const FeedTab({
    super.key,
    required this.user,
    this.postId,
    this.postOwnerId,
  });

  final UserEntity user;
  final String? postId;
  final String? postOwnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = postId != null && postOwnerId != null
        ? ref.watch(
            singlePostProvider((postId: postId!, postOwnerId: postOwnerId!)))
        : ref.watch(feedProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        actions: [AppNotificationButton(user: user)],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'feed_add_post_${user.id}',
        onPressed: () => CreatePostSheet.show(context, user: user),
        child: const Icon(Icons.add_a_photo_outlined),
      ),
      body: feed.when(
        data: (posts) {
          if (posts.isEmpty) {
            // If viewing a specific post that doesn't exist (was deleted)
            if (postId != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error.withValues(
                              alpha: 0.6,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Post no longer exists',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This post may have been deleted by the author.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              );
            }
            // Normal empty feed state
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.dynamic_feed_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary.withValues(
                            alpha: 0.6,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No posts yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a habit with "Share as post" or follow friends and accept their requests to see posts here.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (_, index) => PostCard(
              post: posts[index],
              currentUser: user,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load feed')),
      ),
    );
  }
}
