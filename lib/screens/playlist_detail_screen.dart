import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../models/playlist.dart';
import '../models/video_details.dart';
import '../services/playlist_storage.dart';
import '../services/youtube_video_details_service.dart';
import '../utils/youtube_url_utils.dart';
import 'playlist_player_screen.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final PlaylistStorage _storage = PlaylistStorage();
  final YoutubeVideoDetailsService _detailsService = YoutubeVideoDetailsService();
  final TextEditingController _urlController = TextEditingController();
  String? _errorText;
  Map<String, VideoDetails> _details = {};

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final details = await _detailsService.fetchDetails(widget.playlist.videoIds);
    if (!mounted) return;
    setState(() => _details = details);
  }

  Future<void> _persist() async {
    final all = await _storage.loadPlaylists();
    final index = all.indexWhere((p) => p.id == widget.playlist.id);
    if (index != -1) all[index] = widget.playlist;
    await _storage.savePlaylists(all);
  }

  void _addVideo() {
    final videoId = YoutubeUrlUtils.extractVideoId(_urlController.text);
    if (videoId == null) {
      setState(() => _errorText = "That doesn't look like a valid YouTube URL.");
      return;
    }
    setState(() {
      widget.playlist.videoIds.add(videoId);
      _errorText = null;
      _urlController.clear();
    });
    _persist();
    _loadDetails();
  }

  void _removeVideo(int index) {
    setState(() => widget.playlist.videoIds.removeAt(index));
    _persist();
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final id = widget.playlist.videoIds.removeAt(oldIndex);
      widget.playlist.videoIds.insert(newIndex, id);
    });
    _persist();
  }

  void _openPlayer({int startIndex = 0, bool shuffle = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaylistPlayerScreen(
          playlist: widget.playlist,
          startIndex: startIndex,
          startShuffled: shuffle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasVideos = widget.playlist.videoIds.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(widget.playlist.name)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Paste a YouTube URL to add',
                      prefixIcon: Icon(Icons.link, color: Colors.white54),
                    ),
                    onSubmitted: (_) => _addVideo(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addVideo,
                  icon: const Icon(Icons.add),
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(_errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ),
            ),
          if (hasVideos)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openPlayer(),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openPlayer(shuffle: true),
                      icon: const Icon(Icons.shuffle),
                      label: const Text('Shuffle'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (hasVideos)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Hold and drag to reorder', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ),
            ),
          Expanded(
            child: !hasVideos
                ? const Center(
              child: Text(
                'No videos yet.\nPaste a URL above to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            )
                : ReorderableListView.builder(
              itemCount: widget.playlist.videoIds.length,
              onReorder: _reorder,
              itemBuilder: (context, index) {
                final videoId = widget.playlist.videoIds[index];
                final detail = _details[videoId];
                return ListTile(
                  key: ValueKey(videoId),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      YoutubePlayerController.getThumbnail(
                        videoId: videoId,
                        quality: ThumbnailQuality.medium,
                      ),
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
                    detail?.channelTitle ?? videoId,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  onTap: () => _openPlayer(startIndex: index),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _removeVideo(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}