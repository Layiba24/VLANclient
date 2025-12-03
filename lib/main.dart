// lib/main.dart
// Web-first main entry for VLC client

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

// Required for Flutter Web platform view registry
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web show platformViewRegistry;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import 'models/playlist_manager.dart';
import 'models/media_item.dart';
import 'utils/theme.dart';
import 'screens/splash_screen.dart';
import 'widgets/advanced_video_player.dart';
import 'widgets/playlist_item.dart';
import 'widgets/video_preview_floating.dart';

// Nullable reference to avoid late initialization errors
html.VideoElement? _webVideoElement;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    const viewId = 'vlc-video-element';

    ui_web.platformViewRegistry.registerViewFactory(
      viewId,
      (int id) {
        final video = html.VideoElement()
          ..controls = false
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'contain'
          ..style.backgroundColor = 'black';

        _webVideoElement = video;
        return video;
      },
    );
  }

  /// Sample test videos
  final sampleVideos = [
    MediaItem(
      title: 'Big Buck Bunny',
      url:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    ),
    MediaItem(
      title: 'Elephant Dream',
      url:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    ),
    MediaItem(
      title: 'Sample Video',
      url:
          'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
    ),
  ];

  runApp(
    ChangeNotifierProvider(
      create: (_) {
        final manager = PlaylistManager();
        for (final v in sampleVideos) {
          manager.addItem(v);
        }
        return manager;
      },
      child: const VLCApp(),
    ),
  );
}

class VLCApp extends StatefulWidget {
  const VLCApp({super.key});

  @override
  State<VLCApp> createState() => _VLCAppState();
}

class _VLCAppState extends State<VLCApp> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Videuno',
      theme: VLCTheme.darkTheme,
      home: _showSplash
          ? SplashScreen(
              displayDuration: const Duration(seconds: 3),
              onComplete: () {
                setState(() {
                  _showSplash = false;
                });
              },
            )
          : const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String _viewId = 'vlc-video-element';
  bool _isPlaying = false;
  bool _showPreview = true;

  void _playCurrent(PlaylistManager manager) {
    if (_webVideoElement == null) return;
    if (manager.playlist.isEmpty) return;

    final item = manager.currentItem;
    if (item == null) return;

    _webVideoElement!.src = item.url;
    _webVideoElement!.play();
  }

  @override
  Widget build(BuildContext context) {
    final playlistManager = Provider.of<PlaylistManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Videuno'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear playlist',
            onPressed: () => playlistManager.clear(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Row(
        children: [
          // VIDEO AREA
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        color: Colors.black,
                        child: kIsWeb
                            ? (_webVideoElement == null
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.orange,
                                      ),
                                    ),
                                  )
                                : Stack(
                                    children: [
                                      AdvancedVideoPlayer(
                                        viewId: _viewId,
                                        webVideoElement: _webVideoElement!,
                                      ),
                                      // Play button overlay when paused
                                      if (!_isPlaying)
                                        Center(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.black.withOpacity(0.5),
                                            ),
                                            padding: const EdgeInsets.all(16),
                                            child: Icon(
                                              Icons.play_arrow,
                                              size: 64,
                                              color: Colors.orange.shade400,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ))
                            : const Center(
                                child: Text(
                                  'Desktop target not supported',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // BASIC CONTROLS
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () {
                          setState(() => _isPlaying = true);
                          _playCurrent(playlistManager);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.pause),
                        onPressed: () {
                          setState(() => _isPlaying = false);
                          _webVideoElement?.pause();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.stop),
                        onPressed: () {
                          _webVideoElement?.pause();
                          _webVideoElement?.currentTime = 0;
                        },
                      ),
                      // Browse files (web + mobile)
                      IconButton(
                        icon: const Icon(Icons.folder_open),
                        onPressed: () async {
                          // Web: use HTML input (keeps existing behavior)
                          if (kIsWeb) {
                            final input = html.FileUploadInputElement()
                              ..accept = ".mp4,.mkv,.webm,.mov,.avi"
                              ..multiple = false;

                            input.onChange.listen((_) {
                              final files = input.files;
                              if (files == null || files.isEmpty) return;

                              final file = files.first;
                              final url =
                                  html.Url.createObjectUrlFromBlob(file);

                              final pm = Provider.of<PlaylistManager>(context,
                                  listen: false);
                              pm.addItem(MediaItem(title: file.name, url: url));
                              pm.setCurrentIndex(pm.playlist.length - 1);
                            });

                            input.click();
                          } else {
                            // Mobile/Desktop (non-web): use file_picker package
                            try {
                              final result = await FilePicker.platform
                                  .pickFiles(
                                      type: FileType.video,
                                      allowMultiple: false);
                              if (result == null || result.files.isEmpty) {
                                return;
                              }

                              final file = result.files.first;
                              final path = file.path;
                              final name = file.name;
                              if (path == null) return;

                              final pm = Provider.of<PlaylistManager>(context,
                                  listen: false);
                              pm.addItem(MediaItem(title: name, url: path));
                              pm.setCurrentIndex(pm.playlist.length - 1);
                            } catch (e) {
                              // ignore for now
                            }
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          playlistManager.currentItem?.title ??
                              'No media loaded',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // PLAYLIST AREA
          Container(
            width: 360,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                left: BorderSide(color: Colors.grey.withOpacity(0.12)),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: const [
                      Text(
                        'Playlist',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: playlistManager.playlist.length,
                    itemBuilder: (context, index) {
                      final item = playlistManager.playlist[index];

                      return PlaylistItem(
                        item: item,
                        isSelected: index == playlistManager.currentIndex,
                        onTap: () {
                          playlistManager.setCurrentIndex(index);
                          _playCurrent(playlistManager);
                        },
                        onSecondaryTap: (ctx) {
                          showModalBottomSheet(
                            context: ctx,
                            builder: (_) => ListTile(
                              leading: const Icon(Icons.delete_outline),
                              title: const Text('Remove'),
                              onTap: () {
                                Navigator.pop(ctx);
                                playlistManager.removeItem(index);
                              },
                            ),
                          );
                        },
                        onRemove: () => playlistManager.removeItem(index),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
          ),
          // Floating preview
          if (_showPreview)
            VideoPreviewFloating(
              currentItem: playlistManager.currentItem,
              isPlaying: _isPlaying,
              onClose: () {
                setState(() {
                  _showPreview = false;
                });
              },
            ),
        ],
      ),
    );
  }
}