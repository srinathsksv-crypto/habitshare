import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/domain/entities/habit_post_entity.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/domain/repositories/social_repository.dart';
import 'package:habitshare/presentation/providers/auth_provider.dart';
import 'package:habitshare/presentation/providers/notification_provider.dart';
import 'package:habitshare/presentation/providers/social_provider.dart';
import 'package:habitshare/presentation/providers/user_profile_provider.dart';

final socialControllerProvider = Provider<SocialController>(
  (ref) => SocialController(ref),
);

class SocialController {
  const SocialController(this._ref);

  final Ref _ref;

  ISocialRepository get _repo => _ref.read(socialRepositoryProvider);

  Future<String?> toggleLike({
    required HabitPostEntity post,
    required UserEntity user,
  }) async {
    final result = await _repo.toggleLike(
      postOwnerId: post.userId,
      postId: post.id,
      userId: user.id,
      likerName: user.name,
      likerPhotoUrl: user.photoUrl,
    );
    return result.fold((f) => f.message, (_) {
      _ref.invalidate(feedProvider(user.id));
      return null;
    });
  }

  Future<String?> addComment({
    required HabitPostEntity post,
    required UserEntity user,
    required String text,
  }) async {
    final result = await _repo.addComment(
      postOwnerId: post.userId,
      postId: post.id,
      userId: user.id,
      text: text.trim(),
      authorName: user.name,
      authorPhotoUrl: user.photoUrl,
    );
    return result.fold((f) => f.message, (_) {
      _ref.invalidate(
        postCommentsProvider((postOwnerId: post.userId, postId: post.id)),
      );
      _ref.invalidate(feedProvider(user.id));
      return null;
    });
  }

  Future<String?> createPost({
    required UserEntity user,
    required String habitId,
    required String title,
    String? description,
    String? message,
    File? imageFile,
  }) async {
    final result = await _repo.createPost(
      userId: user.id,
      habitId: habitId,
      title: title,
      description: description,
      message: message,
      authorName: user.name,
      authorPhotoUrl: user.photoUrl,
      imageFile: imageFile,
    );
    return result.fold((f) => f.message, (_) {
      _ref.invalidate(feedProvider(user.id));
      return null;
    });
  }

  Future<String?> sendFollowRequest({
    required String followerId,
    required String followingId,
  }) async {
    final result = await _repo.sendFollowRequest(
      followerId: followerId,
      followingId: followingId,
    );
    return result.fold((f) => f.message, (_) {
      _invalidateSocial(followerId, followingId);
      return null;
    });
  }

  Future<String?> acceptFollowRequest({
    required String currentUserId,
    required String followerId,
    String? followingName,
    String? followingPhotoUrl,
  }) async {
    final result = await _repo.acceptFollowRequest(
      followerId: followerId,
      followingId: currentUserId,
      followingName: followingName,
      followingPhotoUrl: followingPhotoUrl,
    );
    return result.fold((f) => f.message, (_) {
      _invalidateSocial(followerId, currentUserId);
      _ref.invalidate(notificationsProvider(followerId));
      return null;
    });
  }

  Future<String?> rejectFollowRequest({
    required String currentUserId,
    required String followerId,
  }) async {
    final result = await _repo.rejectFollowRequest(
      followerId: followerId,
      followingId: currentUserId,
    );
    return result.fold((f) => f.message, (_) {
      _invalidateSocial(followerId, currentUserId);
      return null;
    });
  }

  Future<String?> unfollow({
    required String followerId,
    required String followingId,
  }) async {
    final result = await _repo.unfollowUser(
      followerId: followerId,
      followingId: followingId,
    );
    return result.fold((f) => f.message, (_) {
      _invalidateSocial(followerId, followingId);
      return null;
    });
  }

  Future<String?> updateBio({
    required String userId,
    required String bio,
  }) async {
    final result = await _repo.updateUserBio(userId: userId, bio: bio);
    return result.fold((f) => f.message, (_) {
      _ref.invalidate(userProfileProvider(userId));
      _ref.invalidate(authStateProvider);
      return null;
    });
  }

  Future<String?> uploadProfilePhoto({
    required String userId,
    required File file,
  }) async {
    final result = await _repo.uploadProfileImage(userId: userId, file: file);
    return result.fold((f) => f.message, (_) {
      _ref.invalidate(userProfileProvider(userId));
      _ref.invalidate(authStateProvider);
      _ref.invalidate(feedProvider(userId));
      return null;
    });
  }

  Future<String?> markNotificationRead({
    required String userId,
    required String notificationId,
  }) async {
    final result = await _repo.markNotificationRead(
      userId: userId,
      notificationId: notificationId,
    );
    return result.fold((f) => f.message, (_) {
      _ref.invalidate(notificationsProvider(userId));
      return null;
    });
  }

  Future<String?> markAllNotificationsRead(String userId) async {
    final result = await _repo.markAllNotificationsRead(userId);
    return result.fold((f) => f.message, (_) {
      _ref.invalidate(notificationsProvider(userId));
      return null;
    });
  }

  void _invalidateSocial(String userA, String userB) {
    _ref.invalidate(followingProvider(userA));
    _ref.invalidate(followersProvider(userB));
    _ref.invalidate(followingCountProvider(userA));
    _ref.invalidate(followersCountProvider(userB));
    _ref.invalidate(pendingFollowRequestsProvider(userB));
    _ref.invalidate(feedProvider(userA));
    _ref.invalidate(
      followRelationshipProvider(
        (followerId: userA, followingId: userB),
      ),
    );
  }
}
