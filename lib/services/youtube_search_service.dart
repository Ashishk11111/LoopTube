import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../models/youtube_search_result.dart';

class YoutubeSearchService {
  static const _baseUrl = 'https://www.googleapis.com/youtube/v3/search';

  Future<List<YoutubeSearchResult>> search(String query) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'part': 'snippet',
      'q': query,
      'type': 'video,playlist',
      'maxResults': '50',
      'key': youtubeApiKey,
    });

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('YouTube search failed (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => YoutubeSearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}