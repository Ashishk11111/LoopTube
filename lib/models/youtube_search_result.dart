enum YoutubeResultType { video, playlist }

class YoutubeSearchResult {
  final YoutubeResultType type;
  final String id;
  final String title;
  final String channelTitle;
  final String thumbnailUrl;

  YoutubeSearchResult({
    required this.type,
    required this.id,
    required this.title,
    required this.channelTitle,
    required this.thumbnailUrl,
  });

  factory YoutubeSearchResult.fromJson(Map<String, dynamic> json) {
    final idMap = json['id'] as Map<String, dynamic>;
    final snippet = json['snippet'] as Map<String, dynamic>;
    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>;
    final thumbnail = (thumbnails['medium'] ?? thumbnails['default']) as Map<String, dynamic>;

    final kind = idMap['kind'] as String? ?? '';
    final isPlaylist = kind.contains('playlist');

    return YoutubeSearchResult(
      type: isPlaylist ? YoutubeResultType.playlist : YoutubeResultType.video,
      id: isPlaylist ? (idMap['playlistId'] as String) : (idMap['videoId'] as String),
      title: snippet['title'] as String,
      channelTitle: snippet['channelTitle'] as String,
      thumbnailUrl: thumbnail['url'] as String,
    );
  }
}