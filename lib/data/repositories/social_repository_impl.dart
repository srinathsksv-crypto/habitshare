import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:habitshare/core/errors/error_mapper.dart';
import 'package:habitshare/core/errors/failure.dart';
import 'package:habitshare/data/datasources/remote/firebase_storage_datasource.dart';
import 'package:habitshare/data/datasources/remote/firestore_datasource.dart';
import 'package:habitshare/domain/entities/follow_entity.dart';
import 'package:habitshare/domain/entities/habit_post_entity.dart';
import 'package:habitshare/domain/entities/notification_entity.dart';
import 'package:habitshare/domain/entities/post_comment_entity.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/domain/repositories/social_repository.dart';

class SocialRepositoryImpl implements ISocialRepository {
  SocialRepositoryImpl(this._remote, this._storage);

  final FirestoreDataSource _remote;
  final FirebaseStorageDataSource _storage;

  @override
  Future<Either<Failure, void>> upsertUserProfile(UserEntity user) async {
    try {
      await _remote.upsertUserProfile(user);
      return const Right(null);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getUserProfile(String userId) async {
    try {
      return Right(await _remote.getUserProfile(userId));
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserBio({
    required String userId,
    required String bio,
  }) async {
    try {
      await _remote.updateUserBio(userId: userId, bio: bio);
      return const Right(null);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, String>> uploadProfileImage({
    required String userId,
    required File file,
  }) async {
    try {
      final url = await _storage.uploadProfileImage(userId: userId, file: file);
      await _remote.updateUserPhotoUrl(userId: userId, photoUrl: url);
      return Right(url);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<UserEntity>>> searchUsers({
    required String query,
    required String currentUserId,
  }) async {
    try {
      final users = await _remote.searchUsers(
        query: query,
        currentUserId: currentUserId,
      );
      return Right(users);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, HabitPostEntity>> createPost({
    required String userId,
    required String habitId,
    required String title,
    String? description,
    String? message,
    String? authorName,
    String? authorPhotoUrl,
    File? imageFile,
  }) async {
    try {
      final post = await _remote.createPost(
        userId: userId,
        habitId: habitId,
        title: title,
        description: description,
        message: message,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
        imageFile: imageFile,
      );
      return Right(post);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Stream<List<HabitPostEntity>> watchFeed({required String viewerId}) =>
      _remote.watchFeed(viewerId: viewerId);

  @override
  Stream<List<HabitPostEntity>> watchUserPosts({
    required String profileUserId,
    required String viewerId,
  }) =>
      _remote.watchUserPosts(
        profileUserId: profileUserId,
        viewerId: viewerId,
      );

  @override
  Future<Either<Failure, bool>> canViewUserPosts({
    required String profileUserId,
    required String viewerId,
  }) async {
    try {
      return Right(
        await _remote.canViewUserPosts(
          profileUserId: profileUserId,
          viewerId: viewerId,
        ),
      );
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> toggleLike({
    required String postOwnerId,
    required String postId,
    required String userId,
    String? likerName,
    String? likerPhotoUrl,
  }) async {
    try {
      await _remote.toggleLike(
        postOwnerId: postOwnerId,
        postId: postId,
        userId: userId,
        likerName: likerName,
        likerPhotoUrl: likerPhotoUrl,
      );
      return const Right(null);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Stream<List<PostCommentEntity>> watchComments({
    required String postOwnerId,
    required String postId,
  }) =>
      _remote.watchComments(postOwnerId: postOwnerId, postId: postId);

  @override
  Future<Either<Failure, PostCommentEntity>> addComment({
    required String postOwnerId,
    required String postId,
    required String userId,
    required String text,
    String? authorName,
    String? authorPhotoUrl,
  }) async {
    try {
      final comment = await _remote.addComment(
        postOwnerId: postOwnerId,
        postId: postId,
        userId: userId,
        text: text,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
      );
      return Right(comment);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> sendFollowRequest({
    required String followerId,
    required String followingId,
  }) async {
    try {
      await _remote.sendFollowRequest(
        followerId: followerId,
        followingId: followingId,
      );
      return const Right(null);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> acceptFollowRequest({
    required String followerId,
    required String followingId,
    String? followingName,
    String? followingPhotoUrl,
  }) async {
    try {
      await _remote.acceptFollowRequest(
        followerId: followerId,
        followingId: followingId,
        followingName: followingName,
        followingPhotoUrl: followingPhotoUrl,
      );
      return const Right(null);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> rejectFollowRequest({
    required String followerId,
    required String followingId,
  }) async {
    try {
      await _remote.rejectFollowRequest(
        followerId: followerId,
        followingId: followingId,
      );
      return const Right(null);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> unfollowUser({
    required String followerId,
    required String followingId,
  }) async {
    try {
      await _remote.unfollowUser(
        followerId: followerId,
        followingId: followingId,
      );
      return const Right(null);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<FollowEntity>>> getFollowing(
    String userId,
  ) async {
    try {
      return Right(await _remote.getFollowing(userId));
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<FollowEntity>>> getFollowers(
    String userId,
  ) async {
    try {
      return Right(await _remote.getFollowers(userId));
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<FollowEntity>>> getPendingFollowRequests(
    String userId,
  ) async {
    try {
      return Right(await _remote.getPendingFollowRequests(userId));
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, int>> getFollowingCount(String userId) async {
    try {
      return Right(await _remote.getFollowingCount(userId));
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, int>> getFollowersCount(String userId) async {
    try {
      return Right(await _remote.getFollowersCount(userId));
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, FollowEntity?>> getFollowRelationship({
    required String followerId,
    required String followingId,
  }) async {
    try {
      return Right(
        await _remote.getFollowRelationship(
          followerId: followerId,
          followingId: followingId,
        ),
      );
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Stream<List<NotificationEntity>> watchNotifications(String userId) =>
      _remote.watchNotifications(userId);

  @override
  Future<Either<Failure, void>> markNotificationRead({
    required String userId,
    required String notificationId,
  }) async {
    try {
      await _remote.markNotificationRead(
        userId: userId,
        notificationId: notificationId,
      );
      return const Right(null);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> markAllNotificationsRead(String userId) async {
    try {
      await _remote.markAllNotificationsRead(userId);
      return const Right(null);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
