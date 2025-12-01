import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../models/playlist_manager.dart';
import '../models/media_item.dart';

class MobileVideoPlayer extends StatefulWidget {
  const MobileVideoPlayer({super.key});

  @override
  State<MobileVideoPlayer> createState() => _MobileVideoPlayerState();
}

class _MobileVideoPlayerState extends State<MobileVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  PlaylistManager? _manager;
  StreamSubscription? _playlistSub;

  @override
  void initState() {
    super.initState();
    _manager = Provider.of<PlaylistManager>(context, listen: false);
    _manager?.addListener(_onPlaylistChanged);
    _initializeForCurrent();
  }

  @override
  void dispose() {
    _playlistSub?.cancel();
    _controller?.dispose();
    _manager?.removeListener(_onPlaylistChanged);
    super.dispose();
  }

  void _onPlaylistChanged() {
    _initializeForCurrent();
  }

  Future<void> _initializeForCurrent() async {
    final item = _manager?.currentItem;
    if (item == null) return;

    try {
      final old = _controller;
      _controller = null;
      if (old != null) {
        await old.pause();
        await old.dispose();
      }

      if (item.url.startsWith('http') || item.url.startsWith('https')) {
        _controller = VideoPlayerController.network(item.url);
      } else {
        // assume local file path on mobile
        _controller = VideoPlayerController.file(File(item.url));
      }

      await _controller!.initialize();
      setState(() => _isInitialized = true);
      _controller!.play();
      _controller!.setLooping(false);
    } catch (e) {
      // initialization failed
      setState(() {
        _isInitialized = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox();

    if (!_isInitialized || _controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text('No media loaded', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: Stack(
        children: [
          VideoPlayer(_controller!),
          Positioned(
            bottom: 8,
            left: 8,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                      _controller!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _controller!.value.isPlaying
                          ? _controller!.pause()
                          : _controller!.play();
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
