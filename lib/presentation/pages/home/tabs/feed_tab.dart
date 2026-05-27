import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/presentation/providers/social_provider.dart';
import 'package:habitshare/presentation/widgets/app_notification_button.dart';
import 'package:habitshare/presentation/widgets/create_post_sheet.dart';
import 'package:habitshare/presentation/widgets/post_card.dart';

class FeedTab extends ConsumerWidget {
  const FeedTab({super.key, required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedProvider(user.id));

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
