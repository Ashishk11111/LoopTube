import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../services/playlist_storage.dart';
import '../services/youtube_playlist_import_service.dart';
import '../utils/youtube_url_utils.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final PlaylistStorage _storage = PlaylistStorage();
  final YoutubePlaylistImportService _importService = YoutubePlaylistImportService();
  List<Playlist> _playlists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final playlists = await _storage.loadPlaylists();
    setState(() {
      _playlists = playlists;
      _loading = false;
    });
  }

  Future<void> _persist() => _storage.savePlaylists(_playlists);

  Future<void> _createPlaylist() async {
    final name = await _promptForName(title: 'New playlist');
    if (name == null || name.trim().isEmpty) return;
    setState(() {
      _playlists.add(Playlist(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name.trim(),
      ));
    });
    await _persist();
  }

  Future<void> _renamePlaylist(Playlist playlist) async {
    final name = await _promptForName(title: 'Rename playlist', initial: playlist.name);
    if (name == null || name.trim().isEmpty) return;
    setState(() => playlist.name = name.trim());
    await _persist();
  }

  Future<void> _deletePlaylist(Playlist playlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete playlist?'),
        content: Text('"${playlist.name}" will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _playlists.removeWhere((p) => p.id == playlist.id));
    await _persist();
  }

  Future<String?> _promptForName({required String title, String initial = ''}) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
  }

  Future<void> _importFromYoutube() async {
    final urlController = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import YouTube playlist'),
        content: TextField(
          controller: urlController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Paste a YouTube playlist URL'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, urlController.text), child: const Text('Import')),
        ],
      ),
    );

    if (url == null || url.trim().isEmpty) return;

    final playlistId = YoutubeUrlUtils.extractPlaylistId(url);
    if (playlistId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("That doesn't look like a YouTube playlist URL.")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Importing playlist...')),
          ],
        ),
      ),
    );

    try {
      final title = await _importService.fetchPlaylistTitle(playlistId);
      final videoIds = await _importService.fetchPlaylistVideoIds(playlistId);

      final newPlaylist = Playlist(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: title ?? 'Imported playlist',
        videoIds: videoIds,
      );

      setState(() => _playlists.add(newPlaylist));
      await _persist();

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported "${newPlaylist.name}" — ${videoIds.length} video(s)')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import failed — check the URL, or that the playlist is public.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add_check),
            tooltip: 'Import from YouTube',
            onPressed: _importFromYoutube,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPlaylist,
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _playlists.isEmpty
          ? const Center(
        child: Text(
          'No playlists yet.\nTap + to create one, or import from YouTube.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54),
        ),
      )
          : ListView.builder(
        itemCount: _playlists.length,
        itemBuilder: (context, index) {
          final playlist = _playlists[index];
          return ListTile(
            leading: const Icon(Icons.queue_music, color: Colors.red),
            title: Text(playlist.name),
            subtitle: Text('${playlist.videoIds.length} video(s)'),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlaylistDetailScreen(playlist: playlist),
                ),
              );
              setState(() {});
              await _persist();
            },
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'rename') _renamePlaylist(playlist);
                if (value == 'delete') _deletePlaylist(playlist);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'rename', child: Text('Rename')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          );
        },
      ),
    );
  }
}