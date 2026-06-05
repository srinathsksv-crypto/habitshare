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

final postCommentsProvider = StreamProvider.family<List<PostCommentEntity>,
    ({String postOwnerId, String postId})>((ref, params) {
  return ref.watch(socialRepositoryProvider).watchComments(
        postOwnerId: params.postOwnerId,
        postId: params.postId,
      );
});

final followingProvider = StreamProvider.family<List<FollowEntity>, String>((
  ref,
  userId,
) {
  return ref.watch(socialRepositoryProvider).watchFollowing(userId);
});

final followersProvider = StreamProvider.family<List<FollowEntity>, String>((
  ref,
  userId,
) {
  return ref.watch(socialRepositoryProvider).watchFollowers(userId);
});

final pendingFollowRequestsProvider =
    StreamProvider.family<List<FollowEntity>, String>((ref, userId) {
  return ref.watch(socialRepositoryProvider).watchPendingFollowRequests(userId);
});

final followingCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  return ref.watch(socialRepositoryProvider).watchFollowingCount(userId);
});

final followersCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  return ref.watch(socialRepositoryProvider).watchFollowersCount(userId);
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

final followRelationshipProvider = StreamProvider.family<FollowEntity?,
    ({String followerId, String followingId})>((ref, params) {
  return ref.watch(socialRepositoryProvider).watchFollowRelationship(
        followerId: params.followerId,
        followingId: params.followingId,
      );
});

final singlePostProvider = StreamProvider.family<List<HabitPostEntity>,
    ({String postId, String postOwnerId})>((ref, params) {
  return ref
      .watch(socialRepositoryProvider)
      .watchUserPosts(
        profileUserId: params.postOwnerId,
        viewerId: params.postOwnerId,
      )
      .map((posts) => posts.where((post) => post.id == params.postId).toList());
});
