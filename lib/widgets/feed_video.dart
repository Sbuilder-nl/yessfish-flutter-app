import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/config.dart';
import '../core/i18n.dart';

/// Rendert de video van een feed-post:
///  - YouTube (youtubeId): thumbnail + play → opent YouTube (url_launcher).
///  - Zelf-gehoste MP4 (videoUrl + ready): tap-to-play; of muted-autoplay-in-beeld als [autoplay] aanstaat
///    (voor sponsored posts, Facebook-stijl).
///  - MP4 nog aan het transcoderen (!ready): "verwerken…"-plaatsvervanger.
class FeedVideo extends StatefulWidget {
  final String? videoUrl;
  final String? poster;
  final String? youtubeId;
  final bool ready;
  final bool autoplay;
  const FeedVideo({super.key, this.videoUrl, this.poster, this.youtubeId, this.ready = true, this.autoplay = false});

  @override
  State<FeedVideo> createState() => _FeedVideoState();
}

class _FeedVideoState extends State<FeedVideo> {
  VideoPlayerController? _c;
  bool _init = false;

  @override
  void dispose() { _c?.dispose(); super.dispose(); }

  Future<void> _ensureController() async {
    if (_c != null) return;
    _c = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!));
    await _c!.initialize();
    _c!.setLooping(widget.autoplay);
    if (widget.autoplay) _c!.setVolume(0);
    if (mounted) setState(() => _init = true);
  }

  Future<void> _tapPlay() async {
    await _ensureController();
    _c!.play();
    if (mounted) setState(() {});
  }

  void _onVisibility(double fraction) async {
    if (!widget.autoplay) return;
    await _ensureController();
    if (fraction > 0.6) { _c?.play(); } else { _c?.pause(); }
    if (mounted) setState(() {});
  }

  Widget _frame(Widget child) => ClipRRect(borderRadius: BorderRadius.circular(12), child: AspectRatio(aspectRatio: (_init && _c != null && _c!.value.aspectRatio > 0) ? _c!.value.aspectRatio : 16 / 9, child: child));

  @override
  Widget build(BuildContext context) {
    // YouTube — thumbnail + play → open in YouTube
    if (widget.youtubeId != null && widget.youtubeId!.isNotEmpty) {
      final yt = widget.youtubeId!;
      return GestureDetector(
        onTap: () => launchUrl(Uri.parse('https://www.youtube.com/watch?v=$yt'), mode: LaunchMode.externalApplication),
        child: ClipRRect(borderRadius: BorderRadius.circular(12), child: AspectRatio(aspectRatio: 16 / 9, child: Stack(fit: StackFit.expand, children: [
          CachedNetworkImage(imageUrl: 'https://i.ytimg.com/vi/$yt/hqdefault.jpg', fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: Colors.black12)),
          const Center(child: _PlayBadge(color: Color(0xCCFF0000))),
        ]))),
      );
    }

    // Geen video
    if (widget.videoUrl == null || widget.videoUrl!.isEmpty) return const SizedBox.shrink();

    // MP4 nog aan het verwerken
    if (!widget.ready) {
      return _frame(Container(color: const Color(0xFFECF1F4), child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal)),
        const SizedBox(width: 8), Text(context.tr('feed.video_processing'), style: const TextStyle(color: Colors.black45, fontSize: 13)),
      ]))));
    }

    final player = (_init && _c != null)
        ? Stack(alignment: Alignment.center, children: [
            VideoPlayer(_c!),
            if (!widget.autoplay) GestureDetector(
              onTap: () { _c!.value.isPlaying ? _c!.pause() : _c!.play(); setState(() {}); },
              child: AnimatedOpacity(opacity: _c!.value.isPlaying ? 0 : 1, duration: const Duration(milliseconds: 200), child: const _PlayBadge(color: Color(0x8C000000))),
            ),
            if (!widget.autoplay) Positioned(left: 0, right: 0, bottom: 0, child: VideoProgressIndicator(_c!, allowScrubbing: true, colors: const VideoProgressColors(playedColor: AppColors.teal))),
          ])
        : Stack(fit: StackFit.expand, children: [
            if (widget.poster != null) CachedNetworkImage(imageUrl: widget.poster!, fit: BoxFit.cover) else Container(color: Colors.black),
            if (!widget.autoplay) GestureDetector(onTap: _tapPlay, child: const Center(child: _PlayBadge(color: Color(0x8C000000)))),
          ]);

    final content = _frame(Container(color: Colors.black, child: player));

    // Autoplay-in-beeld voor sponsored
    if (widget.autoplay) {
      return VisibilityDetector(key: Key('vid-${widget.videoUrl}'), onVisibilityChanged: (info) => _onVisibility(info.visibleFraction), child: content);
    }
    return content;
  }
}

class _PlayBadge extends StatelessWidget {
  final Color color;
  const _PlayBadge({required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 58, height: 58,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: const Icon(Icons.play_arrow, color: Colors.white, size: 34),
  );
}
