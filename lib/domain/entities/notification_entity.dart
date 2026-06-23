import 'package:equatable/equatable.dart';

enum NotificationType {
  newPost,
  like,
  comment,
  followRequest,
  followAccepted,
  share,
}

class NotificationEntity extends Equatable {
  const NotificationEntity({
    required this.id,
    required this.receiverId,
    required this.type,
    required this.createdAt,
    this.senderId,
    this.senderName,
    this.senderPhotoUrl,
    this.postId,
    this.isRead = false,
  });

  final String id;
  final String receiverId;
  final NotificationType type;
  final String? senderId;
  final String? senderName;
  final String? senderPhotoUrl;
  final String? postId;
  final bool isRead;
  final DateTime createdAt;

  String messageText(String? senderDisplayName) {
    final name = senderDisplayName ?? senderName ?? 'Someone';
    switch (type) {
      case NotificationType.newPost:
        return '$name shared a new habit post';
      case NotificationType.like:
        return '$name liked your post';
      case NotificationType.comment:
        return '$name commented on your post';
      case NotificationType.followRequest:
        return '$name sent you a follow request';
      case NotificationType.followAccepted:
        return '$name accepted your follow request';
      case NotificationType.share:
        return '$name shared a post with you';
    }
  }

  @override
  List<Object?> get props => [
        id,
        receiverId,
        type,
        senderId,
        senderName,
        senderPhotoUrl,
        postId,
        isRead,
        createdAt,
      ];
}
