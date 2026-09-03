import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/config.dart';
import 'feed_video.dart';
import 'photo_viewer.dart';

/// Carrousel voor een feedpost met meerdere media (foto's en video's gemengd).
/// Swipen tussen items, stipjes + teller, foto's openen fullscreen in de PhotoViewer.
class MediaCarousel extends StatefulWidget {
  final List media; // [{type, url, poster, ready}]
  const MediaCarousel({super.key, required this.media});

  @override
  State<MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<MediaCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final media = widget.media;
    if (media.isEmpty) return const SizedBox.shrink();
    // Alle foto-URL's voor de fullscreen-viewer (video's doen daar niet aan mee).
    final fotoUrls = [for (final m in media) if (m['type'] == 'image' && m['url'] != null) m['url'].toString()];
    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 280,
          width: double.infinity,
          child: PageView.builder(
            itemCount: media.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) {
              final m = media[i] as Map;
              if (m['type'] == 'video') {
                return Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: FeedVideo(
                    videoUrl: m['url']?.toString(),
                    poster: m['poster']?.toString(),
                    ready: m['ready'] != false,
                  ),
                );
              }
              final url = m['url']?.toString() ?? '';
              return GestureDetector(
                onTap: () => PhotoViewer.open(context, fotoUrls, fotoUrls.indexOf(url).clamp(0, fotoUrls.length - 1)),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: const Color(0xFFECF1F4), child: const Icon(Icons.broken_image, color: Colors.black26)),
                ),
              );
            },
          ),
        ),
      ),
      if (media.length > 1)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < media.length; i++)
              Container(
                width: i == _index ? 9 : 6,
                height: i == _index ? 9 : 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _index ? AppColors.teal : Colors.black26,
                ),
              ),
            const SizedBox(width: 8),
            Text('${_index + 1}/${media.length}', style: const TextStyle(fontSize: 11, color: Colors.black38)),
          ]),
        ),
    ]);
  }
}
