import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../models/playlist.dart';
import '../models/video_details.dart';
import '../services/playlist_storage.dart';
import '../services/youtube_video_details_service.dart';

enum LoopMode { off, playlist, single }

class PlaylistPlayerScreen extends StatefulWidget {
  final Playlist playlist;
  final int startIndex;
  final bool startShuffled;

  const PlaylistPlayerScreen({
    super.key,
    required this.playlist,
    this.startIndex = 0,
    this.startShuffled = false,
  });

  @override
  State<PlaylistPlayerScreen> createState() => _PlaylistPlayerScreenState();
}

class _PlaylistPlayerScreenState extends State<PlaylistPlayerScreen> {
  late final YoutubePlayerController _controller;
  late final StreamSubscription<YoutubePlayerValue> _subscription;
  late List<String> _order;
  late int _currentIndex;
  LoopMode _loopMode = LoopMode.off;
  late bool _shuffle;
  final PlaylistStorage _playlistStorage = PlaylistStorage();
  final YoutubeVideoDetailsService _detailsService = YoutubeVideoDetailsService();
  Map<String, VideoDetails> _details = {};

  @override
  void initState() {
    super.initState();
    _order = List.from(widget.playlist.videoIds);
    _shuffle = widget.startShuffled;

    if (_shuffle) {
      _order.shuffle(Random());
      _currentIndex = 0;
    } else {
      _currentIndex = widget.startIndex.clamp(0, _order.length - 1);
    }

    _controller = YoutubePlayerController.fromVideoId(
      videoId: _order[_currentIndex],
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
      ),
    );
    _subscription = _controller.listen(_onPlayerValueChanged);
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final details = await _detailsService.fetchDetails(_order);
    if (!mounted) return;
    setState(() => _details = details);
  }

  void _onPlayerValueChanged(YoutubePlayerValue value) {
    if (value.playerState == PlayerState.ended) {
      _handleVideoEnded();
    }
  }

  void _handleVideoEnded() {
    if (_loopMode == LoopMode.single) {
      _controller.seekTo(seconds: 0);
      _controller.playVideo();
      return;
    }
    final isLastVideo = _currentIndex == _order.length - 1;
    if (isLastVideo && _loopMode == LoopMode.off) return;
    _playNext();
  }

  void _toggleShuffle() {
    setState(() {
      _shuffle = !_shuffle;
      final currentId = _order[_currentIndex];
      if (_shuffle) {
        final rest = List<String>.from(widget.playlist.videoIds)..remove(currentId);
        rest.shuffle(Random());
        _order = [currentId, ...rest];
      } else {
        _order = List.from(widget.playlist.videoIds);
      }
      _currentIndex = _order.indexOf(currentId);
    });
  }

  void _cycleLoopMode() {
    setState(() {
      _loopMode = switch (_loopMode) {
        LoopMode.off => LoopMode.playlist,
        LoopMode.playlist => LoopMode.single,
        LoopMode.single => LoopMode.off,
      };
    });
  }

  void _playAt(int index) {
    setState(() => _currentIndex = index);
    _controller.loadVideoById(videoId: _order[index]);
  }

  void _playNext() {
    int next = _currentIndex + 1;
    if (next >= _order.length) {
      if (_loopMode == LoopMode.playlist) {
        next = 0;
      } else {
        return;
      }
    }
    _playAt(next);
  }

  void _playPrevious() {
    int prev = _currentIndex - 1;
    if (prev < 0) {
      if (_loopMode == LoopMode.playlist) {
        prev = _order.length - 1;
      } else {
        return;
      }
    }
    _playAt(prev);
  }

  Future<void> _addCurrentVideoToPlaylist() async {
    final currentVideoId = _order[_currentIndex];
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
                  final name = await _promptForPlaylistName(context);
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

  Future<String?> _promptForPlaylistName(BuildContext sheetContext) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: sheetContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, controller.text), child: const Text('Create')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    _controller.close();
    super.dispose();
  }

  IconData get _loopIcon {
    switch (_loopMode) {
      case LoopMode.off:
        return Icons.repeat;
      case LoopMode.playlist:
        return Icons.repeat_on_outlined;
      case LoopMode.single:
        return Icons.repeat_one_on_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Add current video to playlist',
            onPressed: _addCurrentVideoToPlaylist,
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
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.skip_previous, size: 32), onPressed: _playPrevious),
                  IconButton(
                    icon: Icon(_shuffle ? Icons.shuffle_on_outlined : Icons.shuffle, size: 28),
                    color: _shuffle ? Colors.red : Colors.white,
                    onPressed: _toggleShuffle,
                  ),
                  IconButton(
                    icon: Icon(_loopIcon, size: 28),
                    color: _loopMode == LoopMode.off ? Colors.white : Colors.red,
                    onPressed: _cycleLoopMode,
                  ),
                  IconButton(icon: const Icon(Icons.skip_next, size: 32), onPressed: _playNext),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: _order.length,
                itemBuilder: (context, index) {
                  final videoId = _order[index];
                  final isCurrent = index == _currentIndex;
                  final detail = _details[videoId];
                  return ListTile(
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrent ? Colors.red : Colors.white,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      detail?.channelTitle ?? videoId,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    trailing: isCurrent ? const Icon(Icons.equalizer, color: Colors.red) : null,
                    onTap: () => _playAt(index),
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