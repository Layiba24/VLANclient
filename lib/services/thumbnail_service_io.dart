import 'dart:convert';

import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailService {
  /// Extract a PNG thumbnail as a data URL for [videoPath].
  /// Returns `null` on failure.
  static Future<String?> extractThumbnail(String videoPath) async {
    try {
      final uint8list = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.PNG,
        maxHeight: 0, // keep original
        quality: 75,
      );

      if (uint8list == null) return null;
      final base64Data = base64Encode(uint8list);
      return 'data:image/png;base64,$base64Data';
    } catch (_) {
      return null;
    }
  }
}
