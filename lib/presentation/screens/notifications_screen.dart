import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/core/extensions/context_extensions.dart';
import 'package:habitshare/core/utils/date_utils.dart';
import 'package:habitshare/domain/entities/notification_entity.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/presentation/controllers/social_controller.dart';
import 'package:habitshare/presentation/providers/notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key, required this.user});

  final UserEntity user;

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(socialControllerProvider)
          .markAllNotificationsRead(widget.user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider(widget.user.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notifications.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 64,
                    color: context.colors.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: context.textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, index) => _NotificationTile(
              notification: items[index],
              userId: widget.user.id,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load notifications'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(
                  notificationsProvider(widget.user.id),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({
    required this.notification,
    required this.userId,
  });

  final NotificationEntity notification;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = notification.senderName ?? 'Someone';
    final photoUrl = notification.senderPhotoUrl;

    return Material(
      color: notification.isRead
          ? null
          : context.colors.primaryContainer.withValues(alpha: 0.25),
      child: ListTile(
        onTap: () async {
          if (!notification.isRead) {
            await ref.read(socialControllerProvider).markNotificationRead(
                  userId: userId,
                  notificationId: notification.id,
                );
          }
        },
        leading: CircleAvatar(
          backgroundImage:
              photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
              : null,
        ),
        title: Text(notification.messageText(name)),
        subtitle: Text(AppDateUtils.timeAgo(notification.createdAt)),
        trailing: notification.isRead
            ? null
            : Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }
}
