import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'feed_video.dart';

/// Eén item in de viewer: een foto of een video.
class MediaItem {
  const MediaItem({required this.url, this.video = false, this.poster});
  final String url;
  final bool video;
  final String? poster;
}

/// Fullscreen viewer: swipen tussen de media van een bericht, pinch-zoom op foto's, tikken op
/// ✕ of terug om te sluiten.
///
/// Toonde eerst alléén foto's. Zette iemand foto's én video's in één bericht, dan sloeg de
/// viewer de video's over: in de feed zag je ze wel, maar zodra je op een foto tikte waren ze
/// weg (Richard 21-09-2026).
class PhotoViewer extends StatefulWidget {
  final List<MediaItem> items;
  final int initialIndex;
  const PhotoViewer({super.key, required this.items, this.initialIndex = 0});

  /// Alleen foto's — blijft bestaan voor plekken waar er niets anders is (vangstfoto's e.d.).
  static void open(BuildContext context, List<String> urls, [int index = 0]) =>
      openMedia(context, [for (final u in urls) MediaItem(url: u)], index);

  static void openMedia(BuildContext context, List<MediaItem> items, [int index = 0]) {
    if (items.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PhotoViewer(items: items, initialIndex: index.clamp(0, items.length - 1))));
  }

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late final PageController _page = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() { _page.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PageView.builder(
          controller: _page,
          itemCount: widget.items.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) {
            final m = widget.items[i];
            if (m.video) {
              return Center(child: FeedVideo(videoUrl: m.url, poster: m.poster, autoplay: i == _index));
            }
            return InteractiveViewer(
              maxScale: 5,
              child: Center(child: CachedNetworkImage(
                imageUrl: m.url,
                fit: BoxFit.contain,
                progressIndicatorBuilder: (_, __, p) => Center(child: CircularProgressIndicator(value: p.progress, color: Colors.white54)),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white38, size: 48),
              )),
            );
          },
        ),
        SafeArea(child: Align(alignment: Alignment.topRight, child: Padding(
          padding: const EdgeInsets.all(4),
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            style: IconButton.styleFrom(backgroundColor: Colors.white12),
            onPressed: () => Navigator.pop(context),
          ),
        ))),
        if (widget.items.length > 1) SafeArea(child: Align(alignment: Alignment.bottomCenter, child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(999)),
            child: Text('${_index + 1} / ${widget.items.length}', style: const TextStyle(color: Colors.white)),
          ),
        ))),
      ]),
    );
  }
}
