import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/core/extensions/context_extensions.dart';
import 'package:habitshare/domain/entities/habit_post_entity.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/presentation/controllers/social_controller.dart';
import 'package:habitshare/presentation/providers/social_provider.dart';
import 'package:intl/intl.dart';

class PostCommentsSheet extends ConsumerStatefulWidget {
  const PostCommentsSheet({
    super.key,
    required this.post,
    required this.currentUser,
  });

  final HabitPostEntity post;
  final UserEntity currentUser;

  @override
  ConsumerState<PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends ConsumerState<PostCommentsSheet> {
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);
    final error = await ref.read(socialControllerProvider).addComment(
          post: widget.post,
          user: widget.currentUser,
          text: text,
        );

    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);

    if (error != null) {
      context.showSnackBar(error, isError: true);
      return;
    }

    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(
      postCommentsProvider(
        (postOwnerId: widget.post.userId, postId: widget.post.id),
      ),
    );
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
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
                    'Comments',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: comments.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return const Center(
                          child: Text('No comments yet. Be the first!'),
                        );
                      }
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: items.length,
                        itemBuilder: (_, index) {
                          final comment = items[index];
                          final author = comment.authorName ?? 'User';
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                author.isNotEmpty
                                    ? author[0].toUpperCase()
                                    : '?',
                              ),
                            ),
                            title: Text(author),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(comment.text),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat.MMMd().add_jm().format(
                                        comment.createdAt,
                                      ),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) =>
                        const Center(child: Text('Failed to load comments')),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            border: OutlineInputBorder(),
                          ),
                          minLines: 1,
                          maxLines: 3,
                          enabled: !_isSubmitting,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _isSubmitting ? null : _submitComment,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
