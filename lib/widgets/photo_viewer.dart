import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Fullscreen foto-viewer: swipen tussen foto's, pinch-zoom, tikken op ✕ of terug om te sluiten.
class PhotoViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  const PhotoViewer({super.key, required this.urls, this.initialIndex = 0});

  static void open(BuildContext context, List<String> urls, [int index = 0]) {
    if (urls.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => PhotoViewer(urls: urls, initialIndex: index)));
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
          itemCount: widget.urls.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) => InteractiveViewer(
            maxScale: 5,
            child: Center(child: CachedNetworkImage(
              imageUrl: widget.urls[i],
              fit: BoxFit.contain,
              progressIndicatorBuilder: (_, __, p) => Center(child: CircularProgressIndicator(value: p.progress, color: Colors.white54)),
              errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white38, size: 48),
            )),
          ),
        ),
        SafeArea(child: Align(alignment: Alignment.topRight, child: Padding(
          padding: const EdgeInsets.all(4),
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            style: IconButton.styleFrom(backgroundColor: Colors.white12),
            onPressed: () => Navigator.pop(context),
          ),
        ))),
        if (widget.urls.length > 1) SafeArea(child: Align(alignment: Alignment.bottomCenter, child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(999)),
            child: Text('${_index + 1} / ${widget.urls.length}', style: const TextStyle(color: Colors.white)),
          ),
        ))),
      ]),
    );
  }
}
