import 'package:equatable/equatable.dart';

class PostCommentEntity extends Equatable {
  const PostCommentEntity({
    required this.id,
    required this.postId,
    required this.userId,
    required this.text,
    required this.createdAt,
    this.authorName,
    this.authorPhotoUrl,
  });

  final String id;
  final String postId;
  final String userId;
  final String text;
  final DateTime createdAt;
  final String? authorName;
  final String? authorPhotoUrl;

  @override
  List<Object?> get props => [
    id,
    postId,
    userId,
    text,
    createdAt,
    authorName,
    authorPhotoUrl,
  ];
}
