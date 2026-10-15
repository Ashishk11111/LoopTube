import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';

class YoutubePlaylistImportService {
  static const _playlistItemsUrl = 'https://www.googleapis.com/youtube/v3/playlistItems';
  static const _playlistsUrl = 'https://www.googleapis.com/youtube/v3/playlists';

  Future<String?> fetchPlaylistTitle(String playlistId) async {
    final uri = Uri.parse(_playlistsUrl).replace(queryParameters: {
      'part': 'snippet',
      'id': playlistId,
      'key': youtubeApiKey,
    });
    final response = await http.get(uri);
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) return null;
    final snippet = items.first['snippet'] as Map<String, dynamic>;
    return snippet['title'] as String?;
  }

  Future<List<String>> fetchPlaylistVideoIds(String playlistId) async {
    final videoIds = <String>[];
    String? pageToken;

    do {
      final uri = Uri.parse(_playlistItemsUrl).replace(queryParameters: {
        'part': 'contentDetails',
        'playlistId': playlistId,
        'maxResults': '50',
        'key': youtubeApiKey,
        if (pageToken != null) 'pageToken': pageToken,
      });

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch playlist (${response.statusCode}): ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      for (final item in items) {
        final contentDetails = item['contentDetails'] as Map<String, dynamic>;
        final videoId = contentDetails['videoId'] as String?;
        if (videoId != null) videoIds.add(videoId);
      }

      pageToken = data['nextPageToken'] as String?;
    } while (pageToken != null);

    return videoIds;
  }
}