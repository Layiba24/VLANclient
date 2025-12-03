import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

// Conditional export: use native implementation on IO platforms,
// and web implementation on web.
export 'thumbnail_service_io.dart'
    if (dart.library.html) 'thumbnail_service_web.dart';

class ThumbnailService {
  /// Extract a thumbnail from a video URL at a specific time offset (default 2 seconds).
  /// Returns a data URL string that can be used as an image src.
  /// Only works on web (returns null on other platforms).
  static Future<String?> extractThumbnail(
    String videoUrl, {
    double timeOffset = 2.0,
  }) async {
    if (!kIsWeb) return null;

    try {
      final video = html.VideoElement()
        ..src = videoUrl
        ..style.display = 'none'
        ..crossOrigin = 'anonymous';

      html.document.body!.append(video);

      // Wait for metadata to load
      await video.onLoadedMetadata.first;

      // Seek to the time offset
      video.currentTime = timeOffset;

      // Wait a moment for the frame to be ready
      await Future.delayed(const Duration(milliseconds: 300));

      // Capture the frame using canvas
      final canvas = html.CanvasElement()
        ..width = video.videoWidth
        ..height = video.videoHeight;

      final ctx = canvas.context2D;
      ctx.drawImage(video, 0, 0);

      // Get the data URL
      final dataUrl = canvas.toDataUrl('image/jpeg', 0.7);

      // Clean up
      try {
        video.remove();
      } catch (_) {}

      return dataUrl;
    } catch (e) {
      return null;
    }
  }

  /// Extract thumbnail from a video and convert to base64
  static Future<String?> getThumbnailBase64(
    String videoUrl, {
    double timeOffset = 2.0,
  }) async {
    final dataUrl = await extractThumbnail(videoUrl, timeOffset: timeOffset);
    if (dataUrl == null) return null;

    // Remove data:image/jpeg;base64, prefix and return just the base64 string
    final base64 =
        dataUrl.replaceFirst(RegExp(r'data:image/[^;]+;base64,'), '');
    return base64;
  }
}
