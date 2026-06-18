import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:habitshare/core/errors/exceptions.dart';
import 'package:habitshare/core/utils/profile_image_utils.dart';

class FirebaseStorageDataSource {
  FirebaseStorageDataSource({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadProfileImage({
    required String userId,
    required File file,
    String? oldPhotoUrl,
  }) async {
    try {
      if (oldPhotoUrl != null && oldPhotoUrl.isNotEmpty) {
        await _deleteProfileObjectsExcept(
          userId: userId,
          keepPath: ProfileImageUtils.canonicalProfilePath(userId),
          reference: oldPhotoUrl,
        );
      }

      try {
        await _storage
            .ref()
            .child(ProfileImageUtils.canonicalProfilePath(userId))
            .delete();
      } catch (_) {}

      final ref =
          _storage.ref().child(ProfileImageUtils.canonicalProfilePath(userId));
      await ref.putFile(file);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return '${ProfileImageUtils.canonicalProfilePath(userId)}?v=$timestamp';
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to upload image',
        code: e.code,
      );
    }
  }

  /// Gets a fresh download URL for a profile image reference (path or URL).
  Future<String> getProfileImageUrl(String reference) async {
    final cacheBust = ProfileImageUtils.cacheBustQuery(reference);
    FirebaseException? lastError;

    for (final objectPath in ProfileImageUtils.resolveLookupPaths(reference)) {
      try {
        final downloadUrl =
            await _storage.ref().child(objectPath).getDownloadURL();
        if (cacheBust != null) {
          return '$downloadUrl&$cacheBust';
        }
        return downloadUrl;
      } on FirebaseException catch (e) {
        lastError = e;
        if (e.code != 'object-not-found') {
          throw ServerException(
            e.message ?? 'Failed to get image URL',
            code: e.code,
          );
        }
      }
    }

    throw ServerException(
      lastError?.message ?? 'Failed to get image URL',
      code: lastError?.code,
    );
  }

  Future<void> _deleteProfileObjectsExcept({
    required String userId,
    required String keepPath,
    required String reference,
  }) async {
    final objectPath = ProfileImageUtils.resolveStorageReference(reference);
    if (objectPath == null || objectPath == keepPath) {
      return;
    }
    try {
      await _storage.ref().child(objectPath).delete();
    } catch (_) {}

    final legacyUserId =
        ProfileImageUtils.userIdFromProfileStoragePath(objectPath);
    if (legacyUserId == userId && objectPath != keepPath) {
      try {
        await _storage.ref().child(keepPath).delete();
      } catch (_) {}
    }
  }

  Future<void> deletePostImage(String postId) async {
    try {
      // Try to delete common image extensions for the post
      final extensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      for (final ext in extensions) {
        try {
          await _storage.ref().child('posts/$postId.$ext').delete();
        } catch (_) {
          // Ignore if file doesn't exist
        }
      }
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to delete post image',
        code: e.code,
      );
    }
  }
}
