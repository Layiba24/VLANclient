import 'package:flutter/foundation.dart';

@immutable
class MediaItem {
  final String title;
  final String url;
  final String? filePath;
  final DateTime addedAt;
  final Map<String, dynamic>? metadata;
  final String? thumbnailUrl; // Data URL or local path for thumbnail

  MediaItem({
    required this.title,
    required this.url,
    this.filePath,
    DateTime? addedAt,
    this.metadata,
    this.thumbnailUrl,
  }) : addedAt = addedAt ?? DateTime.now();

  /// Create a copy with optional thumbnail
  MediaItem copyWith({
    String? title,
    String? url,
    String? filePath,
    DateTime? addedAt,
    Map<String, dynamic>? metadata,
    String? thumbnailUrl,
  }) {
    return MediaItem(
      title: title ?? this.title,
      url: url ?? this.url,
      filePath: filePath ?? this.filePath,
      addedAt: addedAt ?? this.addedAt,
      metadata: metadata ?? this.metadata,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }
}
