import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../models/playlist.dart';
import '../services/playlist_storage.dart';
import '../utils/youtube_url_utils.dart';
import 'playlists_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final YoutubePlayerController _controller;
  final TextEditingController _urlController = TextEditingController();
  final PlaylistStorage _playlistStorage = PlaylistStorage();
  String? _errorText;
  String? _currentVideoId;

  static const String _defaultVideoId = 'dQw4w9WgXcQ';

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: _defaultVideoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _controller.close();
    super.dispose();
  }

  void _handlePlay() {
    final videoId = YoutubeUrlUtils.extractVideoId(_urlController.text);
    if (videoId == null) {
      setState(() => _errorText = "That doesn't look like a valid YouTube URL.");
      return;
    }
    setState(() {
      _errorText = null;
      _currentVideoId = videoId;
    });
    _controller.loadVideoById(videoId: videoId);
    FocusScope.of(context).unfocus();
  }

  Future<void> _addCurrentVideoToPlaylist() async {
    if (_currentVideoId == null) return;
    final currentVideoId = _currentVideoId!;
    final allPlaylists = await _playlistStorage.loadPlaylists();
    if (!mounted) return;

    final selected = await showModalBottomSheet<Playlist>(
      context: context,
      backgroundColor: const Color(0xFF181818),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Add to playlist', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
              ListTile(
                leading: const Icon(Icons.add, color: Colors.red),
                title: const Text('Create new playlist', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  final name = await showDialog<String>(
                    context: context,
                    builder: (dialogContext) {
                      final controller = TextEditingController();
                      return AlertDialog(
                        title: const Text('New playlist'),
                        content: TextField(
                          controller: controller,
                          autofocus: true,
                          decoration: const InputDecoration(hintText: 'Playlist name'),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, controller.text),
                            child: const Text('Create'),
                          ),
                        ],
                      );
                    },
                  );
                  if (name == null || name.trim().isEmpty) return;
                  final newPlaylist = Playlist(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    name: name.trim(),
                  );
                  allPlaylists.add(newPlaylist);
                  if (context.mounted) Navigator.pop(context, newPlaylist);
                },
              ),
              const Divider(color: Colors.white24, height: 1),
              if (allPlaylists.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text('No playlists yet.', style: TextStyle(color: Colors.white54)),
                )
              else
                ...allPlaylists.map(
                      (playlist) => ListTile(
                    leading: const Icon(Icons.queue_music, color: Colors.red),
                    title: Text(playlist.name, style: const TextStyle(color: Colors.white)),
                    onTap: () => Navigator.pop(context, playlist),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected == null) return;

    if (selected.videoIds.contains(currentVideoId)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Already in "${selected.name}"')),
      );
      return;
    }

    selected.videoIds.add(currentVideoId);
    await _playlistStorage.savePlaylists(allPlaylists);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added to "${selected.name}"')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_display_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('🫵🧪', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Add current video to playlist',
            onPressed: _currentVideoId == null ? null : _addCurrentVideoToPlaylist,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.video_library_outlined),
            tooltip: 'Playlists',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PlaylistsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            YoutubePlayerScaffold(
              controller: _controller,
              aspectRatio: 16 / 9,
              autoFullScreen: true,
              fullscreenOrientations: const [
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ],
              builder: (context, player) => player,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Paste a YouTube URL',
                        prefixIcon: Icon(Icons.link, color: Colors.white54),
                      ),
                      onSubmitted: (_) => _handlePlay(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _handlePlay,
                    icon: const Icon(Icons.play_arrow),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _errorText!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}