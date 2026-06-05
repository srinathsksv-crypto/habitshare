import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:habitshare/config/constants/app_constants.dart';
import 'package:habitshare/core/errors/exceptions.dart';
import 'package:habitshare/core/logger/app_logger.dart';
import 'package:habitshare/core/utils/firestore_parse_utils.dart';
import 'package:habitshare/data/models/habit_log_model.dart';
import 'package:habitshare/data/models/habit_model.dart';
import 'package:habitshare/data/models/notification_model.dart';
import 'package:habitshare/data/datasources/remote/firestore_paths.dart';
import 'package:habitshare/data/models/shared_habit_model.dart';
import 'package:habitshare/domain/entities/follow_entity.dart';
import 'package:habitshare/domain/entities/habit_entity.dart';
import 'package:habitshare/domain/entities/habit_post_entity.dart';
import 'package:habitshare/domain/entities/notification_entity.dart';
import 'package:habitshare/domain/entities/post_comment_entity.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/domain/services/habit_streak_service.dart';
import 'package:habitshare/domain/services/push_notification_service.dart';

class FirestoreDataSource {
  FirestoreDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    PushNotificationService? pushService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _pushService = pushService;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final PushNotificationService? _pushService;
  late final FirestorePaths _paths = FirestorePaths(_firestore);

  String _requireAuthUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw const AuthException('You must be signed in to perform this action');
    }
    return uid;
  }

  HabitModel _habitFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    String? ownerUserId,
  }) {
    final data = doc.data();
    return HabitModel(
      id: doc.id,
      userId: data['user_id'] as String? ?? ownerUserId ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      categoryId: data['category_id'] as String?,
      colorHex: data['color_hex'] as String? ?? '#6750A4',
      frequency: data['frequency'] as String? ?? 'daily',
      targetPerPeriod: (data['target_per_period'] as num?)?.toInt() ?? 1,
      isArchived: data['is_archived'] as bool? ?? false,
      status: data['status'] as String? ?? 'active',
      startDate: FirestoreParseUtils.parseDateTimeOrNull(data['start_date']),
      endDate: FirestoreParseUtils.parseDateTimeOrNull(data['end_date']),
      streakCount: (data['streak_count'] as num?)?.toInt() ?? 0,
      lastCompletedAt:
          FirestoreParseUtils.parseDateTimeOrNull(data['last_completed_at']),
      lastCompletedWindowIndex:
          (data['last_completed_window_index'] as num?)?.toInt() ?? 0,
      createdAt: FirestoreParseUtils.parseDateTime(data['created_at']),
      updatedAt: FirestoreParseUtils.parseDateTimeOrNull(data['updated_at']),
    );
  }

  List<HabitModel> _sortHabits(List<HabitModel> habits) {
    final sorted = List<HabitModel>.from(habits)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  Stream<List<HabitModel>> watchHabits(String userId) {
    return _paths.habits(userId).snapshots().map(
          (snapshot) => _sortHabits(
            snapshot.docs
                .map((doc) => _habitFromDoc(doc, ownerUserId: userId))
                .toList(),
          ),
        );
  }

  Future<List<HabitModel>> getHabits(String userId) async {
    try {
      final snapshot = await _paths.habits(userId).get();
      return _sortHabits(
        snapshot.docs
            .map((doc) => _habitFromDoc(doc, ownerUserId: userId))
            .toList(),
      );
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch habits',
        code: e.code,
      );
    }
  }

  Future<HabitModel> createHabit(HabitModel habit) async {
    try {
      final collection = _paths.habits(habit.userId);
      final doc =
          habit.id.isEmpty ? collection.doc() : collection.doc(habit.id);
      final data = habit.copyWith(id: doc.id).toJson()
        ..remove('id')
        ..['user_id'] = habit.userId;
      await doc.set(data);
      return habit.copyWith(id: doc.id);
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to create habit',
        code: e.code,
      );
    }
  }

  Future<HabitModel> updateHabit(HabitModel habit) async {
    try {
      final data = habit.toJson()
        ..remove('id')
        ..['updated_at'] = DateTime.now().toIso8601String();
      await _paths.habits(habit.userId).doc(habit.id).update(data);
      return habit.copyWith(updatedAt: DateTime.now());
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to update habit',
        code: e.code,
      );
    }
  }

  Future<HabitModel> completeHabit({
    required String userId,
    required String habitId,
  }) async {
    try {
      final habitRef = _paths.habits(userId).doc(habitId);
      final habitDoc = await habitRef.get();
      final habitData = habitDoc.data();

      if (habitData == null) {
        throw ServerException('Habit not found');
      }

      // Manually create HabitModel from document data
      final habitModel = HabitModel(
        id: habitDoc.id,
        userId: habitData['user_id'] as String? ?? userId,
        title: habitData['title'] as String? ?? '',
        description: habitData['description'] as String?,
        categoryId: habitData['category_id'] as String?,
        colorHex: habitData['color_hex'] as String? ?? '#6750A4',
        frequency: habitData['frequency'] as String? ?? 'daily',
        targetPerPeriod: (habitData['target_per_period'] as num?)?.toInt() ?? 1,
        isArchived: habitData['is_archived'] as bool? ?? false,
        status: habitData['status'] as String? ?? 'active',
        startDate:
            FirestoreParseUtils.parseDateTimeOrNull(habitData['start_date']),
        endDate: FirestoreParseUtils.parseDateTimeOrNull(habitData['end_date']),
        streakCount: (habitData['streak_count'] as num?)?.toInt() ?? 0,
        lastCompletedAt: FirestoreParseUtils.parseDateTimeOrNull(
            habitData['last_completed_at']),
        lastCompletedWindowIndex:
            (habitData['last_completed_window_index'] as num?)?.toInt() ?? 0,
        createdAt: FirestoreParseUtils.parseDateTime(habitData['created_at']),
        updatedAt:
            FirestoreParseUtils.parseDateTimeOrNull(habitData['updated_at']),
      );

      final habitEntity = habitModel.toEntity();
      final now = DateTime.now();

      // Check if habit can be completed
      if (!HabitStreakService.canCompleteHabit(habitEntity, now)) {
        throw ServerException('Habit already completed for this period');
      }

      // Calculate new streak
      final newStreak = HabitStreakService.calculateNewStreak(habitEntity, now);
      final today = DateTime(now.year, now.month, now.day);

      // Update habit with completion data
      final updateData = <String, dynamic>{
        'streak_count': newStreak,
        'last_completed_at': today.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (habitEntity.frequency == HabitFrequency.weekly) {
        final currentWindowIndex = HabitStreakService.getCurrentWindowIndex(
          habitEntity.createdAt,
          now,
        );
        updateData['last_completed_window_index'] = currentWindowIndex;
      }

      await habitRef.update(updateData);

      // Return updated habit
      final updatedDoc = await habitRef.get();
      final updatedData = updatedDoc.data()!;
      return HabitModel(
        id: updatedDoc.id,
        userId: updatedData['user_id'] as String? ?? userId,
        title: updatedData['title'] as String? ?? '',
        description: updatedData['description'] as String?,
        categoryId: updatedData['category_id'] as String?,
        colorHex: updatedData['color_hex'] as String? ?? '#6750A4',
        frequency: updatedData['frequency'] as String? ?? 'daily',
        targetPerPeriod:
            (updatedData['target_per_period'] as num?)?.toInt() ?? 1,
        isArchived: updatedData['is_archived'] as bool? ?? false,
        status: updatedData['status'] as String? ?? 'active',
        startDate:
            FirestoreParseUtils.parseDateTimeOrNull(updatedData['start_date']),
        endDate:
            FirestoreParseUtils.parseDateTimeOrNull(updatedData['end_date']),
        streakCount: (updatedData['streak_count'] as num?)?.toInt() ?? 0,
        lastCompletedAt: FirestoreParseUtils.parseDateTimeOrNull(
            updatedData['last_completed_at']),
        lastCompletedWindowIndex:
            (updatedData['last_completed_window_index'] as num?)?.toInt() ?? 0,
        createdAt: FirestoreParseUtils.parseDateTime(updatedData['created_at']),
        updatedAt:
            FirestoreParseUtils.parseDateTimeOrNull(updatedData['updated_at']),
      );
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to complete habit',
        code: e.code,
      );
    }
  }

  Future<void> deleteHabit({
    required String userId,
    required String habitId,
  }) async {
    try {
      final batch = _firestore.batch();

      // Delete the habit
      final habitRef = _paths.habits(userId).doc(habitId);
      batch.delete(habitRef);

      // Delete related posts
      final postsSnapshot = await _paths
          .posts(userId)
          .where('habit_id', isEqualTo: habitId)
          .get();
      for (final doc in postsSnapshot.docs) {
        batch.delete(doc.reference);
        // Note: cloud functions or a recursive delete might be better if posts have subcollections (likes/comments),
        // but batch deleting the document itself will hide it from the feed.
      }

      // Delete related habit logs
      final logsSnapshot = await _paths
          .habitLogs(userId)
          .where('habit_id', isEqualTo: habitId)
          .get();
      for (final doc in logsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to delete habit',
        code: e.code,
      );
    }
  }

  Stream<List<HabitLogModel>> watchHabitLogs(String habitId, String userId) {
    return _paths
        .habitLogs(userId)
        .where('habit_id', isEqualTo: habitId)
        .orderBy('logged_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => HabitLogModel.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }

  Future<List<HabitLogModel>> getHabitLogs(
      String habitId, String userId) async {
    try {
      final snapshot = await _paths
          .habitLogs(userId)
          .where('habit_id', isEqualTo: habitId)
          .orderBy('logged_at', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => HabitLogModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to fetch logs', code: e.code);
    }
  }

  Future<HabitLogModel> createHabitLog(HabitLogModel log) async {
    try {
      final collection = _paths.habitLogs(log.userId);
      final doc = log.id.isEmpty ? collection.doc() : collection.doc(log.id);
      final data = log.copyWith(id: doc.id).toJson()..remove('id');
      await doc.set(data);
      return log.copyWith(id: doc.id);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to log habit', code: e.code);
    }
  }

  Future<SharedHabitModel> shareHabit(SharedHabitModel shared) async {
    try {
      final collection = _paths.sharedHabits(shared.sharedWithUserId);
      final doc = collection.doc();
      final data = shared.copyWith(id: doc.id).toJson()..remove('id');
      await doc.set(data);
      return shared.copyWith(id: doc.id);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to share habit', code: e.code);
    }
  }

  Future<List<SharedHabitModel>> getSharedHabits(String userId) async {
    try {
      final snapshot = await _paths
          .sharedHabits(userId)
          .orderBy('shared_at', descending: true)
          .get();
      return snapshot.docs
          .map(
            (doc) => SharedHabitModel.fromJson({...doc.data(), 'id': doc.id}),
          )
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch shared habits',
        code: e.code,
      );
    }
  }

  Stream<List<SharedHabitModel>> watchSharedHabits(String userId) {
    return _paths
        .sharedHabits(userId)
        .orderBy('shared_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => SharedHabitModel.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                }),
              )
              .toList(),
        );
  }

  Future<void> upsertUserProfile(UserEntity user) async {
    try {
      final data = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        data['display_name'] = user.displayName;
      }
      if (user.bio != null) {
        data['bio'] = user.bio;
      }
      // Never overwrite a custom uploaded image with null/empty auth photo.
      if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
        data['image_url'] = user.photoUrl;
        data['photo_url'] = user.photoUrl;
      }
      await _paths.user(user.id).set(data, SetOptions(merge: true));
      await _paths.privateProfile(user.id).set(
        {
          'email': user.email,
          'updated_at': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to save profile',
        code: e.code,
      );
    }
  }

  Future<UserEntity?> getUserProfile(String userId) async {
    try {
      final doc = await _paths.user(userId).get();
      if (!doc.exists) {
        return null;
      }
      final data = doc.data()!;
      var email = '';
      if (_auth.currentUser?.uid == userId) {
        final privateDoc = await _paths.privateProfile(userId).get();
        email = privateDoc.data()?['email'] as String? ?? '';
      }
      return UserEntity(
        id: doc.id,
        email: email,
        displayName: data['display_name'] as String?,
        photoUrl: FirestorePaths.readImageUrl(data),
        bio: data['bio'] as String?,
      );
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to load profile',
        code: e.code,
      );
    }
  }

  Future<void> updateUserBio({
    required String userId,
    required String bio,
  }) async {
    try {
      await _paths.user(userId).set(
        {
          'bio': bio.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to update bio',
        code: e.code,
      );
    }
  }

  Future<void> updateUserPhotoUrl({
    required String userId,
    required String photoUrl,
  }) async {
    try {
      await _paths.user(userId).set(
        {
          'image_url': photoUrl,
          'photo_url': photoUrl,
          'updated_at': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to update photo',
        code: e.code,
      );
    }
  }

  Future<void> updateProfilePhotoInPosts({
    required String userId,
    required String newPhotoUrl,
  }) async {
    try {
      final postsSnapshot = await _paths.posts(userId).get();
      final batch = _firestore.batch();
      for (final doc in postsSnapshot.docs) {
        batch.update(doc.reference, {
          'author_photo_url': newPhotoUrl,
          'author_image_url': newPhotoUrl,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      // Also update notifications that reference this user's photo
      final notificationsSnapshot = await _paths
          .notificationsCollectionGroup()
          .where('sender_id', isEqualTo: userId)
          .get();
      for (final doc in notificationsSnapshot.docs) {
        batch.update(doc.reference, {
          'sender_photo_url': newPhotoUrl,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to update posts with new photo',
        code: e.code,
      );
    }
  }

  Future<List<UserEntity>> searchUsers({
    required String query,
    required String currentUserId,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }
      final lower = query.trim().toLowerCase();
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .limit(50)
          .get();
      return snapshot.docs.where((doc) => doc.id != currentUserId).map((doc) {
        final data = doc.data();
        return UserEntity(
          id: doc.id,
          email: '',
          displayName: data['display_name'] as String?,
          photoUrl: FirestorePaths.readImageUrl(data),
          bio: data['bio'] as String?,
        );
      }).where((user) {
        final name = user.name.toLowerCase();
        return name.contains(lower);
      }).toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to search users',
        code: e.code,
      );
    }
  }

  Future<HabitPostEntity> createPost({
    required String userId,
    required String habitId,
    required String title,
    String? description,
    String? message,
    String? authorName,
    String? authorPhotoUrl,
    dynamic imageFile,
  }) async {
    try {
      final authUid = _requireAuthUid();
      if (authUid != userId) {
        throw const AuthException(
            'Authenticated user mismatch while creating post');
      }
      final doc = _paths.posts(userId).doc();
      final createdAt = DateTime.now();

      String? uploadedImageUrl;
      if (imageFile != null && imageFile is File) {
        final ext = imageFile.path.split('.').last;
        final ref = _storage.ref().child('posts/${doc.id}.$ext');
        await ref.putFile(imageFile);
        uploadedImageUrl = await ref.getDownloadURL();
      }

      final data = {
        'user_id': userId,
        'habit_id': habitId,
        'title': title,
        'description': description,
        'message': message,
        'author_name': authorName,
        'author_photo_url': authorPhotoUrl,
        'author_image_url': authorPhotoUrl,
        'image_url': uploadedImageUrl,
        'created_at': createdAt.toIso8601String(),
        'like_count': 0,
        'comment_count': 0,
      };
      await doc.set(data);
      AppLogger.info('Post created: ${doc.id} for user $userId');
      final post = HabitPostEntity(
        id: doc.id,
        userId: userId,
        habitId: habitId,
        title: title,
        description: description,
        message: message,
        createdAt: createdAt,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
        imageUrl: uploadedImageUrl,
      );
      await _notifyFollowersOfNewPost(
        authorId: userId,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
        postId: doc.id,
      );
      return post;
    } on FirebaseException catch (e, stack) {
      AppLogger.error('createPost failed', e, stack);
      throw ServerException(e.message ?? 'Failed to create post', code: e.code);
    }
  }

  Stream<List<HabitPostEntity>> watchFeed({required String viewerId}) {
    return _watchPostsForViewer(
      viewerId: viewerId,
      profileUserId: null,
    );
  }

  Stream<List<HabitPostEntity>> watchUserPosts({
    required String profileUserId,
    required String viewerId,
  }) {
    return _watchPostsForViewer(
      viewerId: viewerId,
      profileUserId: profileUserId,
    );
  }

  Stream<List<HabitPostEntity>> _watchPostsForViewer({
    required String viewerId,
    String? profileUserId,
  }) {
    return _paths
        .postsCollectionGroup()
        .orderBy('created_at', descending: true)
        .limit(100)
        .snapshots()
        .asyncMap((postSnapshot) async {
      try {
        final visibleUserIds = await _visibleUserIdsForViewer(
          viewerId: viewerId,
          profileUserId: profileUserId,
        );
        if (visibleUserIds.isEmpty) {
          return <HabitPostEntity>[];
        }

        final postFutures = postSnapshot.docs
            .where((doc) => visibleUserIds.contains(doc.data()['user_id']))
            .map((doc) => _postFromDoc(doc, viewerId: viewerId));
        final currentPosts = await Future.wait(postFutures);

        AppLogger.debug(
            'Feed: fetched ${currentPosts.length} posts for viewer $viewerId');
        return currentPosts;
      } catch (e, stack) {
        AppLogger.error('Feed error: failed to fetch posts', e, stack);
        return <HabitPostEntity>[];
      }
    });
  }

  Future<Set<String>> _visibleUserIdsForViewer({
    required String viewerId,
    String? profileUserId,
  }) async {
    if (profileUserId != null) {
      if (profileUserId == viewerId) {
        return {viewerId};
      }
      final canView = await _hasAcceptedFollow(
        followerId: viewerId,
        followingId: profileUserId,
      );
      return canView ? {profileUserId} : {};
    }

    final followingSnapshot = await _paths.following(viewerId).get();
    final acceptedFollowing = followingSnapshot.docs.where((doc) {
      final status = doc.data()['status'] as String?;
      return status == null || status == AppConstants.followStatusAccepted;
    });

    return {
      viewerId,
      ...acceptedFollowing.map((doc) => doc.id),
    };
  }

  Future<bool> canViewUserPosts({
    required String profileUserId,
    required String viewerId,
  }) async {
    if (profileUserId == viewerId) {
      return true;
    }
    return _hasAcceptedFollow(
      followerId: viewerId,
      followingId: profileUserId,
    );
  }

  Future<bool> _hasAcceptedFollow({
    required String followerId,
    required String followingId,
  }) async {
    final doc = await _paths.following(followerId).doc(followingId).get();
    if (!doc.exists) {
      return false;
    }
    final status = doc.data()?['status'] as String?;
    return status == null || status == AppConstants.followStatusAccepted;
  }

  Future<HabitPostEntity> _postFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required String viewerId,
  }) async {
    final data = doc.data();
    final likeDoc = await doc.reference
        .collection(AppConstants.likesSubcollection)
        .doc(viewerId)
        .get();

    final authorId = data['user_id'] as String? ?? '';
    final postAuthorName = data['author_name'] as String?;
    final postAuthorPhotoUrl = data['author_photo_url'] as String? ??
        data['author_image_url'] as String?;
    var authorName = postAuthorName;
    var authorPhotoUrl = postAuthorPhotoUrl;

    if (authorId.isNotEmpty && (authorName == null || authorPhotoUrl == null)) {
      final userDoc = await _paths.user(authorId).get();
      final userData = userDoc.data();
      authorName ??= userData?['display_name'] as String?;
      authorPhotoUrl ??= FirestorePaths.readImageUrl(userData);
    }

    return HabitPostEntity(
      id: doc.id,
      userId: data['user_id'] as String,
      habitId: data['habit_id'] as String,
      title: data['title'] as String,
      description: data['description'] as String?,
      message: data['message'] as String?,
      createdAt: FirestoreParseUtils.parseDateTime(data['created_at']),
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      imageUrl: data['image_url'] as String?,
      likeCount: (data['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (data['comment_count'] as num?)?.toInt() ?? 0,
      isLikedByCurrentUser: likeDoc.exists,
    );
  }

  Future<void> toggleLike({
    required String postOwnerId,
    required String postId,
    required String userId,
    String? likerName,
    String? likerPhotoUrl,
  }) async {
    try {
      final authUid = _requireAuthUid();
      if (authUid != userId) {
        throw const AuthException(
            'Authenticated user mismatch while toggling like');
      }
      final postRef = _paths.post(userId: postOwnerId, postId: postId);
      final likeRef =
          postRef.collection(AppConstants.likesSubcollection).doc(userId);
      var addedLike = false;

      await _firestore.runTransaction((transaction) async {
        final postSnap = await transaction.get(postRef);
        if (!postSnap.exists) {
          throw const ServerException('Post not found');
        }
        final likeSnap = await transaction.get(likeRef);
        if (likeSnap.exists) {
          transaction.delete(likeRef);
          transaction.update(postRef, {
            'like_count': FieldValue.increment(-1),
          });
        } else {
          addedLike = true;
          transaction.set(likeRef, {
            'user_id': userId,
            'created_at': DateTime.now().toIso8601String(),
          });
          transaction.update(postRef, {
            'like_count': FieldValue.increment(1),
          });
        }
      });

      if (addedLike && postOwnerId != userId) {
        await _createNotificationIfNew(
          receiverId: postOwnerId,
          type: NotificationType.like,
          senderId: userId,
          senderName: likerName,
          senderPhotoUrl: likerPhotoUrl,
          postId: postId,
        );
      }
    } on FirebaseException catch (e, stack) {
      AppLogger.error('toggleLike failed for post $postId', e, stack);
      throw ServerException(e.message ?? 'Failed to toggle like', code: e.code);
    }
  }

  Stream<List<PostCommentEntity>> watchComments({
    required String postOwnerId,
    required String postId,
  }) {
    return _paths
        .post(userId: postOwnerId, postId: postId)
        .collection(AppConstants.commentsSubcollection)
        .orderBy('created_at', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return PostCommentEntity(
              id: doc.id,
              postId: postId,
              userId: data['user_id'] as String,
              text: data['text'] as String,
              createdAt: FirestoreParseUtils.parseDateTime(data['created_at']),
              authorName: data['author_name'] as String?,
              authorPhotoUrl: data['author_photo_url'] as String? ??
                  data['author_image_url'] as String?,
            );
          }).toList(),
        );
  }

  Future<PostCommentEntity> addComment({
    required String postOwnerId,
    required String postId,
    required String userId,
    required String text,
    String? authorName,
    String? authorPhotoUrl,
  }) async {
    try {
      final authUid = _requireAuthUid();
      if (authUid != userId) {
        throw const AuthException(
            'Authenticated user mismatch while adding comment');
      }
      final postRef = _paths.post(userId: postOwnerId, postId: postId);
      final commentRef =
          postRef.collection(AppConstants.commentsSubcollection).doc();
      final createdAt = DateTime.now();

      await _firestore.runTransaction((transaction) async {
        transaction.set(commentRef, {
          'user_id': userId,
          'text': text,
          'author_name': authorName,
          'author_photo_url': authorPhotoUrl,
          'author_image_url': authorPhotoUrl,
          'created_at': createdAt.toIso8601String(),
        });
        transaction.update(postRef, {
          'comment_count': FieldValue.increment(1),
        });
      });

      if (postOwnerId != userId) {
        await _createNotificationIfNew(
          receiverId: postOwnerId,
          type: NotificationType.comment,
          senderId: userId,
          senderName: authorName,
          senderPhotoUrl: authorPhotoUrl,
          postId: postId,
        );
      }

      return PostCommentEntity(
        id: commentRef.id,
        postId: postId,
        userId: userId,
        text: text,
        createdAt: createdAt,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
      );
    } on FirebaseException catch (e, stack) {
      AppLogger.error('addComment failed for post $postId', e, stack);
      throw ServerException(e.message ?? 'Failed to add comment', code: e.code);
    }
  }

  Future<void> sendFollowRequest({
    required String followerId,
    required String followingId,
  }) async {
    try {
      final authUid = _requireAuthUid();
      if (authUid != followerId) {
        throw const AuthException(
            'Authenticated user mismatch while sending follow request');
      }
      final existing =
          await _paths.following(followerId).doc(followingId).get();
      if (existing.exists) {
        return;
      }
      final payload = {
        'follower_id': followerId,
        'following_id': followingId,
        'status': AppConstants.followStatusPending,
        'created_at': DateTime.now().toIso8601String(),
      };
      await _paths.followers(followingId).doc(followerId).set(payload);
      await _paths.following(followerId).doc(followingId).set(payload);
      final followerDoc = await _paths.user(followerId).get();
      final followerData = followerDoc.data();
      await _createNotificationIfNew(
        receiverId: followingId,
        type: NotificationType.followRequest,
        senderId: followerId,
        senderName: followerData?['display_name'] as String?,
        senderPhotoUrl: FirestorePaths.readImageUrl(followerData),
      );
    } on FirebaseException catch (e, stack) {
      AppLogger.error(
          'sendFollowRequest failed: $followerId -> $followingId', e, stack);
      throw ServerException(
        e.message ?? 'Failed to send follow request',
        code: e.code,
      );
    }
  }

  Future<void> acceptFollowRequest({
    required String followerId,
    required String followingId,
    String? followingName,
    String? followingPhotoUrl,
  }) async {
    try {
      final authUid = _requireAuthUid();
      if (authUid != followingId) {
        throw const AuthException(
            'Authenticated user mismatch while accepting request');
      }
      final update = {
        'status': AppConstants.followStatusAccepted,
        'accepted_at': DateTime.now().toIso8601String(),
      };
      await _paths.followers(followingId).doc(followerId).update(update);
      await _paths.following(followerId).doc(followingId).update(update);
      await _createNotificationIfNew(
        receiverId: followerId,
        type: NotificationType.followAccepted,
        senderId: followingId,
        senderName: followingName,
        senderPhotoUrl: followingPhotoUrl,
      );
    } on FirebaseException catch (e, stack) {
      AppLogger.error('acceptFollowRequest failed', e, stack);
      throw ServerException(
        e.message ?? 'Failed to accept request',
        code: e.code,
      );
    }
  }

  Future<void> rejectFollowRequest({
    required String followerId,
    required String followingId,
  }) async {
    try {
      final authUid = _requireAuthUid();
      if (authUid != followingId && authUid != followerId) {
        throw const AuthException(
            'Authenticated user mismatch while rejecting request');
      }
      await _paths.followers(followingId).doc(followerId).delete();
      await _paths.following(followerId).doc(followingId).delete();
    } on FirebaseException catch (e, stack) {
      AppLogger.error('rejectFollowRequest failed', e, stack);
      throw ServerException(
        e.message ?? 'Failed to reject request',
        code: e.code,
      );
    }
  }

  Future<void> unfollowUser({
    required String followerId,
    required String followingId,
  }) async {
    try {
      await _paths.followers(followingId).doc(followerId).delete();
      await _paths.following(followerId).doc(followingId).delete();
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to unfollow user',
        code: e.code,
      );
    }
  }

  Future<List<FollowEntity>> getFollowing(String userId) async {
    try {
      final snapshot = await _paths.following(userId).get();
      final docs = snapshot.docs.where((doc) {
        final status = doc.data()['status'] as String?;
        return status == null || status == AppConstants.followStatusAccepted;
      }).toList();
      return _mapFollowDocs(
        docs,
        ownerUserId: userId,
        isFollowingList: true,
      );
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to load following',
        code: e.code,
      );
    }
  }

  Stream<List<FollowEntity>> watchFollowing(String userId) {
    return _paths
        .following(userId)
        .snapshots()
        .asyncMap((snapshot) {
          final docs = snapshot.docs.where((doc) {
            final status = doc.data()['status'] as String?;
            return status == null || status == AppConstants.followStatusAccepted;
          }).toList();
          return _mapFollowDocs(
            docs,
            ownerUserId: userId,
            isFollowingList: true,
          );
        });
  }

  Future<List<FollowEntity>> getFollowers(String userId) async {
    try {
      final snapshot = await _paths.followers(userId).get();
      final docs = snapshot.docs.where((doc) {
        final status = doc.data()['status'] as String?;
        return status == null || status == AppConstants.followStatusAccepted;
      }).toList();
      return _mapFollowDocs(
        docs,
        ownerUserId: userId,
        isFollowingList: false,
      );
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to load followers',
        code: e.code,
      );
    }
  }

  Stream<List<FollowEntity>> watchFollowers(String userId) {
    return _paths
        .followers(userId)
        .snapshots()
        .asyncMap((snapshot) {
          final docs = snapshot.docs.where((doc) {
            final status = doc.data()['status'] as String?;
            return status == null || status == AppConstants.followStatusAccepted;
          }).toList();
          return _mapFollowDocs(
            docs,
            ownerUserId: userId,
            isFollowingList: false,
          );
        });
  }

  Future<List<FollowEntity>> getPendingFollowRequests(String userId) async {
    try {
      final snapshot = await _paths
          .followers(userId)
          .where('status', isEqualTo: AppConstants.followStatusPending)
          .get();
      return _mapFollowDocs(
        snapshot.docs,
        ownerUserId: userId,
        isFollowingList: false,
      );
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to load requests',
        code: e.code,
      );
    }
  }

  Stream<List<FollowEntity>> watchPendingFollowRequests(String userId) {
    return _paths
        .followers(userId)
        .where('status', isEqualTo: AppConstants.followStatusPending)
        .snapshots()
        .asyncMap((snapshot) => _mapFollowDocs(
              snapshot.docs,
              ownerUserId: userId,
              isFollowingList: false,
            ));
  }

  Future<int> getFollowingCount(String userId) async {
    final list = await getFollowing(userId);
    return list.length;
  }

  Stream<int> watchFollowingCount(String userId) {
    return watchFollowing(userId).map((list) => list.length);
  }

  Future<int> getFollowersCount(String userId) async {
    final list = await getFollowers(userId);
    return list.length;
  }

  Stream<int> watchFollowersCount(String userId) {
    return watchFollowers(userId).map((list) => list.length);
  }

  Future<FollowEntity?> getFollowRelationship({
    required String followerId,
    required String followingId,
  }) async {
    try {
      final doc = await _paths.following(followerId).doc(followingId).get();
      if (!doc.exists) {
        return null;
      }
      final mapped = await _mapFollowDocs(
        [doc],
        ownerUserId: followerId,
        isFollowingList: true,
      );
      return mapped.first;
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to load relationship',
        code: e.code,
      );
    }
  }

  Stream<FollowEntity?> watchFollowRelationship({
    required String followerId,
    required String followingId,
  }) {
    return _paths
        .following(followerId)
        .doc(followingId)
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists) {
        return null;
      }
      final mapped = await _mapFollowDocs(
        [doc],
        ownerUserId: followerId,
        isFollowingList: true,
      );
      return mapped.first;
    });
  }

  FollowStatus _parseFollowStatus(String? value) {
    if (value == AppConstants.followStatusPending) {
      return FollowStatus.pending;
    }
    return FollowStatus.accepted;
  }

  Future<List<FollowEntity>> _mapFollowDocs(
    List<DocumentSnapshot<Map<String, dynamic>>> docs, {
    required String ownerUserId,
    required bool isFollowingList,
  }) async {
    final results = <FollowEntity>[];
    for (final doc in docs) {
      final data = doc.data() ?? {};
      final followerId = data['follower_id'] as String? ??
          (isFollowingList ? ownerUserId : doc.id);
      final followingId = data['following_id'] as String? ??
          (isFollowingList ? doc.id : ownerUserId);
      final targetId = isFollowingList ? followingId : followerId;
      final userDoc = await _paths.user(targetId).get();
      final userData = userDoc.data();
      results.add(
        FollowEntity(
          id: doc.id,
          followerId: followerId,
          followingId: followingId,
          createdAt: FirestoreParseUtils.parseDateTime(data['created_at']),
          status: _parseFollowStatus(data['status'] as String?),
          followingName:
              isFollowingList ? (userData?['display_name'] as String?) : null,
          followingEmail: null,
          followingPhotoUrl:
              isFollowingList ? FirestorePaths.readImageUrl(userData) : null,
          followerName:
              !isFollowingList ? (userData?['display_name'] as String?) : null,
          followerEmail: null,
          followerPhotoUrl:
              !isFollowingList ? FirestorePaths.readImageUrl(userData) : null,
        ),
      );
    }
    return results;
  }

  NotificationEntity _notificationFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required String receiverId,
  }) {
    final data = doc.data();
    return NotificationModel(
      id: doc.id,
      receiverId: receiverId,
      type: data['type'] as String? ?? NotificationType.newPost.name,
      senderId: data['sender_id'] as String?,
      senderName: data['sender_name'] as String?,
      senderPhotoUrl: data['sender_photo_url'] as String?,
      postId: data['post_id'] as String?,
      isRead: data['is_read'] as bool? ?? false,
      createdAt: FirestoreParseUtils.parseDateTime(data['created_at']),
    ).toEntity();
  }

  Stream<List<NotificationEntity>> watchNotifications(String userId) {
    return _paths.notifications(userId).snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => _notificationFromDoc(doc, receiverId: userId))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Future<void> markNotificationRead({
    required String userId,
    required String notificationId,
  }) async {
    try {
      await _paths
          .notifications(userId)
          .doc(notificationId)
          .update({'is_read': true});
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to mark notification read',
        code: e.code,
      );
    }
  }

  Future<void> markAllNotificationsRead(String userId) async {
    try {
      final snapshot = await _paths
          .notifications(userId)
          .where('is_read', isEqualTo: false)
          .get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'is_read': true});
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to mark notifications read',
        code: e.code,
      );
    }
  }

  Future<void> _createNotificationIfNew({
    required String receiverId,
    required NotificationType type,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? postId,
  }) async {
    print('=== CREATING NOTIFICATION ===');
    print('Receiver ID: $receiverId');
    print('Type: ${type.name}');
    print('Sender ID: $senderId');
    print('Sender Name: $senderName');
    print('Post ID: $postId');

    if (receiverId.isEmpty) {
      print('ERROR: Receiver ID is empty');
      print('=== NOTIFICATION CREATION FAILED ===');
      return;
    }

    // IMPORTANT:
    // Your Firestore rules prevent reading notifications belonging to other users.
    // So we must NOT query existing notifications for dedupe purposes.
    //
    // Instead, we create a deterministic document id (hour bucket) and use `.create()`
    // so duplicates become a harmless "already-exists" error.
    final nowUtc = DateTime.now().toUtc();
    final hourBucketMillis = DateTime.utc(
      nowUtc.year,
      nowUtc.month,
      nowUtc.day,
      nowUtc.hour,
    ).millisecondsSinceEpoch;

    final docId =
        '${receiverId}_${type.name}_${senderId ?? 'anon'}_${postId ?? 'none'}_$hourBucketMillis';

    try {
      print('Saving notification to Firestore...');
      // Use merge:true so re-sending the same notification doesn't wipe receiver state.
      // We intentionally omit `is_read` so if the receiver has already opened it,
      // we don't reset the read flag on duplicates.
      await _paths.notifications(receiverId).doc(docId).set(
        {
          'type': type.name,
          'sender_id': senderId,
          'sender_name': senderName,
          'sender_photo_url': senderPhotoUrl,
          'post_id': postId,
          'created_at': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
      print('Notification saved to Firestore successfully');

      // Send push notification if service is available
      if (_pushService != null) {
        print(
            'Push notification service available, sending notification for type: ${type.name}');
        final title = _getNotificationTitle(type, senderName);
        final body = _getNotificationBody(type, senderName);
        print('Notification title: $title, body: $body');
        await _pushService.sendPushNotification(
          userId: receiverId,
          title: title,
          body: body,
          data: {
            'type': type.name,
            'receiver_id': receiverId,
            'sender_id': senderId,
            'sender_name': senderName,
            'post_id': postId,
          },
        );
      } else {
        print('ERROR: Push notification service not available');
      }
      print('=== NOTIFICATION CREATION COMPLETE ===');
    } on FirebaseException catch (e) {
      print('=== NOTIFICATION CREATION ERROR ===');
      print('Error: ${e.message}');
      print('Code: ${e.code}');
      AppLogger.warning('Notification create skipped: ${e.message}');
    }
  }

  String _getNotificationTitle(NotificationType type, String? senderName) {
    final name = senderName ?? 'Someone';
    switch (type) {
      case NotificationType.like:
        return '$name liked your post';
      case NotificationType.comment:
        return '$name commented on your post';
      case NotificationType.followRequest:
        return '$name sent you a follow request';
      case NotificationType.followAccepted:
        return '$name accepted your follow request';
      case NotificationType.newPost:
        return '$name posted a new habit';
    }
  }

  String _getNotificationBody(NotificationType type, String? senderName) {
    final name = senderName ?? 'Someone';
    switch (type) {
      case NotificationType.like:
        return 'Tap to see the post';
      case NotificationType.comment:
        return 'Tap to read the comment';
      case NotificationType.followRequest:
        return 'Tap to accept or decline';
      case NotificationType.followAccepted:
        return 'You can now see $name\'s habits';
      case NotificationType.newPost:
        return 'Tap to see what $name shared';
    }
  }

  Future<void> _notifyFollowersOfNewPost({
    required String authorId,
    required String? authorName,
    required String? authorPhotoUrl,
    required String postId,
  }) async {
    try {
      final followersSnapshot = await _paths
          .followers(authorId)
          .where('status', isEqualTo: AppConstants.followStatusAccepted)
          .get();
      for (final doc in followersSnapshot.docs) {
        final followerId = doc.id;
        if (followerId == authorId) {
          continue;
        }
        await _createNotificationIfNew(
          receiverId: followerId,
          type: NotificationType.newPost,
          senderId: authorId,
          senderName: authorName,
          senderPhotoUrl: authorPhotoUrl,
          postId: postId,
        );
      }
    } on FirebaseException catch (e) {
      AppLogger.warning('Follower notifications skipped: ${e.message}');
    }
  }

  Future<void> saveFCMToken({
    required String userId,
    required String token,
  }) async {
    try {
      await _paths.user(userId).collection('fcm_tokens').doc(token).set({
        'token': token,
        'created_at': DateTime.now().toIso8601String(),
        'platform': 'unknown',
      });
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to save FCM token',
        code: e.code,
      );
    }
  }

  Future<void> deleteFCMToken({
    required String userId,
    required String token,
  }) async {
    try {
      await _paths.user(userId).collection('fcm_tokens').doc(token).delete();
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to delete FCM token',
        code: e.code,
      );
    }
  }

  Future<Map<String, bool>> getNotificationSettings(String userId) async {
    try {
      final doc = await _paths
          .user(userId)
          .collection('settings')
          .doc('notifications')
          .get();
      if (!doc.exists) {
        // Return default settings
        return {
          'likes': true,
          'comments': true,
          'follows': true,
          'new_posts': true,
        };
      }
      final data = doc.data()!;
      return {
        'likes': data['likes'] as bool? ?? true,
        'comments': data['comments'] as bool? ?? true,
        'follows': data['follows'] as bool? ?? true,
        'new_posts': data['new_posts'] as bool? ?? true,
      };
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to get notification settings',
        code: e.code,
      );
    }
  }

  Future<void> updateNotificationSettings({
    required String userId,
    required Map<String, bool> settings,
  }) async {
    try {
      await _paths
          .user(userId)
          .collection('settings')
          .doc('notifications')
          .set({
        'likes': settings['likes'] ?? true,
        'comments': settings['comments'] ?? true,
        'follows': settings['follows'] ?? true,
        'new_posts': settings['new_posts'] ?? true,
        'updated_at': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to update notification settings',
        code: e.code,
      );
    }
  }

  Future<List<String>> getUserFCMTokens(String userId) async {
    try {
      final snapshot = await _paths.user(userId).collection('fcm_tokens').get();
      return snapshot.docs.map((doc) => doc.data()['token'] as String).toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to get FCM tokens',
        code: e.code,
      );
    }
  }
}
