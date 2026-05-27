import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:habitshare/domain/entities/notification_entity.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

@freezed
sealed class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String id,
    @JsonKey(name: 'receiver_id') required String receiverId,
    required String type,
    @JsonKey(name: 'sender_id') String? senderId,
    @JsonKey(name: 'sender_name') String? senderName,
    @JsonKey(name: 'sender_photo_url') String? senderPhotoUrl,
    @JsonKey(name: 'post_id') String? postId,
    @JsonKey(name: 'is_read') @Default(false) bool isRead,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);
}

extension NotificationModelX on NotificationModel {
  NotificationEntity toEntity() => NotificationEntity(
        id: id,
        receiverId: receiverId,
        type: _parseType(type),
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        postId: postId,
        isRead: isRead,
        createdAt: createdAt,
      );

  static NotificationModel fromEntity(NotificationEntity entity) =>
      NotificationModel(
        id: entity.id,
        receiverId: entity.receiverId,
        type: entity.type.name,
        senderId: entity.senderId,
        senderName: entity.senderName,
        senderPhotoUrl: entity.senderPhotoUrl,
        postId: entity.postId,
        isRead: entity.isRead,
        createdAt: entity.createdAt,
      );
}

NotificationType _parseType(String value) =>
    NotificationType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => NotificationType.newPost,
    );
