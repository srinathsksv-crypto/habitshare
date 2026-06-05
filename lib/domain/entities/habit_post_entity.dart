import 'package:equatable/equatable.dart';

class HabitPostEntity extends Equatable {
  const HabitPostEntity({
    required this.id,
    required this.userId,
    required this.habitId,
    required this.title,
    required this.createdAt,
    this.description,
    this.message,
    this.authorName,
    this.authorPhotoUrl,
    this.imageUrl,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLikedByCurrentUser = false,
  });

  final String id;
  final String userId;
  final String habitId;
  final String title;
  final String? description;
  final String? message;
  final DateTime createdAt;
  final String? authorName;
  final String? authorPhotoUrl;
  final String? imageUrl;
  final int likeCount;
  final int commentCount;
  final bool isLikedByCurrentUser;

  HabitPostEntity copyWith({
    int? likeCount,
    int? commentCount,
    bool? isLikedByCurrentUser,
  }) {
    return HabitPostEntity(
      id: id,
      userId: userId,
      habitId: habitId,
      title: title,
      description: description,
      message: message,
      createdAt: createdAt,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      imageUrl: imageUrl,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        habitId,
        title,
        description,
        message,
        createdAt,
        authorName,
        authorPhotoUrl,
        imageUrl,
        likeCount,
        commentCount,
        isLikedByCurrentUser,
      ];
}
