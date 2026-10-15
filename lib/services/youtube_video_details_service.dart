import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../models/video_details.dart';

class YoutubeVideoDetailsService {
  static const _baseUrl = 'https://www.googleapis.com/youtube/v3/videos';

  Future<Map<String, VideoDetails>> fetchDetails(List<String> videoIds) async {
    final result = <String, VideoDetails>{};
    if (videoIds.isEmpty) return result;

    for (var i = 0; i < videoIds.length; i += 50) {
      final end = (i + 50 > videoIds.length) ? videoIds.length : i + 50;
      final chunk = videoIds.sublist(i, end);

      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'part': 'snippet',
        'id': chunk.join(','),
        'key': youtubeApiKey,
      });

      final response = await http.get(uri);
      if (response.statusCode != 200) continue;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      for (final item in items) {
        final id = item['id'] as String;
        final snippet = item['snippet'] as Map<String, dynamic>;
        result[id] = VideoDetails(
          videoId: id,
          title: snippet['title'] as String? ?? 'Untitled',
          channelTitle: snippet['channelTitle'] as String? ?? '',
        );
      }
    }

    return result;
  }
}