import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:habitshare/core/errors/failure.dart';
import 'package:habitshare/domain/entities/follow_entity.dart';
import 'package:habitshare/domain/entities/habit_post_entity.dart';
import 'package:habitshare/domain/entities/notification_entity.dart';
import 'package:habitshare/domain/entities/post_comment_entity.dart';
import 'package:habitshare/domain/entities/user_entity.dart';

abstract class ISocialRepository {
  Future<Either<Failure, void>> upsertUserProfile(UserEntity user);

  Future<Either<Failure, UserEntity?>> getUserProfile(String userId);

  Future<Either<Failure, void>> updateUserBio({
    required String userId,
    required String bio,
  });

  Future<Either<Failure, String>> uploadProfileImage({
    required String userId,
    required File file,
    String? oldPhotoUrl,
  });

  Future<Either<Failure, String>> getProfileImageUrl(String path);

  Future<Either<Failure, List<UserEntity>>> searchUsers({
    required String query,
    required String currentUserId,
  });

  Future<Either<Failure, HabitPostEntity>> createPost({
    required String userId,
    required String habitId,
    required String title,
    String? description,
    String? message,
    String? authorName,
    String? authorPhotoUrl,
    File? imageFile,
  });

  Stream<List<HabitPostEntity>> watchFeed({
    required String viewerId,
  });

  Stream<List<HabitPostEntity>> watchUserPosts({
    required String profileUserId,
    required String viewerId,
  });

  Future<Either<Failure, bool>> canViewUserPosts({
    required String profileUserId,
    required String viewerId,
  });

  Future<Either<Failure, void>> toggleLike({
    required String postOwnerId,
    required String postId,
    required String userId,
    String? likerName,
    String? likerPhotoUrl,
  });

  Stream<List<PostCommentEntity>> watchComments({
    required String postOwnerId,
    required String postId,
  });

  Future<Either<Failure, PostCommentEntity>> addComment({
    required String postOwnerId,
    required String postId,
    required String userId,
    required String text,
    String? authorName,
    String? authorPhotoUrl,
  });

  Future<Either<Failure, void>> sendFollowRequest({
    required String followerId,
    required String followingId,
  });

  Future<Either<Failure, void>> acceptFollowRequest({
    required String followerId,
    required String followingId,
    String? followingName,
    String? followingPhotoUrl,
  });

  Future<Either<Failure, void>> rejectFollowRequest({
    required String followerId,
    required String followingId,
  });

  Future<Either<Failure, void>> unfollowUser({
    required String followerId,
    required String followingId,
  });

  Future<Either<Failure, List<FollowEntity>>> getFollowing(String userId);

  Stream<List<FollowEntity>> watchFollowing(String userId);

  Future<Either<Failure, List<FollowEntity>>> getFollowers(String userId);

  Stream<List<FollowEntity>> watchFollowers(String userId);

  Future<Either<Failure, List<FollowEntity>>> getPendingFollowRequests(
    String userId,
  );

  Stream<List<FollowEntity>> watchPendingFollowRequests(String userId);

  Future<Either<Failure, int>> getFollowingCount(String userId);

  Stream<int> watchFollowingCount(String userId);

  Future<Either<Failure, int>> getFollowersCount(String userId);

  Stream<int> watchFollowersCount(String userId);

  Future<Either<Failure, FollowEntity?>> getFollowRelationship({
    required String followerId,
    required String followingId,
  });

  Stream<FollowEntity?> watchFollowRelationship({
    required String followerId,
    required String followingId,
  });

  Stream<List<NotificationEntity>> watchNotifications(String userId);

  Future<Either<Failure, void>> markNotificationRead({
    required String userId,
    required String notificationId,
  });

  Future<Either<Failure, void>> markAllNotificationsRead(String userId);

  Future<Either<Failure, void>> deletePost({
    required String userId,
    required String postId,
  });

  Future<Either<Failure, void>> createShares({
    required String senderId,
    required String senderName,
    required List<String> receiverIds,
    required String postId,
  });
}
