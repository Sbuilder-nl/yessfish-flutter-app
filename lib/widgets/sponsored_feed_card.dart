import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import 'feed_video.dart';

/// Feed-kaart voor een sponsored post ("Gesponsord"-label + adverteerder + media + klik-door-knop).
/// Video's spelen muted-autoplay-in-beeld (Facebook-stijl). Klik telt door via /sponsored/{id}/click.
class SponsoredFeedCard extends StatelessWidget {
  final Map sp;
  const SponsoredFeedCard(this.sp, {super.key});

  Future<void> _open(BuildContext context) async {
    final link = sp['link_url']?.toString();
    if (link == null || link.isEmpty) return;
    String url = link;
    try {
      final r = await Api.post('/sponsored/${sp['sponsored_id']}/click');
      if (r is Map && r['url'] != null) url = r['url'].toString();
    } catch (_) {}
    try { await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final adv = sp['advertiser'] as Map?;
    final name = adv?['name']?.toString() ?? context.tr('sponsored.advertiser');
    final logo = adv?['logo_path']?.toString();
    final title = sp['title']?.toString();
    final body = sp['content']?.toString();
    final img = sp['image_path']?.toString();
    final video = sp['video_path']?.toString();
    final yt = sp['youtube_id']?.toString();
    final cta = (sp['cta_label']?.toString().isNotEmpty ?? false) ? sp['cta_label'].toString() : context.tr('sponsored.cta');
    final hasLink = (sp['link_url']?.toString().isNotEmpty ?? false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0x261F8A70))),
      child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 19, backgroundColor: const Color(0x141F8A70),
            backgroundImage: (logo != null && logo.isNotEmpty) ? CachedNetworkImageProvider(logo) : null,
            child: (logo == null || logo.isEmpty) ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'A', style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.bold)) : null),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
            Text(context.tr('sponsored.label').toUpperCase(), style: const TextStyle(fontSize: 10.5, letterSpacing: 0.5, color: Colors.black38, fontWeight: FontWeight.w600)),
          ])),
        ]),
        if (title != null && title.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy))),
        if (body != null && body.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(body, style: const TextStyle(fontSize: 14.5))),
        if (video != null && video.isNotEmpty || (yt != null && yt.isNotEmpty))
          Padding(padding: const EdgeInsets.only(top: 10), child: FeedVideo(videoUrl: video, poster: sp['video_poster']?.toString(), youtubeId: yt, ready: sp['video_ready'] != false, autoplay: true))
        else if (img != null && img.isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 10), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: img, width: double.infinity, fit: BoxFit.cover))),
        if (hasLink) Padding(padding: const EdgeInsets.only(top: 12), child: SizedBox(width: double.infinity, child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
          onPressed: () => _open(context), icon: const Icon(Icons.open_in_new, size: 17), label: Text(cta)))),
      ])),
    );
  }
}
