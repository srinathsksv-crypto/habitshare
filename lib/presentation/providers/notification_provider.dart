import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/domain/entities/notification_entity.dart';
import 'package:habitshare/presentation/providers/social_provider.dart';

final notificationsProvider =
    StreamProvider.family<List<NotificationEntity>, String>((ref, userId) {
  return ref.watch(socialRepositoryProvider).watchNotifications(userId);
});

final unreadNotificationsCountProvider =
    Provider.family<int, String>((ref, userId) {
  final notifications = ref.watch(notificationsProvider(userId));
  return notifications.maybeWhen(
    data: (items) => items.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
