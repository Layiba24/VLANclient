// lib/widgets/advanced_video_player.dart

import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/media_item.dart';
import '../models/playlist_manager.dart';

class AdvancedVideoPlayer extends StatefulWidget {
  final String viewId;
  final html.VideoElement webVideoElement;

  const AdvancedVideoPlayer({
    super.key,
    required this.viewId,
    required this.webVideoElement,
  });

  @override
  State<AdvancedVideoPlayer> createState() => _AdvancedVideoPlayerState();
}

class _AdvancedVideoPlayerState extends State<AdvancedVideoPlayer> {
  late final html.VideoElement _video;
  bool _isPlaying = false;
  double _volume = 0.8;
  Timer? _pollTimer;
  PlaylistManager? _manager;
  String? _currentThumbnail;
  bool _thumbnailLoaded = false;

  late html.DivElement _dropOverlay;

  Future<void> _attemptPlay(html.VideoElement v) async {
    final prevMuted = v.muted;
    final prevVolume = v.volume;
    try {
      v.muted = true;
      await v.play();
    } catch (_) {}
    Future.delayed(const Duration(milliseconds: 200), () {
      v.muted = prevMuted;
      v.volume = prevVolume;
    });
  }

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) return;

    _video = widget.webVideoElement;
    _video.volume = _volume;

    _video.onPlay.listen((_) => setState(() => _isPlaying = true));
    _video.onPause.listen((_) => setState(() => _isPlaying = false));
    _video.onEnded.listen((_) => setState(() => _isPlaying = false));

    _manager = Provider.of<PlaylistManager>(context, listen: false);
    _manager?.addListener(_onPlaylistChanged);

    _pollTimer = Timer.periodic(
        const Duration(milliseconds: 150), (_) => setState(() {}));

    // Drag and Drop overlay
    _dropOverlay = html.DivElement()
      ..style.position = 'absolute'
      ..style.top = '0'
      ..style.left = '0'
      ..style.right = '0'
      ..style.bottom = '0'
      ..style.backgroundColor = 'rgba(255,255,255,0.15)'
      ..style.display = 'none'
      ..style.pointerEvents = 'none'
      ..style.transition = 'opacity 0.2s';

    html.document.body!.append(_dropOverlay);

    html.window.onDragOver.listen((e) {
      e.preventDefault();
      _dropOverlay.style.display = 'block';
    });

    html.window.onDrop.listen((e) {
      e.preventDefault();
      _dropOverlay.style.display = 'none';

      final files = e.dataTransfer.files;
      if (files == null || files.isEmpty) return;

      final file = files.first;
      final url = html.Url.createObjectUrlFromBlob(file);

      final pm = Provider.of<PlaylistManager>(context, listen: false);
      pm.addItem(MediaItem(title: file.name, url: url));
      pm.setCurrentIndex(pm.playlist.length - 1);
    });

    html.window.onDragLeave.listen((html.Event _) {
      _dropOverlay.style.display = 'none';
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _manager?.removeListener(_onPlaylistChanged);

    try {
      _dropOverlay.remove();
    } catch (_) {}

    super.dispose();
  }

  void _onPlaylistChanged() {
    final item = _manager?.currentItem;
    if (item == null) return;

    _video.src = item.url;
    _currentThumbnail = item.thumbnailUrl;
    _thumbnailLoaded = item.thumbnailUrl != null;

    // If no thumbnail yet, extract one asynchronously (web only here)
    if (!_thumbnailLoaded && kIsWeb && item.url.startsWith('http')) {
      final idx = _manager?.currentIndex ?? 0;
      _generateWebThumbnail(item, idx);
    }

    _attemptPlay(_video);
  }

  void _generateWebThumbnail(MediaItem item, int index) async {
    try {
      final off = html.VideoElement()
        ..src = item.url
        ..crossOrigin = 'anonymous'
        ..muted = true
        ..preload = 'auto'
        ..style.display = 'none';

      html.document.body!.append(off);

      await off.onLoadedData.first;

      // Seek to 0.5s (if available)
      try {
        off.currentTime = off.duration > 1 ? 1 : 0.5;
      } catch (_) {}

      // wait a bit for the frame
      await Future.delayed(const Duration(milliseconds: 250));

      final canvas =
          html.CanvasElement(width: off.videoWidth, height: off.videoHeight);
      final ctx = canvas.context2D;
      ctx.drawImageScaled(off, 0, 0, canvas.width!, canvas.height!);
      final dataUrl = canvas.toDataUrl('image/png');

      // update playlist item with thumbnail
      final newItem = item.copyWith(thumbnailUrl: dataUrl);
      _manager?.updateItem(index, newItem);

      // cleanup
      try {
        off.remove();
        canvas.remove();
      } catch (_) {}
    } catch (_) {}
  }

  String _formatTime(num n) {
    if (n.isNaN || n.isInfinite) return "00:00";
    final s = n.floor();
    final m = s ~/ 60;
    final sec = s % 60;
    return "${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
  }

  Widget _buildThumbnailImage(String thumbnailUrl) {
    // Handle data URLs (base64 encoded images)
    if (thumbnailUrl.startsWith('data:')) {
      try {
        // Extract base64 data from data URL
        final base64Data = thumbnailUrl.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(bytes,
            fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container());
      } catch (_) {
        return Container();
      }
    }
    // Handle network URLs
    return Image.network(thumbnailUrl,
        fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container());
  }

  void _toggleFullscreen() {
    try {
      _video.requestFullscreen();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox();

    final duration = _video.duration.toDouble();
    final current = _video.currentTime.toDouble();

    return GestureDetector(
      onDoubleTap: _toggleFullscreen,
      child: Stack(
        children: [
          // Video player
          Positioned.fill(child: HtmlElementView(viewType: widget.viewId)),

          // Thumbnail overlay (shown while loading)
          if (_currentThumbnail != null && !_isPlaying)
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: _buildThumbnailImage(_currentThumbnail!),
              ),
            ),

          // Loading spinner (shown if no thumbnail and not playing)
          if (!_isPlaying && (_currentThumbnail == null || !_thumbnailLoaded))
            Positioned.fill(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.orange),
                  ),
                ),
              ),
            ),

          // Controls overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.black.withOpacity(0.55),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // SEEK BAR
                  Row(
                    children: [
                      Text(
                        _formatTime(current),
                        style: const TextStyle(color: Colors.white),
                      ),
                      Expanded(
                        child: Slider(
                          value: current.isFinite ? current : 0.0,
                          min: 0.0,
                          max: duration.isFinite && duration > 0
                              ? duration
                              : 100.0,
                          onChanged: (v) {
                            _video.currentTime = v;
                            setState(() {});
                          },
                        ),
                      ),
                      Text(
                        _formatTime(duration),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      // Play / Pause
                      IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          if (_isPlaying) {
                            _video.pause();
                          } else {
                            _attemptPlay(_video);
                          }
                        },
                      ),

                      // Volume slider
                      const Icon(Icons.volume_up, color: Colors.white),
                      SizedBox(
                        width: 120,
                        child: Slider(
                          value: _volume,
                          min: 0,
                          max: 1,
                          onChanged: (v) {
                            _volume = v;
                            _video.volume = v;
                            setState(() {});
                          },
                        ),
                      ),

                      const Spacer(),

                      // File picker
                      IconButton(
                        icon:
                            const Icon(Icons.folder_open, color: Colors.white),
                        onPressed: () {
                          final input = html.FileUploadInputElement()
                            ..accept = ".mp4,.mkv,.webm,.mov,.avi";

                          input.onChange.listen((_) {
                            final files = input.files;
                            if (files == null || files.isEmpty) return;

                            final file = files.first;
                            final url = html.Url.createObjectUrlFromBlob(file);

                            final pm = Provider.of<PlaylistManager>(context,
                                listen: false);

                            pm.addItem(MediaItem(title: file.name, url: url));
                            pm.setCurrentIndex(pm.playlist.length - 1);
                          });

                          input.click();
                        },
                      ),

                      // Fullscreen
                      IconButton(
                        icon: const Icon(Icons.fullscreen, color: Colors.white),
                        onPressed: _toggleFullscreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
