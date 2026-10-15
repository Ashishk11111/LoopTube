class Playlist {
  final String id;
  String name;
  List<String> videoIds;

  Playlist({
    required this.id,
    required this.name,
    List<String>? videoIds,
  }) : videoIds = videoIds ?? [];

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      videoIds: List<String>.from(json['videoIds'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'videoIds': videoIds,
  };
}