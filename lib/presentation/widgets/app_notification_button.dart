import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/presentation/providers/notification_provider.dart';
import 'package:habitshare/presentation/screens/notifications_screen.dart';

class AppNotificationButton extends ConsumerWidget {
  const AppNotificationButton({super.key, required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider(user.id));

    return IconButton(
      tooltip: 'Notifications',
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => NotificationsScreen(user: user),
          ),
        );
      },
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(unreadCount > 9 ? '9+' : '$unreadCount'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
