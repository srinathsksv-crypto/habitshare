import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:habitshare/config/constants/app_constants.dart';

/// Centralized Firestore paths:
/// users/{userId}
///   - profile fields on user doc
///   - habits/{habitId}
///   - posts/{postId}/likes|comments
///   - notifications/{notificationId}
///   - followers/{followerId}
///   - following/{followingId}
class FirestorePaths {
  FirestorePaths(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> user(String userId) =>
      _db.collection(AppConstants.usersCollection).doc(userId);

  CollectionReference<Map<String, dynamic>> habits(String userId) =>
      user(userId).collection(AppConstants.habitsSubcollection);

  CollectionReference<Map<String, dynamic>> habitLogs(String userId) =>
      user(userId).collection(AppConstants.habitLogsSubcollection);

  CollectionReference<Map<String, dynamic>> sharedHabits(String userId) =>
      user(userId).collection(AppConstants.sharedHabitsSubcollection);

  CollectionReference<Map<String, dynamic>> posts(String userId) =>
      user(userId).collection(AppConstants.postsSubcollection);

  DocumentReference<Map<String, dynamic>> post({
    required String userId,
    required String postId,
  }) =>
      posts(userId).doc(postId);

  CollectionReference<Map<String, dynamic>> notifications(String userId) =>
      user(userId).collection(AppConstants.notificationsSubcollection);

  CollectionReference<Map<String, dynamic>> followers(String userId) =>
      user(userId).collection(AppConstants.followersSubcollection);

  CollectionReference<Map<String, dynamic>> following(String userId) =>
      user(userId).collection(AppConstants.followingSubcollection);

  DocumentReference<Map<String, dynamic>> privateProfile(String userId) => user(
        userId,
      )
          .collection(AppConstants.privateSubcollection)
          .doc(AppConstants.privateProfileDoc);

  Query<Map<String, dynamic>> postsCollectionGroup() =>
      _db.collectionGroup(AppConstants.postsSubcollection);

  static String? readImageUrl(Map<String, dynamic>? data) {
    if (data == null) return null;
    return data['image_url'] as String? ?? data['photo_url'] as String?;
  }
}
