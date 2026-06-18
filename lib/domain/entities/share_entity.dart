import 'package:equatable/equatable.dart';

class ShareEntity extends Equatable {
  const ShareEntity({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.postId,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String postId;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        senderId,
        senderName,
        receiverId,
        postId,
        createdAt,
      ];
}
