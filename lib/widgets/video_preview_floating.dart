import 'package:flutter/material.dart';
import '../models/media_item.dart';

class VideoPreviewFloating extends StatelessWidget {
  final MediaItem? currentItem;
  final bool isPlaying;
  final VoidCallback onClose;

  const VideoPreviewFloating({
    Key? key,
    required this.currentItem,
    required this.isPlaying,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (currentItem == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 20,
      right: 20,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 200,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black87,
            border: Border.all(
              color: Colors.orange.shade400,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              // Preview content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      currentItem!.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Status
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          isPlaying ? Icons.play_circle : Icons.pause_circle,
                          color: Colors.orange.shade400,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPlaying ? 'Playing' : 'Paused',
                          style: TextStyle(
                            color: Colors.orange.shade400,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // URL preview
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      currentItem!.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
              // Close button
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onClose,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.orange.shade400.withOpacity(0.8),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
