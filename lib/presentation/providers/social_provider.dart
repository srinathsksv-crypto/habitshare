import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/core/di/service_locator.dart';
import 'package:habitshare/domain/entities/follow_entity.dart';
import 'package:habitshare/domain/entities/habit_post_entity.dart';
import 'package:habitshare/domain/entities/post_comment_entity.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/domain/repositories/social_repository.dart';

final socialRepositoryProvider = Provider<ISocialRepository>(
  (ref) => sl<ISocialRepository>(),
);

final feedProvider = StreamProvider.family<List<HabitPostEntity>, String>((
  ref,
  viewerId,
) {
  return ref.watch(socialRepositoryProvider).watchFeed(viewerId: viewerId);
});

final postCommentsProvider = StreamProvider.family<
    List<PostCommentEntity>,
    ({String postOwnerId, String postId})>((ref, params) {
  return ref.watch(socialRepositoryProvider).watchComments(
        postOwnerId: params.postOwnerId,
        postId: params.postId,
      );
});

final followingProvider = FutureProvider.family<List<FollowEntity>, String>((
  ref,
  userId,
) async {
  final result = await ref.watch(socialRepositoryProvider).getFollowing(userId);
  return result.fold((_) => <FollowEntity>[], (list) => list);
});

final followersProvider = FutureProvider.family<List<FollowEntity>, String>((
  ref,
  userId,
) async {
  final result = await ref.watch(socialRepositoryProvider).getFollowers(userId);
  return result.fold((_) => <FollowEntity>[], (list) => list);
});

final pendingFollowRequestsProvider =
    FutureProvider.family<List<FollowEntity>, String>((ref, userId) async {
  final result = await ref
      .read(socialRepositoryProvider)
      .getPendingFollowRequests(userId);
  return result.fold((_) => <FollowEntity>[], (list) => list);
});

final followingCountProvider = FutureProvider.family<int, String>((
  ref,
  userId,
) async {
  final result = await ref.read(socialRepositoryProvider).getFollowingCount(
    userId,
  );
  return result.fold((_) => 0, (count) => count);
});

final followersCountProvider = FutureProvider.family<int, String>((
  ref,
  userId,
) async {
  final result = await ref.read(socialRepositoryProvider).getFollowersCount(
    userId,
  );
  return result.fold((_) => 0, (count) => count);
});

final userSearchProvider =
    FutureProvider.family<List<UserEntity>, ({String query, String userId})>((
  ref,
  params,
) async {
  if (params.query.trim().length < 2) {
    return [];
  }
  final result = await ref.watch(socialRepositoryProvider).searchUsers(
    query: params.query,
    currentUserId: params.userId,
  );
  return result.fold((_) => <UserEntity>[], (users) => users);
});

final followRelationshipProvider = FutureProvider.family<
    FollowEntity?,
    ({String followerId, String followingId})>((ref, params) async {
  final result = await ref.read(socialRepositoryProvider).getFollowRelationship(
    followerId: params.followerId,
    followingId: params.followingId,
  );
  return result.fold((_) => null, (entity) => entity);
});
