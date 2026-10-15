import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/video_details.dart';
import '../services/playlist_storage.dart';
import '../services/youtube_playlist_import_service.dart';
import '../services/youtube_video_details_service.dart';
import 'playlist_player_screen.dart';

class PlaylistPreviewScreen extends StatefulWidget {
  final String playlistId;
  final String title;

  const PlaylistPreviewScreen({super.key, required this.playlistId, required this.title});

  @override
  State<PlaylistPreviewScreen> createState() => _PlaylistPreviewScreenState();
}

class _PlaylistPreviewScreenState extends State<PlaylistPreviewScreen> {
  final YoutubePlaylistImportService _importService = YoutubePlaylistImportService();
  final YoutubeVideoDetailsService _detailsService = YoutubeVideoDetailsService();
  final PlaylistStorage _storage = PlaylistStorage();

  List<String> _videoIds = [];
  Map<String, VideoDetails> _details = {};
  bool _loading = true;
  bool _saved = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ids = await _importService.fetchPlaylistVideoIds(widget.playlistId);
      final details = await _detailsService.fetchDetails(ids);
      if (!mounted) return;
      setState(() {
        _videoIds = ids;
        _details = details;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Failed to load playlist.';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final all = await _storage.loadPlaylists();
    final newPlaylist = Playlist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: widget.title,
      videoIds: _videoIds,
    );
    all.add(newPlaylist);
    await _storage.savePlaylists(all);
    if (!mounted) return;
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved "${widget.title}" to your playlists')),
    );
  }

  void _play({int startIndex = 0}) {
    final tempPlaylist = Playlist(
      id: 'preview_${widget.playlistId}',
      name: widget.title,
      videoIds: _videoIds,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaylistPlayerScreen(playlist: tempPlaylist, startIndex: startIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(_saved ? Icons.check : Icons.playlist_add_check),
            tooltip: 'Save this playlist',
            onPressed: _saved ? null : _save,
          ),
        ],
      ),
      floatingActionButton: _videoIds.isEmpty
          ? null
          : FloatingActionButton.extended(
        backgroundColor: Colors.red,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Play'),
        onPressed: () => _play(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorText != null
          ? Center(child: Text(_errorText!, style: const TextStyle(color: Colors.redAccent)))
          : ListView.builder(
        itemCount: _videoIds.length,
        itemBuilder: (context, index) {
          final id = _videoIds[index];
          final detail = _details[id];
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                'https://i.ytimg.com/vi/$id/mqdefault.jpg',
                width: 80,
                height: 45,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 80,
                  height: 45,
                  child: Icon(Icons.smart_display_outlined, color: Colors.white54),
                ),
              ),
            ),
            title: Text(
              detail?.title ?? 'Video ${index + 1}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              detail?.channelTitle ?? '',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            onTap: () => _play(startIndex: index),
          );
        },
      ),
    );
  }
}