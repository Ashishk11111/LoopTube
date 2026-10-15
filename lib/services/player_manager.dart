// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/foundation.dart';
// import 'package:youtube_player_iframe/youtube_player_iframe.dart';
//
// enum LoopMode { off, playlist, single }
//
// class NowPlayingItem {
//   final String videoId;
//   final String title;
//   final String thumbnailUrl;
//
//   NowPlayingItem({
//     required this.videoId,
//     required this.title,
//     this.thumbnailUrl = '',
//   });
// }
//
// class PlayerManager extends ChangeNotifier {
//   PlayerManager._internal() {
//     _controller = YoutubePlayerController(
//       params: const YoutubePlayerParams(
//         showControls: true,
//         showFullscreenButton: true,
//         strictRelatedVideos: true,
//       ),
//     );
//     _subscription = _controller.listen(_onValueChanged);
//   }
//
//   static final PlayerManager instance = PlayerManager._internal();
//
//   late final YoutubePlayerController _controller;
//   late final StreamSubscription<YoutubePlayerValue> _subscription;
//
//   YoutubePlayerController get controller => _controller;
//
//   List<NowPlayingItem> _originalOrder = [];
//   List<NowPlayingItem> _queue = [];
//   int _currentIndex = 0;
//   LoopMode _loopMode = LoopMode.off;
//   bool _shuffle = false;
//   bool _isActive = false;
//   bool _isExpanded = false;
//
//   List<NowPlayingItem> get queue => _queue;
//   int get currentIndex => _currentIndex;
//   NowPlayingItem? get currentItem => _queue.isEmpty ? null : _queue[_currentIndex];
//   LoopMode get loopMode => _loopMode;
//   bool get shuffle => _shuffle;
//   bool get isActive => _isActive;
//   bool get isExpanded => _isExpanded;
//   bool get isPlaying => _controller.value.playerState == PlayerState.playing;
//
//   void _onValueChanged(YoutubePlayerValue value) {
//     if (value.playerState == PlayerState.ended) {
//       _handleEnded();
//     }
//     notifyListeners();
//   }
//
//   void _handleEnded() {
//     if (_loopMode == LoopMode.single) {
//       _controller.seekTo(seconds: 0);
//       _controller.playVideo();
//       return;
//     }
//     final isLast = _currentIndex == _queue.length - 1;
//     if (isLast && _loopMode == LoopMode.off) return;
//     next();
//   }
//
//   void playSingle({required String videoId, required String title, String thumbnailUrl = ''}) {
//     final item = NowPlayingItem(videoId: videoId, title: title, thumbnailUrl: thumbnailUrl);
//     _originalOrder = [item];
//     _queue = [item];
//     _currentIndex = 0;
//     _shuffle = false;
//     _isActive = true;
//     _controller.loadVideoById(videoId: videoId);
//     notifyListeners();
//   }
//
//   void playQueue({required List<NowPlayingItem> items, int startIndex = 0, bool shuffle = false}) {
//     if (items.isEmpty) return;
//     _originalOrder = List.from(items);
//     _queue = List.from(items);
//     _currentIndex = startIndex.clamp(0, _queue.length - 1);
//     _shuffle = shuffle;
//     if (_shuffle) {
//       final current = _queue[_currentIndex];
//       final rest = List<NowPlayingItem>.from(_queue)..removeAt(_currentIndex);
//       rest.shuffle(Random());
//       _queue = [current, ...rest];
//       _currentIndex = 0;
//     }
//     _isActive = true;
//     _controller.loadVideoById(videoId: _queue[_currentIndex].videoId);
//     notifyListeners();
//   }
//
//   void toggleShuffle() {
//     if (_queue.isEmpty) return;
//     final current = _queue[_currentIndex];
//     _shuffle = !_shuffle;
//     if (_shuffle) {
//       final rest = List<NowPlayingItem>.from(_originalOrder)
//         ..removeWhere((item) => item.videoId == current.videoId);
//       rest.shuffle(Random());
//       _queue = [current, ...rest];
//       _currentIndex = 0;
//     } else {
//       _queue = List.from(_originalOrder);
//       _currentIndex = _queue.indexWhere((item) => item.videoId == current.videoId);
//     }
//     notifyListeners();
//   }
//
//   void cycleLoopMode() {
//     _loopMode = switch (_loopMode) {
//       LoopMode.off => LoopMode.playlist,
//       LoopMode.playlist => LoopMode.single,
//       LoopMode.single => LoopMode.off,
//     };
//     notifyListeners();
//   }
//
//   void playAt(int index) {
//     if (index < 0 || index >= _queue.length) return;
//     _currentIndex = index;
//     _controller.loadVideoById(videoId: _queue[index].videoId);
//     notifyListeners();
//   }
//
//   void next() {
//     int nextIndex = _currentIndex + 1;
//     if (nextIndex >= _queue.length) {
//       if (_loopMode == LoopMode.playlist) {
//         nextIndex = 0;
//       } else {
//         return;
//       }
//     }
//     playAt(nextIndex);
//   }
//
//   void previous() {
//     int prevIndex = _currentIndex - 1;
//     if (prevIndex < 0) {
//       if (_loopMode == LoopMode.playlist) {
//         prevIndex = _queue.length - 1;
//       } else {
//         return;
//       }
//     }
//     playAt(prevIndex);
//   }
//
//   void togglePlayPause() {
//     if (isPlaying) {
//       _controller.pauseVideo();
//     } else {
//       _controller.playVideo();
//     }
//   }
//
//   void expand() {
//     _isExpanded = true;
//     notifyListeners();
//   }
//
//   void collapse() {
//     _isExpanded = false;
//     notifyListeners();
//   }
//
//   void closeMiniPlayer() {
//     _isActive = false;
//     _isExpanded = false;
//     _controller.pauseVideo();
//     notifyListeners();
//   }
// }


// The Fix


import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

enum LoopMode { off, playlist, single }

class NowPlayingItem {
  final String videoId;
  final String title;
  final String thumbnailUrl;

  NowPlayingItem({
    required this.videoId,
    required this.title,
    this.thumbnailUrl = '',
  });
}

class PlayerManager extends ChangeNotifier {
  PlayerManager._internal() {
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
      ),
    );
    _subscription = _controller.listen(_onValueChanged);
  }

  static final PlayerManager instance = PlayerManager._internal();

  late final YoutubePlayerController _controller;
  late final StreamSubscription<YoutubePlayerValue> _subscription;

  YoutubePlayerController get controller => _controller;

  List<NowPlayingItem> _originalOrder = [];
  List<NowPlayingItem> _queue = [];
  int _currentIndex = 0;
  LoopMode _loopMode = LoopMode.off;
  bool _shuffle = false;
  bool _isActive = false;
  bool _isExpanded = false;

  List<NowPlayingItem> get queue => _queue;
  int get currentIndex => _currentIndex;
  NowPlayingItem? get currentItem => _queue.isEmpty ? null : _queue[_currentIndex];
  LoopMode get loopMode => _loopMode;
  bool get shuffle => _shuffle;
  bool get isActive => _isActive;
  bool get isExpanded => _isExpanded;
  bool get isPlaying => _controller.value.playerState == PlayerState.playing;
  bool get isBuffering =>
      _controller.value.playerState == PlayerState.buffering ||
          _controller.value.playerState == PlayerState.unStarted;

  void _onValueChanged(YoutubePlayerValue value) {
    if (value.playerState == PlayerState.ended) {
      _handleEnded();
    }
    notifyListeners();
  }

  void _handleEnded() {
    if (_loopMode == LoopMode.single) {
      _controller.seekTo(seconds: 0);
      _controller.playVideo();
      return;
    }
    final isLast = _currentIndex == _queue.length - 1;
    if (isLast && _loopMode == LoopMode.off) return;
    next();
  }

  // NOTE: _isActive is set to true and notifyListeners() is called BEFORE
  // (or around) the loadVideoById call is issued. This matters because the
  // player widget in PersistentPlayerOverlay must already be mounted (kept
  // alive via Visibility(maintainState: true) rather than conditionally
  // built/unbuilt) for loadVideoById to actually reach a live WebView.
  // See persistent_player_overlay.dart for the corresponding fix.

  void playSingle({required String videoId, required String title, String thumbnailUrl = ''}) {
    final item = NowPlayingItem(videoId: videoId, title: title, thumbnailUrl: thumbnailUrl);
    _originalOrder = [item];
    _queue = [item];
    _currentIndex = 0;
    _shuffle = false;
    _isActive = true;
    _isExpanded = true;
    notifyListeners();
    _controller.loadVideoById(videoId: videoId);
  }
  void playQueue({required List<NowPlayingItem> items, int startIndex = 0, bool shuffle = false}) {
    if (items.isEmpty) return;
    _originalOrder = List.from(items);
    _queue = List.from(items);
    _currentIndex = startIndex.clamp(0, _queue.length - 1);
    _shuffle = shuffle;
    if (_shuffle) {
      final current = _queue[_currentIndex];
      final rest = List<NowPlayingItem>.from(_queue)..removeAt(_currentIndex);
      rest.shuffle(Random());
      _queue = [current, ...rest];
      _currentIndex = 0;
    }
    _isActive = true;
    _isExpanded = true;
    notifyListeners();
    _controller.loadVideoById(videoId: _queue[_currentIndex].videoId);
  }

  void toggleShuffle() {
    if (_queue.isEmpty) return;
    final current = _queue[_currentIndex];
    _shuffle = !_shuffle;
    if (_shuffle) {
      final rest = List<NowPlayingItem>.from(_originalOrder)
        ..removeWhere((item) => item.videoId == current.videoId);
      rest.shuffle(Random());
      _queue = [current, ...rest];
      _currentIndex = 0;
    } else {
      _queue = List.from(_originalOrder);
      _currentIndex = _queue.indexWhere((item) => item.videoId == current.videoId);
    }
    notifyListeners();
  }

  void cycleLoopMode() {
    _loopMode = switch (_loopMode) {
      LoopMode.off => LoopMode.playlist,
      LoopMode.playlist => LoopMode.single,
      LoopMode.single => LoopMode.off,
    };
    notifyListeners();
  }

  void playAt(int index) {
    if (index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    _controller.loadVideoById(videoId: _queue[index].videoId);
    notifyListeners();
  }

  void next() {
    int nextIndex = _currentIndex + 1;
    if (nextIndex >= _queue.length) {
      if (_loopMode == LoopMode.playlist) {
        nextIndex = 0;
      } else {
        return;
      }
    }
    playAt(nextIndex);
  }

  void previous() {
    int prevIndex = _currentIndex - 1;
    if (prevIndex < 0) {
      if (_loopMode == LoopMode.playlist) {
        prevIndex = _queue.length - 1;
      } else {
        return;
      }
    }
    playAt(prevIndex);
  }

  void togglePlayPause() {
    if (isPlaying) {
      _controller.pauseVideo();
    } else {
      _controller.playVideo();
    }
  }

  void expand() {
    _isExpanded = true;
    notifyListeners();
  }

  void collapse() {
    _isExpanded = false;
    notifyListeners();
  }

  void closeMiniPlayer() {
    _isActive = false;
    _isExpanded = false;
    _controller.pauseVideo();
    notifyListeners();
  }
}