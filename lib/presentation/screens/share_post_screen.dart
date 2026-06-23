import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/domain/entities/follow_entity.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/presentation/providers/social_provider.dart';
import 'package:habitshare/presentation/widgets/profile_avatar.dart';

class SharePostScreen extends ConsumerStatefulWidget {
  const SharePostScreen({
    super.key,
    required this.currentUser,
    required this.postId,
  });

  final UserEntity currentUser;
  final String postId;

  @override
  ConsumerState<SharePostScreen> createState() => _SharePostScreenState();
}

class _SharePostScreenState extends ConsumerState<SharePostScreen> {
  final Set<String> _selectedUserIds = {};

  void _toggleSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  Future<void> _handleShare() async {
    if (_selectedUserIds.isEmpty) return;

    final error = await ref.read(socialRepositoryProvider).createShares(
          senderId: widget.currentUser.id,
          senderName: widget.currentUser.name,
          senderPhotoUrl: widget.currentUser.photoUrl,
          receiverIds: _selectedUserIds.toList(),
          postId: widget.postId,
        );

    if (!mounted) return;

    error.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share post: ${failure.message}')),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post shared successfully')),
        );
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final followers = ref.watch(followersProvider(widget.currentUser.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Post'),
      ),
      body: Column(
        children: [
          Expanded(
            child: followers.when(
              data: (followersList) {
                if (followersList.isEmpty) {
                  return const Center(
                    child: Text('No followers yet'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: followersList.length,
                  itemBuilder: (context, index) {
                    final follower = followersList[index];
                    final userId = follower.followerId;
                    final isSelected = _selectedUserIds.contains(userId);

                    return _FollowerCard(
                      follower: follower,
                      isSelected: isSelected,
                      onTap: () => _toggleSelection(userId),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (_, __) => const Center(
                child: Text('Failed to load followers'),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedUserIds.isEmpty ? null : _handleShare,
                child: const Text('Share'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowerCard extends StatelessWidget {
  const _FollowerCard({
    required this.follower,
    required this.isSelected,
    required this.onTap,
  });

  final FollowEntity follower;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = follower.followerName ?? 'User';
    final photoUrl = follower.followerPhotoUrl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : null,
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ProfileAvatar(
                    photoUrl: photoUrl,
                    fallbackText: displayName.isNotEmpty
                        ? displayName[0].toUpperCase()
                        : '?',
                    radius: 30,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _MarqueeText(
                    text: displayName,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.check,
                    size: 16,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MarqueeText extends StatefulWidget {
  const _MarqueeText({
    required this.text,
    this.style,
  });

  final String text;
  final TextStyle? style;

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(text: widget.text, style: widget.style);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          maxLines: 1,
        );
        textPainter.layout();

        final textWidth = textPainter.width;
        final containerWidth = constraints.maxWidth;

        if (textWidth <= containerWidth) {
          return Text(widget.text, style: widget.style);
        }

        _controller.repeat();

        return ClipRect(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  -_animation.value * (textWidth - containerWidth),
                  0,
                ),
                child: child,
              );
            },
            child: Text(
              widget.text,
              style: widget.style,
              overflow: TextOverflow.fade,
              softWrap: false,
            ),
          ),
        );
      },
    );
  }
}
