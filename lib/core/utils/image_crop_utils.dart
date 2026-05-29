import 'dart:io';
import 'package:image_cropper/image_cropper.dart';

class ImageCropUtils {
  ImageCropUtils._();

  static Future<File?> cropPostImage(String sourcePath) async {
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 5),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop image',
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop image',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );
      if (cropped == null) {
        // User explicitly cancelled the cropping activity
        return null;
      }
      return File(cropped.path);
    } catch (e) {
      // Something failed (e.g. platform error), gracefully fall back to original image
      return File(sourcePath);
    }
  }
}
