import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../models/playlist.dart';
import '../models/youtube_search_result.dart';
import '../services/playlist_storage.dart';
import '../services/youtube_search_service.dart';
import 'playlist_preview_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  final YoutubeSearchService _searchService = YoutubeSearchService();
  final PlaylistStorage _playlistStorage = PlaylistStorage();
  late final YoutubePlayerController _controller;

  List<YoutubeSearchResult> _results = [];
  bool _loading = false;
  String? _errorText;
  String? _playingVideoId;
  bool _hasPlayedSomething = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
      ),
    );
  }

  Future<void> _runSearch() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _errorText = null;
    });

    try {
      final results = await _searchService.search(query);
      setState(() => _results = results);
    } catch (e) {
      setState(() => _errorText = 'Search failed. Check your API key and internet connection.');
    } finally {
      setState(() => _loading = false);
    }

    FocusScope.of(context).unfocus();
  }

  void _playVideo(YoutubeSearchResult result) {
    setState(() {
      _playingVideoId = result.id;
      _hasPlayedSomething = true;
    });
    _controller.loadVideoById(videoId: result.id);
  }

  void _openPlaylist(YoutubeSearchResult result) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaylistPreviewScreen(playlistId: result.id, title: result.title),
      ),
    );
  }

  Future<void> _addToPlaylist(YoutubeSearchResult result) async {
    final playlists = await _playlistStorage.loadPlaylists();
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
                  playlists.add(newPlaylist);
                  if (context.mounted) Navigator.pop(context, newPlaylist);
                },
              ),
              const Divider(color: Colors.white24, height: 1),
              if (playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text('No playlists yet.', style: TextStyle(color: Colors.white54)),
                )
              else
                ...playlists.map(
                      (playlist) => ListTile(
                    leading: const Icon(Icons.queue_music, color: Colors.red),
                    title: Text(playlist.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      '${playlist.videoIds.length} video(s)',
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
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

    if (selected.videoIds.contains(result.id)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Already in "${selected.name}"')),
      );
      return;
    }

    selected.videoIds.add(result.id);
    await _playlistStorage.savePlaylists(playlists);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added to "${selected.name}"')),
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Search YouTube',
                        prefixIcon: Icon(Icons.search, color: Colors.white54),
                      ),
                      onSubmitted: (_) => _runSearch(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _runSearch,
                    icon: const Icon(Icons.search),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            if (_hasPlayedSomething)
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
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ),
            Expanded(
              child: _results.isEmpty
                  ? const Center(
                child: Text(
                  'Search for something to get started.',
                  style: TextStyle(color: Colors.white54),
                ),
              )
                  : ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[index];
                  final isVideo = result.type == YoutubeResultType.video;
                  final isPlaying = isVideo && result.id == _playingVideoId;

                  return ListTile(
                    leading: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            result.thumbnailUrl,
                            width: 100,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (!isVideo)
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: const Icon(Icons.queue_music, size: 12, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      result.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isPlaying ? Colors.red : Colors.white,
                        fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      isVideo ? result.channelTitle : 'Playlist · ${result.channelTitle}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    trailing: isVideo
                        ? IconButton(
                      icon: const Icon(Icons.playlist_add, color: Colors.white70),
                      onPressed: () => _addToPlaylist(result),
                    )
                        : const Icon(Icons.chevron_right, color: Colors.white38),
                    onTap: () => isVideo ? _playVideo(result) : _openPlaylist(result),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}