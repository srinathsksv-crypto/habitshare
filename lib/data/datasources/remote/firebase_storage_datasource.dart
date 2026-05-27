import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:habitshare/core/errors/exceptions.dart';

class FirebaseStorageDataSource {
  FirebaseStorageDataSource({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadProfileImage({
    required String userId,
    required File file,
  }) async {
    try {
      final ref = _storage.ref().child('profiles/$userId.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to upload image',
        code: e.code,
      );
    }
  }
}
