import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../services/player_manager.dart';

class PersistentPlayerOverlay extends StatelessWidget {
  const PersistentPlayerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = PlayerManager.instance;

    return AnimatedBuilder(
      animation: manager,
      builder: (context, _) {
        final active = manager.isActive;
        final expanded = manager.isExpanded;
        final screenWidth = MediaQuery.of(context).size.width;
        final videoWidth = expanded ? screenWidth : 120.0;

        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          top: (active && expanded) ? 0 : null,
          child: Visibility(
            visible: active,
            maintainState: true,
            maintainAnimation: true,
            maintainSize: false,
            child: Material(
              color: const Color(0xFF181818),
              child: SafeArea(
                top: expanded,
                bottom: !expanded,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (expanded)
                      AppBar(
                        backgroundColor: const Color(0xFF0F0F0F),
                        leading: IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down),
                          onPressed: manager.collapse,
                        ),
                        title: const Text('Now Playing'),
                      ),
                    GestureDetector(
                      onTap: expanded ? null : manager.expand,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: videoWidth,
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: YoutubePlayerScaffold(
                                controller: manager.controller,
                                autoFullScreen: true,
                                fullscreenOrientations: const [
                                  DeviceOrientation.landscapeLeft,
                                  DeviceOrientation.landscapeRight,
                                ],
                                builder: (context, player) => player,
                              ),
                            ),
                          ),
                          if (!expanded) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                manager.currentItem?.title ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                            IconButton(
                              icon: Icon(manager.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                              onPressed: manager.togglePlayPause,
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white54),
                              onPressed: manager.closeMiniPlayer,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (expanded) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.skip_previous, size: 32, color: Colors.white),
                              onPressed: manager.previous,
                            ),
                            IconButton(
                              icon: Icon(manager.shuffle ? Icons.shuffle_on_outlined : Icons.shuffle, size: 28),
                              color: manager.shuffle ? Colors.red : Colors.white,
                              onPressed: manager.toggleShuffle,
                            ),
                            IconButton(
                              icon: Icon(_loopIcon(manager.loopMode), size: 28),
                              color: manager.loopMode == LoopMode.off ? Colors.white : Colors.red,
                              onPressed: manager.cycleLoopMode,
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_next, size: 32, color: Colors.white),
                              onPressed: manager.next,
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white24, height: 1),
                      Expanded(
                        child: manager.queue.length <= 1
                            ? const SizedBox.shrink()
                            : ListView.builder(
                          itemCount: manager.queue.length,
                          itemBuilder: (context, index) {
                            final item = manager.queue[index];
                            final isCurrent = index == manager.currentIndex;
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  item.thumbnailUrl.isNotEmpty
                                      ? item.thumbnailUrl
                                      : YoutubePlayerController.getThumbnail(videoId: item.videoId),
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
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isCurrent ? Colors.red : Colors.white,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              trailing: isCurrent ? const Icon(Icons.equalizer, color: Colors.red) : null,
                              onTap: () => manager.playAt(index),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _loopIcon(LoopMode mode) {
    switch (mode) {
      case LoopMode.off:
        return Icons.repeat;
      case LoopMode.playlist:
        return Icons.repeat_on_outlined;
      case LoopMode.single:
        return Icons.repeat_one_on_outlined;
    }
  }
}