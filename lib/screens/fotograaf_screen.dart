import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/fotograaf_i18n.dart';
import '../widgets/email_typo_hint.dart';
import '../widgets/photo_viewer.dart';
import 'fotograaf_portaal_screen.dart';

/// Openbare fotograafpagina (06-10-2026) — hetzelfde als yessfish.com/fotograaf/<slug>:
/// portfolio, albums, wateren in beeld, over mij en het aanvraagformulier.
class FotograafScreen extends StatefulWidget {
  final String slug;
  final String? naam;
  const FotograafScreen({super.key, required this.slug, this.naam});

  @override
  State<FotograafScreen> createState() => _FotograafScreenState();
}

class _FotograafScreenState extends State<FotograafScreen> {
  Map? _p;
  bool _laden = true, _weg = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await Api.get('/photographers/${Uri.encodeComponent(widget.slug)}');
      _p = Map.from(r['data']);
    } catch (e) {
      _weg = e is ApiException && e.status == 404;
    }
    if (mounted) setState(() => _laden = false);
  }

  void _openFotos(List fotos, int i) {
    PhotoViewer.open(context, [for (final f in fotos) '${f['url']}'], i);
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    return Scaffold(
      appBar: AppBar(
        title: Text(p?['name'] ?? widget.naam ?? ft(context, 'pub_photographer')),
        actions: [
          if (p != null) IconButton(tooltip: ft(context, 'pub_share'), icon: const Icon(Icons.share_outlined),
            onPressed: () => Share.share('${p['name']} — ${ft(context, 'pub_on_yessfish')}\n${p['share_url'] ?? '${Config.webOrigin}/fotograaf/${widget.slug}'}')),
        ],
      ),
      body: _laden
          ? const Center(child: CircularProgressIndicator())
          : p == null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_weg ? ft(context, 'pub_not_found') : ft(context, 'app_error'), textAlign: TextAlign.center)))
              : RefreshIndicator(onRefresh: _load, child: _inhoud(p)),
    );
  }

  Widget _kop(String t) => Padding(padding: const EdgeInsets.fromLTRB(0, 22, 0, 10),
    child: Text(t, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.navy)));

  Widget _inhoud(Map p) {
    final fotos = (p['photos'] as List?) ?? [];
    final albums = (p['albums'] as List?) ?? [];
    final wateren = (p['waters'] as List?) ?? [];
    final posts = (p['posts'] as List?) ?? [];
    final specs = ((p['specialties'] as List?) ?? []).map((s) => ft(context, 'spec_$s')).toList();
    final links = (p['links'] is List) ? p['links'] as List : const [];
    final stats = (p['stats'] as Map?) ?? {};
    return ListView(padding: EdgeInsets.only(bottom: 24 + MediaQuery.of(context).padding.bottom), children: [
      // Omslag + logo
      Stack(clipBehavior: Clip.none, children: [
        AspectRatio(aspectRatio: 2.4, child: p['cover'] != null
            ? CachedNetworkImage(imageUrl: '${p['cover']}', fit: BoxFit.cover)
            : Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.navy, AppColors.teal])))),
        Positioned(left: 16, bottom: -34, child: Container(
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), color: Colors.white),
          child: CircleAvatar(radius: 38, backgroundColor: AppColors.bg,
            backgroundImage: p['logo'] != null ? CachedNetworkImageProvider('${p['logo']}') : null,
            child: p['logo'] == null ? const Icon(Icons.photo_camera_outlined, color: AppColors.teal, size: 32) : null))),
      ]),
      Padding(padding: const EdgeInsets.fromLTRB(16, 42, 16, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${p['name']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy)),
        const SizedBox(height: 2),
        Text(['📷 ${ft(context, 'pub_photographer')}', if ((p['city'] ?? '').toString().isNotEmpty) '${p['city']}'].join(' · '),
          style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 6),
        Text([ft(context, 'pub_photos', {'n': stats['photos'] ?? fotos.length}), if ((stats['albums'] ?? 0) > 0) '${stats['albums']} ${ft(context, 'pub_albums').toLowerCase()}'].join(' · '),
          style: const TextStyle(fontSize: 12.5, color: Colors.black45)),
        if (specs.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Wrap(spacing: 6, runSpacing: 6, children: [
          for (final s in specs) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(s, style: const TextStyle(fontSize: 12, color: AppColors.teal, fontWeight: FontWeight.w600))),
        ])),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (p['booking'] == true) FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
            onPressed: _contact, icon: const Icon(Icons.mail_outline, size: 18), label: Text(ft(context, 'pub_book'))),
          if ((p['website'] ?? '').toString().isNotEmpty) OutlinedButton.icon(
            onPressed: () => _open('${p['website']}'), icon: const Icon(Icons.language, size: 18), label: const Text('Website')),
          for (final l in links) if (l is Map && (l['url'] ?? '').toString().isNotEmpty) OutlinedButton.icon(
            onPressed: () => _open('${l['url']}'), icon: Icon(socialIcoon(l['kind']?.toString()), size: 18),
            label: Text('${l['label'] ?? l['kind'] ?? 'Link'}')),
          if (p['can_manage'] == true) OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FotograafPortaalScreen(partnerId: p['id'] as int, naam: '${p['name']}'))),
            icon: const Icon(Icons.edit_outlined, size: 18), label: Text(ft(context, 'pub_manage'))),
        ]),
        if (fotos.isNotEmpty) ...[
          _kop(ft(context, 'pub_portfolio')),
          _grid(fotos),
        ],
        if (albums.isNotEmpty) ...[
          _kop(ft(context, 'pub_albums')),
          for (final a in albums) Card(margin: const EdgeInsets.only(bottom: 8), clipBehavior: Clip.antiAlias, child: ListTile(
            contentPadding: const EdgeInsets.only(right: 12),
            leading: SizedBox(width: 72, height: 72, child: a['cover'] != null ? CachedNetworkImage(imageUrl: '${a['cover']}', fit: BoxFit.cover) : Container(color: AppColors.bg, child: const Icon(Icons.photo_library_outlined, color: AppColors.teal))),
            title: Text('${a['title']}', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(ft(context, 'photos_count', {'n': a['photos_count'] ?? 0})),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FotograafAlbumScreen(slug: widget.slug, albumSlug: '${a['slug']}', titel: '${a['title']}'))),
          )),
        ],
        if (wateren.isNotEmpty) ...[
          _kop(ft(context, 'pub_waters')),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final w in wateren) Chip(avatar: const Icon(Icons.water, size: 16, color: AppColors.teal),
              label: Text('${w['name'] ?? ''} (${w['photos']})', style: const TextStyle(fontSize: 12.5))),
          ]),
        ],
        if ((p['description'] ?? '').toString().trim().isNotEmpty) ...[
          _kop(ft(context, 'pub_about')),
          Text('${p['description']}', style: const TextStyle(fontSize: 15, height: 1.4)),
        ],
        if (posts.isNotEmpty) ...[
          _kop(ft(context, 'pub_latest')),
          for (final x in posts) Card(margin: const EdgeInsets.only(bottom: 8), clipBehavior: Clip.antiAlias, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (x['image'] != null) GestureDetector(onTap: () => PhotoViewer.open(context, ['${x['image']}']),
              child: AspectRatio(aspectRatio: 16 / 10, child: CachedNetworkImage(imageUrl: '${x['image']}', fit: BoxFit.cover))),
            Padding(padding: const EdgeInsets.all(12), child: Text('${x['content'] ?? ''}', maxLines: 6, overflow: TextOverflow.ellipsis)),
          ])),
        ],
        if (p['booking'] == true) Padding(padding: const EdgeInsets.only(top: 20), child: SizedBox(width: double.infinity, child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(vertical: 14)),
          onPressed: _contact, icon: const Icon(Icons.mail_outline), label: Text(ft(context, 'pub_contact'))))),
      ])),
    ]);
  }

  Widget _grid(List fotos) => GridView.builder(
    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: fotos.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 4, crossAxisSpacing: 4),
    itemBuilder: (_, i) => GestureDetector(onTap: () => _openFotos(fotos, i),
      child: ClipRRect(borderRadius: BorderRadius.circular(6), child: CachedNetworkImage(imageUrl: '${fotos[i]['thumb'] ?? fotos[i]['url']}', fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(color: Colors.black12)))),
  );

  Future<void> _open(String url) async {
    final u = Uri.tryParse(url.startsWith('http') ? url : 'https://$url');
    if (u != null) await launchUrl(u, mode: LaunchMode.externalApplication);
  }

  /// Aanvraagformulier. 'elapsed' = hoe lang het formulier open stond (anti-spam, zoals op de site).
  Future<void> _contact() async {
    final start = DateTime.now();
    final naam = TextEditingController(), mail = TextEditingController(), tel = TextEditingController(),
        onderwerp = TextEditingController(), bericht = TextEditingController();
    DateTime? datum;
    bool bezig = false;
    await showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
      Future<void> stuur() async {
        if (naam.text.trim().isEmpty || !mail.text.contains('@') || bericht.text.trim().length < 10) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ft(context, 'app_fill_required')))); return;
        }
        setS(() => bezig = true);
        try {
          await Api.post('/photographers/${Uri.encodeComponent(widget.slug)}/inquiry', {
            'name': naam.text.trim(), 'email': mail.text.trim(),
            'phone': tel.text.trim().isEmpty ? null : tel.text.trim(),
            'subject': onderwerp.text.trim().isEmpty ? null : onderwerp.text.trim(),
            'message': bericht.text.trim(),
            'wish_date': datum == null ? null : '${datum!.year}-${datum!.month.toString().padLeft(2, '0')}-${datum!.day.toString().padLeft(2, '0')}',
            'elapsed': DateTime.now().difference(start).inMilliseconds,
          });
          if (ctx.mounted) Navigator.pop(ctx);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ft(context, 'pub_sent'))));
        } catch (e) {
          setS(() => bezig = false);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : ft(context, 'app_error'))));
        }
      }
      InputDecoration dec(String l) => InputDecoration(labelText: l, border: const OutlineInputBorder(), isDense: true);
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(ctx).padding.bottom), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(ft(context, 'pub_contact'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 12),
          TextField(controller: naam, decoration: dec(ft(context, 'pub_name')), textCapitalization: TextCapitalization.words),
          const SizedBox(height: 10),
          TextField(controller: mail, decoration: dec(ft(context, 'pub_email')), keyboardType: TextInputType.emailAddress),
          EmailTypoHint(controller: mail),
          const SizedBox(height: 10),
          TextField(controller: tel, decoration: dec(ft(context, 'pub_phone')), keyboardType: TextInputType.phone),
          const SizedBox(height: 10),
          TextField(controller: onderwerp, decoration: dec(ft(context, 'pub_subject'))),
          const SizedBox(height: 10),
          TextField(controller: bericht, decoration: dec(ft(context, 'pub_message')), minLines: 4, maxLines: 8),
          const SizedBox(height: 10),
          OutlinedButton.icon(icon: const Icon(Icons.event, size: 18),
            label: Text(datum == null ? ft(context, 'pub_wish_date') : '${datum!.day}-${datum!.month}-${datum!.year}'),
            onPressed: () async {
              final n = DateTime.now();
              final d = await showDatePicker(context: ctx, firstDate: DateTime(n.year, n.month, n.day), lastDate: DateTime(n.year + 2), initialDate: datum ?? n);
              if (d != null) setS(() => datum = d);
            }),
          const SizedBox(height: 6),
          Text(ft(context, 'pub_privacy'), style: const TextStyle(fontSize: 11.5, color: Colors.black45)),
          const SizedBox(height: 12),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: bezig ? null : stuur,
            child: bezig ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(ft(context, 'pub_send'))),
        ])),
      );
    }));
  }
}

/// Album van een fotograaf (openbaar).
class FotograafAlbumScreen extends StatefulWidget {
  final String slug, albumSlug;
  final String? titel;
  const FotograafAlbumScreen({super.key, required this.slug, required this.albumSlug, this.titel});

  @override
  State<FotograafAlbumScreen> createState() => _FotograafAlbumScreenState();
}

class _FotograafAlbumScreenState extends State<FotograafAlbumScreen> {
  Map? _a;
  bool _laden = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Api.get('/photographers/${Uri.encodeComponent(widget.slug)}/albums/${Uri.encodeComponent(widget.albumSlug)}');
      _a = Map.from(r['data']);
    } catch (_) {}
    if (mounted) setState(() => _laden = false);
  }

  @override
  Widget build(BuildContext context) {
    final a = _a;
    final fotos = (a?['photos'] as List?) ?? [];
    return Scaffold(
      appBar: AppBar(title: Text(a?['title'] ?? widget.titel ?? ft(context, 'album'))),
      body: _laden ? const Center(child: CircularProgressIndicator()) : a == null
          ? Center(child: Text(ft(context, 'app_error')))
          : ListView(padding: EdgeInsets.fromLTRB(12, 12, 12, 24 + MediaQuery.of(context).padding.bottom), children: [
              InkWell(onTap: () => Navigator.pop(context), child: Text(ft(context, 'pub_back', {'name': (a['photographer'] as Map?)?['name'] ?? ''}),
                style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600))),
              if ((a['description'] ?? '').toString().trim().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text('${a['description']}', style: const TextStyle(fontSize: 15, height: 1.4))),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: fotos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 4, crossAxisSpacing: 4),
                itemBuilder: (_, i) => GestureDetector(onTap: () => PhotoViewer.open(context, [for (final f in fotos) '${f['url']}'], i),
                  child: ClipRRect(borderRadius: BorderRadius.circular(6), child: CachedNetworkImage(imageUrl: '${fotos[i]['thumb'] ?? fotos[i]['url']}', fit: BoxFit.cover)))),
            ]),
    );
  }
}
