import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/fotograaf_i18n.dart';
import '../widgets/photo_viewer.dart';
import 'fotograaf_screen.dart';
import 'gids_screen.dart' show openWebPagina;

/// Fotograafportaal in de app (06-10-2026) — dezelfde tabbladen als het partnerpaneel op de site:
/// Foto's · Albums · Feedbericht · Instellingen · Aanvragen. Het profiel zelf (naam, logo, over mij,
/// links) blijft op de site; daar gaat een knop heen via de inlogbrug.
class FotograafPortaalScreen extends StatefulWidget {
  final int partnerId;
  final String naam;
  final String? slug;
  final String status;
  const FotograafPortaalScreen({super.key, required this.partnerId, required this.naam, this.slug, this.status = 'approved'});

  @override
  State<FotograafPortaalScreen> createState() => _FotograafPortaalScreenState();
}

String _fout(BuildContext c, Object e) => e is ApiException ? e.message : ft(c, 'app_error');
void _melding(BuildContext c, String t) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(t)));

class _FotograafPortaalScreenState extends State<FotograafPortaalScreen> {
  int get id => widget.partnerId;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (Icons.photo_library_outlined, ft(context, 'tab_photos')),
      (Icons.collections_bookmark_outlined, ft(context, 'tab_albums')),
      (Icons.dynamic_feed_outlined, ft(context, 'tab_feedpost')),
      (Icons.tune, ft(context, 'tab_settings')),
      (Icons.mail_outline, ft(context, 'tab_inquiries')),
    ];
    return DefaultTabController(length: tabs.length, child: Scaffold(
      appBar: AppBar(
        title: Text(widget.naam, overflow: TextOverflow.ellipsis),
        actions: [
          if (widget.slug != null) IconButton(tooltip: ft(context, 'pub_on_yessfish'), icon: const Icon(Icons.visibility_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FotograafScreen(slug: widget.slug!, naam: widget.naam)))),
        ],
        // Geen scrollende tabbalk (Richard 06-10: "dit stuk heeft scrols is niet heel handig"):
        // vijf vaste tabs met icoon + kort label.
        bottom: TabBar(
          labelPadding: EdgeInsets.zero,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          tabs: [for (final t in tabs) Tab(height: 58, icon: Icon(t.$1, size: 21), child: FittedBox(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Text(t.$2))))],
        ),
      ),
      body: widget.status != 'approved'
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(ft(context, 'app_pending'), textAlign: TextAlign.center)))
          : TabBarView(children: [
              _FotosTab(partnerId: id),
              _AlbumsTab(partnerId: id),
              _FeedTab(partnerId: id),
              _InstellingenTab(partnerId: id, naam: widget.naam),
              _AanvragenTab(partnerId: id),
            ]),
    ));
  }
}

// ─────────────────────────────── Foto's ───────────────────────────────

class _FotosTab extends StatefulWidget {
  final int partnerId;
  const _FotosTab({required this.partnerId});
  @override
  State<_FotosTab> createState() => _FotosTabState();
}

class _FotosTabState extends State<_FotosTab> with AutomaticKeepAliveClientMixin {
  List _fotos = [], _albums = [];
  bool _laden = true, _origineel = true;
  int? _albumFilter, _uploadAlbum;
  Map? _water;
  String? _voortgang;

  @override
  bool get wantKeepAlive => true;
  String get _basis => '/partner/${widget.partnerId}';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await Api.get('$_basis/photos${_albumFilter != null ? '?album_id=$_albumFilter' : ''}');
      _fotos = (r['data'] as List?) ?? [];
      final a = await Api.get('$_basis/albums');
      _albums = (a['data'] as List?) ?? [];
    } catch (_) {}
    if (mounted) setState(() => _laden = false);
  }

  Future<void> _upload(ImageSource bron) async {
    // Geen maxWidth/imageQuality: de app stuurt de foto zoals hij is. De server maakt de webversie
    // en bewaart het origineel alleen als 'Origineel bewaren' aan staat.
    final picker = ImagePicker();
    final List<XFile> lijst;
    if (bron == ImageSource.camera) {
      final x = await picker.pickImage(source: ImageSource.camera);
      lijst = x == null ? [] : [x];
    } else {
      lijst = await picker.pickMultiImage();
    }
    if (lijst.isEmpty || !mounted) return;
    var gelukt = 0;
    for (var i = 0; i < lijst.length; i++) {
      setState(() => _voortgang = ft(context, 'uploading', {'n': i + 1, 'total': lijst.length}));
      try {
        await Api.uploadMet('$_basis/photos', await _alsJpeg(lijst[i].path), {
          'keep_original': _origineel ? '1' : '0',
          if (_uploadAlbum != null) 'album_id': '$_uploadAlbum',
          if (_water?['id'] != null) 'water_id': '${_water!['id']}',
        }, timeout: const Duration(minutes: 10));
        gelukt++;
      } catch (e) {
        if (mounted) _melding(context, '${ft(context, 'upload_failed_one', {'name': lijst[i].name})} — ${_fout(context, e)}');
      }
    }
    if (!mounted) return;
    setState(() => _voortgang = null);
    if (gelukt > 0) _melding(context, ft(context, 'upload_done', {'n': gelukt}));
    _load();
  }

  /// HEIC/HEIF (iPhone-formaat, ook op sommige Android-toestellen) neemt de server niet aan:
  /// omzetten naar JPEG op volle grootte, kwaliteit 95. Andere bestanden gaan ongewijzigd.
  Future<String> _alsJpeg(String pad) async {
    final l = pad.toLowerCase();
    if (!l.endsWith('.heic') && !l.endsWith('.heif')) return pad;
    final doel = '${(await getTemporaryDirectory()).path}/fg-${DateTime.now().microsecondsSinceEpoch}.jpg';
    final x = await FlutterImageCompress.compressAndGetFile(pad, doel, quality: 95, minWidth: 10000, minHeight: 10000, keepExif: true, format: CompressFormat.jpeg);
    return x?.path ?? pad;
  }

  Future<void> _kiesWater() async {
    final w = await kiesWater(context, huidig: _water != null);
    if (w == null) return;
    setState(() => _water = w.isEmpty ? null : w);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_laden) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(onRefresh: _load, child: ListView(padding: EdgeInsets.fromLTRB(14, 14, 14, 24 + MediaQuery.of(context).padding.bottom), children: [
      Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(ft(context, 'upload_title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
        const SizedBox(height: 4),
        Text(ft(context, 'upload_hint'), style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 10),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: true, label: Text(ft(context, 'keep_original')), icon: const Icon(Icons.high_quality_outlined, size: 18)),
            ButtonSegment(value: false, label: Text(ft(context, 'compressed')), icon: const Icon(Icons.compress, size: 18)),
          ],
          selected: {_origineel},
          onSelectionChanged: (s) => setState(() => _origineel = s.first),
        ),
        const SizedBox(height: 6),
        Text(ft(context, _origineel ? 'keep_original_hint' : 'compressed_hint'), style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 10),
        Text(ft(context, 'app_upload_where'), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: DropdownButtonFormField<int?>(
            initialValue: _uploadAlbum, isExpanded: true,
            decoration: InputDecoration(labelText: ft(context, 'album'), isDense: true, border: const OutlineInputBorder()),
            items: [DropdownMenuItem(value: null, child: Text(ft(context, 'no_album'))),
              for (final a in _albums) DropdownMenuItem(value: a['id'] as int, child: Text('${a['title']}', overflow: TextOverflow.ellipsis))],
            onChanged: (v) => setState(() => _uploadAlbum = v))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: _kiesWater, icon: const Icon(Icons.water, size: 18),
            label: Text(_water?['name'] ?? ft(context, 'water'), overflow: TextOverflow.ellipsis))),
        ]),
        const SizedBox(height: 12),
        if (_voortgang != null) Row(children: [
          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 10),
          Expanded(child: Text(_voortgang!, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]) else Row(children: [
          Expanded(child: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
            onPressed: () => _upload(ImageSource.gallery), icon: const Icon(Icons.add_photo_alternate_outlined, size: 18), label: Text(ft(context, 'app_pick_gallery')))),
          const SizedBox(width: 8),
          OutlinedButton.icon(onPressed: () => _upload(ImageSource.camera), icon: const Icon(Icons.photo_camera_outlined, size: 18), label: Text(ft(context, 'app_take_photo'))),
        ]),
      ]))),
      const SizedBox(height: 10),
      if (_albums.isNotEmpty) SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
        Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(label: Text(ft(context, 'all_photos')), selected: _albumFilter == null,
          onSelected: (_) { setState(() => _albumFilter = null); _load(); })),
        for (final a in _albums) Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(label: Text('${a['title']}'), selected: _albumFilter == a['id'],
          onSelected: (_) { setState(() => _albumFilter = a['id'] as int); _load(); })),
      ])),
      const SizedBox(height: 8),
      if (_fotos.isEmpty)
        Padding(padding: const EdgeInsets.symmetric(vertical: 30), child: Text(ft(context, 'no_photos'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.black45)))
      else GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _fotos.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 6, crossAxisSpacing: 6),
        itemBuilder: (_, i) {
          final f = _fotos[i] as Map;
          return GestureDetector(
            onTap: () async { final w = await bewerkFoto(context, widget.partnerId, f, _albums); if (w == true) _load(); },
            child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Stack(fit: StackFit.expand, children: [
              CachedNetworkImage(imageUrl: '${f['thumb'] ?? f['url']}', fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: Colors.black12)),
              Positioned(left: 4, top: 4, child: Row(children: [
                if (f['is_featured'] == true) const _Bolletje(Icons.star, Color(0xFFF59E0B)),
                if (f['is_public'] == false) const _Bolletje(Icons.visibility_off, Colors.black54),
                if (f['has_original'] == true) const _Bolletje(Icons.high_quality, AppColors.teal),
              ])),
            ])),
          );
        },
      ),
    ]));
  }
}

class _Bolletje extends StatelessWidget {
  final IconData ic;
  final Color kleur;
  const _Bolletje(this.ic, this.kleur);
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(right: 3), padding: const EdgeInsets.all(3),
    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(ic, size: 12, color: kleur));
}

/// Water zoeken (zelfde zoekroute als bij een vangst). Lege map = water weghalen, null = annuleren.
Future<Map?> kiesWater(BuildContext context, {bool huidig = false}) async {
  final zoek = TextEditingController();
  List res = [];
  bool bezig = false;
  return showDialog<Map?>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
    Future<void> doe() async {
      final q = zoek.text.trim();
      if (q.length < 2) return;
      setS(() => bezig = true);
      try {
        final r = await Api.get('/waters?q=${Uri.encodeComponent(q)}');
        res = r is List ? r : ((r as Map)['data'] ?? []);
      } catch (_) {}
      setS(() => bezig = false);
    }
    return AlertDialog(
      scrollable: true,
      title: Text(ft(context, 'water')),
      content: SizedBox(width: double.maxFinite, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: zoek, autofocus: true, onSubmitted: (_) => doe(),
          decoration: InputDecoration(hintText: ft(context, 'water_search_ph'), suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: doe))),
        if (bezig) const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()),
        for (final w in res.take(25)) ListTile(dense: true, title: Text('${w['name'] ?? ''}'),
          subtitle: (w['city'] ?? w['region'] ?? w['country']) != null ? Text('${w['city'] ?? w['region'] ?? w['country']}') : null,
          onTap: () => Navigator.pop(ctx, {'id': w['id'], 'name': w['name']})),
      ])),
      actions: [
        if (huidig) TextButton(onPressed: () => Navigator.pop(ctx, <String, dynamic>{}), child: Text(ft(context, 'water_none'))),
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ft(context, 'cancel'))),
      ],
    );
  }));
}

/// Foto bewerken: titel, beschrijving, album, water, uitgelicht/openbaar, verwijderen. true = gewijzigd.
Future<bool?> bewerkFoto(BuildContext context, int partnerId, Map f, List albums) {
  final titel = TextEditingController(text: f['title'] ?? ''), tekst = TextEditingController(text: f['caption'] ?? '');
  final labels = TextEditingController(text: ((f['tags'] as List?) ?? []).join(', '));
  int? album = f['album_id'] as int?;
  Map? water = f['water'] is Map ? Map.from(f['water']) : null;
  bool uitgelicht = f['is_featured'] == true, openbaar = f['is_public'] != false, bezig = false;
  final basis = '/partner/$partnerId/photos/${f['id']}';
  return showModalBottomSheet<bool>(context: context, isScrollControlled: true, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
    Future<void> opslaan() async {
      setS(() => bezig = true);
      try {
        await Api.put(basis, {
          'title': titel.text.trim().isEmpty ? null : titel.text.trim(),
          'caption': tekst.text.trim().isEmpty ? null : tekst.text.trim(),
          'tags': labels.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).take(10).toList(),
          'album_id': album, 'water_id': water?['id'], 'is_featured': uitgelicht, 'is_public': openbaar,
        });
        if (ctx.mounted) Navigator.pop(ctx, true);
        if (context.mounted) _melding(context, ft(context, 'saved'));
      } catch (e) { setS(() => bezig = false); if (context.mounted) _melding(context, _fout(context, e)); }
    }
    Future<void> weg() async {
      final ok = await showDialog<bool>(context: ctx, builder: (d) => AlertDialog(scrollable: true, content: Text(ft(context, 'delete_photo_confirm')), actions: [
        TextButton(onPressed: () => Navigator.pop(d, false), child: Text(ft(context, 'cancel'))),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(d, true), child: Text(ft(context, 'delete'))),
      ]));
      if (ok != true) return;
      try { await Api.delete(basis); if (ctx.mounted) Navigator.pop(ctx, true); } catch (e) { if (context.mounted) _melding(context, _fout(context, e)); }
    }
    InputDecoration dec(String l) => InputDecoration(labelText: l, border: const OutlineInputBorder(), isDense: true);
    return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom), child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(ctx).padding.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        GestureDetector(onTap: () => PhotoViewer.open(context, ['${f['url']}']),
          child: ClipRRect(borderRadius: BorderRadius.circular(10), child: AspectRatio(aspectRatio: 16 / 10, child: CachedNetworkImage(imageUrl: '${f['url']}', fit: BoxFit.cover)))),
        const SizedBox(height: 6),
        Text([ft(context, f['has_original'] == true ? 'with_original' : 'web_only'), if ((f['downloads'] ?? 0) > 0) ft(context, 'downloads', {'n': f['downloads']})].join(' · '),
          style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 12),
        TextField(controller: titel, decoration: dec(ft(context, 'title'))),
        const SizedBox(height: 10),
        TextField(controller: tekst, decoration: dec(ft(context, 'caption')), minLines: 2, maxLines: 5),
        const SizedBox(height: 10),
        TextField(controller: labels, decoration: dec(ft(context, 'tags'))),
        const SizedBox(height: 10),
        DropdownButtonFormField<int?>(initialValue: album, isExpanded: true, decoration: dec(ft(context, 'album')),
          items: [DropdownMenuItem(value: null, child: Text(ft(context, 'no_album'))),
            for (final a in albums) DropdownMenuItem(value: a['id'] as int, child: Text('${a['title']}', overflow: TextOverflow.ellipsis))],
          onChanged: (v) => setS(() => album = v)),
        const SizedBox(height: 10),
        OutlinedButton.icon(style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          onPressed: () async { final w = await kiesWater(ctx, huidig: water != null); if (w != null) setS(() => water = w.isEmpty ? null : w); },
          icon: const Icon(Icons.water, size: 18), label: Text(water?['name'] ?? '${ft(context, 'water')}: ${ft(context, 'water_none')}')),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(ft(context, 'featured')), value: uitgelicht, onChanged: (v) => setS(() => uitgelicht = v)),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(ft(context, openbaar ? 'public' : 'hidden')), value: openbaar, onChanged: (v) => setS(() => openbaar = v)),
        const SizedBox(height: 6),
        Row(children: [
          TextButton.icon(onPressed: weg, icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            label: Text(ft(context, 'delete'), style: const TextStyle(color: AppColors.danger))),
          const Spacer(),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.teal), onPressed: bezig ? null : opslaan, child: Text(ft(context, 'save'))),
        ]),
      ]),
    ));
  }));
}

// ─────────────────────────────── Albums ───────────────────────────────

class _AlbumsTab extends StatefulWidget {
  final int partnerId;
  const _AlbumsTab({required this.partnerId});
  @override
  State<_AlbumsTab> createState() => _AlbumsTabState();
}

class _AlbumsTabState extends State<_AlbumsTab> with AutomaticKeepAliveClientMixin {
  List _albums = [];
  bool _laden = true;
  @override
  bool get wantKeepAlive => true;
  String get _basis => '/partner/${widget.partnerId}/albums';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { final r = await Api.get(_basis); _albums = (r['data'] as List?) ?? []; } catch (_) {}
    if (mounted) setState(() => _laden = false);
  }

  Future<void> _bewerk([Map? a]) async {
    final titel = TextEditingController(text: a?['title'] ?? ''), oms = TextEditingController(text: a?['description'] ?? '');
    bool openbaar = a?['is_public'] != false;
    int? omslag = a?['cover_photo_id'] as int?;
    List fotos = [];
    if (a != null) {
      try { final r = await Api.get('/partner/${widget.partnerId}/photos?album_id=${a['id']}'); fotos = (r['data'] as List?) ?? []; } catch (_) {}
    }
    if (!mounted) return;
    final klaar = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
      Future<void> opslaan() async {
        if (titel.text.trim().isEmpty) return;
        try {
          final body = {'title': titel.text.trim(), 'description': oms.text.trim().isEmpty ? null : oms.text.trim(), 'is_public': openbaar,
            if (a != null) 'cover_photo_id': omslag};
          a == null ? await Api.post(_basis, body) : await Api.put('$_basis/${a['id']}', body);
          if (ctx.mounted) Navigator.pop(ctx, true);
        } catch (e) { if (mounted) _melding(context, _fout(context, e)); }
      }
      Future<void> weg() async {
        final ok = await showDialog<bool>(context: ctx, builder: (d) => AlertDialog(scrollable: true, content: Text(ft(context, 'delete_album_confirm')), actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(ft(context, 'cancel'))),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(d, true), child: Text(ft(context, 'delete'))),
        ]));
        if (ok != true) return;
        try { await Api.delete('$_basis/${a!['id']}'); if (ctx.mounted) Navigator.pop(ctx, true); } catch (e) { if (mounted) _melding(context, _fout(context, e)); }
      }
      return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom), child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(ctx).padding.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(a == null ? ft(context, 'new_album') : ft(context, 'edit'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 12),
          TextField(controller: titel, autofocus: a == null, decoration: InputDecoration(labelText: ft(context, 'album_title'), border: const OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 10),
          TextField(controller: oms, minLines: 2, maxLines: 5, decoration: InputDecoration(labelText: ft(context, 'album_desc'), border: const OutlineInputBorder(), isDense: true)),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(ft(context, 'album_public')), value: openbaar, onChanged: (v) => setS(() => openbaar = v)),
          if (fotos.isNotEmpty) ...[
            Text(ft(context, 'album_cover'), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            SizedBox(height: 74, child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final f in fotos) GestureDetector(onTap: () => setS(() => omslag = f['id'] as int), child: Container(
                margin: const EdgeInsets.only(right: 6), width: 74,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: omslag == f['id'] ? AppColors.teal : Colors.transparent, width: 3)),
                child: ClipRRect(borderRadius: BorderRadius.circular(5), child: CachedNetworkImage(imageUrl: '${f['thumb'] ?? f['url']}', fit: BoxFit.cover)))),
            ])),
          ],
          const SizedBox(height: 12),
          Row(children: [
            if (a != null) TextButton.icon(onPressed: weg, icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              label: Text(ft(context, 'delete'), style: const TextStyle(color: AppColors.danger))),
            const Spacer(),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.teal), onPressed: opslaan, child: Text(ft(context, 'save'))),
          ]),
        ]),
      ));
    }));
    if (klaar == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_laden) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(onRefresh: _load, child: ListView(padding: EdgeInsets.fromLTRB(14, 14, 14, 24 + MediaQuery.of(context).padding.bottom), children: [
      FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: AppColors.teal), onPressed: () => _bewerk(),
        icon: const Icon(Icons.add, size: 18), label: Text(ft(context, 'new_album'))),
      const SizedBox(height: 12),
      if (_albums.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Text(ft(context, 'albums_empty'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.black45))),
      for (final a in _albums) Card(margin: const EdgeInsets.only(bottom: 8), clipBehavior: Clip.antiAlias, child: ListTile(
        contentPadding: const EdgeInsets.only(right: 8),
        leading: SizedBox(width: 72, height: 72, child: a['cover'] != null ? CachedNetworkImage(imageUrl: '${a['cover']}', fit: BoxFit.cover) : Container(color: AppColors.bg, child: const Icon(Icons.photo_library_outlined, color: AppColors.teal))),
        title: Text('${a['title']}', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${ft(context, 'photos_count', {'n': a['photos_count'] ?? 0})} · ${ft(context, a['is_public'] == false ? 'hidden' : 'public')}'),
        trailing: const Icon(Icons.edit_outlined, size: 20),
        onTap: () => _bewerk(Map.from(a)),
      )),
    ]));
  }
}

// ─────────────────────────────── Feedbericht ───────────────────────────────

class _FeedTab extends StatefulWidget {
  final int partnerId;
  const _FeedTab({required this.partnerId});
  @override
  State<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<_FeedTab> with AutomaticKeepAliveClientMixin {
  List _posts = [], _fotos = [];
  Map? _quota;
  int? _kies;
  final _tekst = TextEditingController();
  bool _laden = true, _bezig = false;
  @override
  bool get wantKeepAlive => true;
  String get _basis => '/partner/${widget.partnerId}';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await Api.get('$_basis/posts');
      _posts = (r['data'] as List?) ?? [];
      _quota = r['quota'] is Map ? Map.from(r['quota']) : null;
      final f = await Api.get('$_basis/photos');
      _fotos = ((f['data'] as List?) ?? []).where((x) => x['is_public'] != false).toList();
    } catch (_) {}
    if (mounted) setState(() => _laden = false);
  }

  Future<void> _plaats() async {
    if (_kies == null) { _melding(context, ft(context, 'app_choose_photo_first')); return; }
    if (_tekst.text.trim().isEmpty) return;
    setState(() => _bezig = true);
    try {
      await Api.post('$_basis/posts', {'kind': 'photo', 'photo_id': _kies, 'content': _tekst.text.trim()});
      _tekst.clear(); _kies = null;
      if (mounted) _melding(context, ft(context, 'feed_posted'));
      await _load();
    } catch (e) {
      if (mounted) _melding(context, e is ApiException && e.status == 429 ? ft(context, 'feed_limit_reached', {'n': _quota?['limit'] ?? 3}) : _fout(context, e));
    }
    if (mounted) setState(() => _bezig = false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_laden) return const Center(child: CircularProgressIndicator());
    final vol = _quota != null && (_quota!['used'] ?? 0) >= (_quota!['limit'] ?? 3);
    return RefreshIndicator(onRefresh: _load, child: ListView(padding: EdgeInsets.fromLTRB(14, 14, 14, 24 + MediaQuery.of(context).padding.bottom), children: [
      Text(ft(context, 'feed_title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
      const SizedBox(height: 4),
      Text(ft(context, 'feed_intro'), style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
      if (_quota != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(ft(context, 'feed_quota', {'used': _quota!['used'] ?? 0, 'limit': _quota!['limit'] ?? 3}),
        style: TextStyle(fontWeight: FontWeight.w700, color: vol ? AppColors.danger : AppColors.teal))),
      const SizedBox(height: 12),
      if (vol) Text(ft(context, 'feed_limit_reached', {'n': _quota!['limit'] ?? 3}), style: const TextStyle(color: Colors.black54))
      else ...[
        Text(ft(context, 'feed_choose_photo'), style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        if (_fotos.isEmpty) Text(ft(context, 'no_photos'), style: const TextStyle(color: Colors.black45))
        else SizedBox(height: 92, child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final f in _fotos) GestureDetector(onTap: () => setState(() => _kies = f['id'] as int), child: Container(
            margin: const EdgeInsets.only(right: 6), width: 92,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: _kies == f['id'] ? AppColors.teal : Colors.transparent, width: 3)),
            child: ClipRRect(borderRadius: BorderRadius.circular(7), child: CachedNetworkImage(imageUrl: '${f['thumb'] ?? f['url']}', fit: BoxFit.cover)))),
        ])),
        const SizedBox(height: 10),
        TextField(controller: _tekst, minLines: 3, maxLines: 8, maxLength: 3000,
          decoration: InputDecoration(hintText: ft(context, 'feed_text_ph'), border: const OutlineInputBorder())),
        FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(vertical: 14)),
          onPressed: _bezig ? null : _plaats, icon: const Icon(Icons.send, size: 18), label: Text(ft(context, 'feed_post_btn'))),
      ],
      if (_posts.isNotEmpty) ...[
        const SizedBox(height: 22),
        Text(ft(context, 'feed_previous'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
        const SizedBox(height: 8),
        for (final p in _posts) Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
          leading: p['image_path'] != null ? ClipRRect(borderRadius: BorderRadius.circular(6), child: SizedBox(width: 52, height: 52, child: CachedNetworkImage(imageUrl: '${p['image_path']}', fit: BoxFit.cover))) : null,
          title: Text('${p['content'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text('${p['created_at'] ?? ''}'.split('T').first),
        )),
      ],
    ]));
  }
}

// ─────────────────────────────── Instellingen ───────────────────────────────

class _InstellingenTab extends StatefulWidget {
  final int partnerId;
  final String naam;
  const _InstellingenTab({required this.partnerId, required this.naam});
  @override
  State<_InstellingenTab> createState() => _InstellingenTabState();
}

class _InstellingenTabState extends State<_InstellingenTab> with AutomaticKeepAliveClientMixin {
  Map? _s;
  final _wm = TextEditingController();
  bool _bezig = false;
  @override
  bool get wantKeepAlive => true;
  String get _pad => '/partner/${widget.partnerId}/photo-settings';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { final r = await Api.get(_pad); _s = Map.from(r['data']); _wm.text = '${_s!['watermark_text'] ?? ''}'; } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _opslaan() async {
    setState(() => _bezig = true);
    try {
      final r = await Api.put(_pad, {
        'credit': _s!['credit'] == true, 'watermark': _s!['watermark'] == true, 'download': _s!['download'] == true,
        'booking': _s!['booking'] == true, 'watermark_text': _wm.text.trim().isEmpty ? null : _wm.text.trim(),
        'specialties': List<String>.from((_s!['specialties'] as List?) ?? []),
      });
      final n = (r['rewatermarked'] ?? 0) as int;
      if (mounted) _melding(context, n > 0 ? '${ft(context, 'settings_saved')} · ${ft(context, 'wm_redone', {'n': n})}' : ft(context, 'settings_saved'));
      await _load();
    } catch (e) { if (mounted) _melding(context, _fout(context, e)); }
    if (mounted) setState(() => _bezig = false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = _s;
    if (s == null) return const Center(child: CircularProgressIndicator());
    final opties = List<String>.from((s['specialty_options'] as List?) ?? []);
    final gekozen = List<String>.from((s['specialties'] as List?) ?? []);
    final opslag = (s['storage'] as Map?) ?? {};
    Widget schakel(String k, String titel, String uitleg) => SwitchListTile(contentPadding: EdgeInsets.zero,
      title: Text(titel, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(uitleg, style: const TextStyle(fontSize: 12.5)),
      value: s[k] == true, onChanged: (v) => setState(() => s[k] = v));
    return ListView(padding: EdgeInsets.fromLTRB(14, 14, 14, 24 + MediaQuery.of(context).padding.bottom), children: [
      Text(ft(context, 'settings_title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
      schakel('credit', ft(context, 'set_credit'), ft(context, 'set_credit_hint', {'name': widget.naam})),
      schakel('watermark', ft(context, 'set_watermark'), ft(context, 'set_watermark_hint')),
      if (s['watermark'] == true) Padding(padding: const EdgeInsets.only(bottom: 8), child: TextField(controller: _wm, maxLength: 60,
        decoration: InputDecoration(labelText: ft(context, 'set_wm_text'), border: const OutlineInputBorder(), isDense: true))),
      schakel('download', ft(context, 'set_download'), ft(context, 'set_download_hint')),
      schakel('booking', ft(context, 'set_booking'), ft(context, 'set_booking_hint')),
      const SizedBox(height: 10),
      Text(ft(context, 'specialties'), style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final o in opties) FilterChip(label: Text(ft(context, 'spec_$o')), selected: gekozen.contains(o),
          onSelected: (v) => setState(() { v ? gekozen.add(o) : gekozen.remove(o); s['specialties'] = gekozen; })),
      ]),
      const SizedBox(height: 14),
      Text(ft(context, 'storage', {'photos': opslag['photos'] ?? 0, 'originals': opslag['originals'] ?? 0,
        'mb': ((opslag['original_bytes'] ?? 0) / 1048576).toStringAsFixed(1)}), style: const TextStyle(fontSize: 12, color: Colors.black45)),
      const SizedBox(height: 14),
      FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(vertical: 14)),
        onPressed: _bezig ? null : _opslaan, child: Text(ft(context, 'save'))),
      const Divider(height: 36),
      _NaamEditor(partnerId: widget.partnerId),
      const Divider(height: 36),
      _LinksEditor(partnerId: widget.partnerId),
      const SizedBox(height: 10),
      OutlinedButton.icon(onPressed: () => openWebPagina('/partner'), icon: const Icon(Icons.open_in_new, size: 18), label: Text(ft(context, 'app_profile_web'))),
    ]);
  }
}

// ─────────────────────────────── Aanvragen ───────────────────────────────

class _AanvragenTab extends StatefulWidget {
  final int partnerId;
  const _AanvragenTab({required this.partnerId});
  @override
  State<_AanvragenTab> createState() => _AanvragenTabState();
}

class _AanvragenTabState extends State<_AanvragenTab> with AutomaticKeepAliveClientMixin {
  List _items = [];
  bool _laden = true;
  @override
  bool get wantKeepAlive => true;
  String get _basis => '/partner/${widget.partnerId}/inquiries';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { final r = await Api.get(_basis); _items = (r['data'] as List?) ?? []; } catch (_) {}
    if (mounted) setState(() => _laden = false);
  }

  Future<void> _status(Map i, String st) async {
    try { await Api.put('$_basis/${i['id']}', {'status': st}); _load(); } catch (e) { if (mounted) _melding(context, _fout(context, e)); }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_laden) return const Center(child: CircularProgressIndicator());
    const kleur = {'new': Color(0xFF1F8A70), 'read': Color(0xFF0E5A87), 'answered': Color(0xFF64748B), 'archived': Color(0xFF94A3B8)};
    return RefreshIndicator(onRefresh: _load, child: ListView(padding: EdgeInsets.fromLTRB(14, 14, 14, 24 + MediaQuery.of(context).padding.bottom), children: [
      Text(ft(context, 'inq_title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
      const SizedBox(height: 10),
      if (_items.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Text(ft(context, 'inq_empty'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.black45))),
      for (final i in _items) Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('${i['name']}${(i['subject'] ?? '').toString().isNotEmpty ? ' · ${i['subject']}' : ''}', style: const TextStyle(fontWeight: FontWeight.bold))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: (kleur[i['status']] ?? Colors.grey).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
            child: Text(ft(context, 'inq_${i['status']}'), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: kleur[i['status']] ?? Colors.grey))),
        ]),
        const SizedBox(height: 2),
        Text('${i['created_at'] ?? ''}'.split('T').first, style: const TextStyle(fontSize: 11.5, color: Colors.black45)),
        const SizedBox(height: 8),
        Text('${i['message'] ?? ''}', style: const TextStyle(height: 1.35)),
        if (i['wish_date'] != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(ft(context, 'inq_wish_date', {'d': i['wish_date']}), style: const TextStyle(fontSize: 12.5, color: Colors.black54))),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
          FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: AppColors.teal, visualDensity: VisualDensity.compact),
            onPressed: () { launchUrl(Uri(scheme: 'mailto', path: '${i['email']}', queryParameters: {'subject': 'Re: ${i['subject'] ?? 'YessFish'}'})); if (i['status'] == 'new') _status(i, 'read'); },
            icon: const Icon(Icons.reply, size: 16), label: Text(ft(context, 'inq_reply_mail'))),
          if ((i['phone'] ?? '').toString().isNotEmpty) OutlinedButton.icon(style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
            onPressed: () => launchUrl(Uri(scheme: 'tel', path: '${i['phone']}')), icon: const Icon(Icons.phone, size: 16), label: Text('${i['phone']}')),
          PopupMenuButton<String>(
            tooltip: ft(context, 'inq_mark'),
            onSelected: (v) => _status(i, v),
            itemBuilder: (_) => [for (final st in ['new', 'read', 'answered', 'archived']) if (st != i['status']) PopupMenuItem(value: st, child: Text(ft(context, 'inq_$st')))],
            child: Padding(padding: const EdgeInsets.all(6), child: Text('${ft(context, 'inq_mark')} …', style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600))),
          ),
        ]),
        Text('${i['email']}', style: const TextStyle(fontSize: 12, color: Colors.black45)),
      ]))),
    ]));
  }
}

// ─────────────────────────────── Social media en links (07-10-2026) ───────────────────────────────

const kLinkSoortenFoto = ['instagram', 'facebook', 'tiktok', 'youtube', 'flickr', '500px', 'website', 'other'];

/// Icoon per linksoort (Material heeft geen Instagram/YouTube-merkicoon; dit is het dichtstbij).
IconData socialIcoon(String? soort) => switch (soort) {
  'facebook' => Icons.facebook,
  'tiktok' => Icons.tiktok,
  'instagram' => Icons.camera_alt_outlined,
  'youtube' => Icons.smart_display_outlined,
  'flickr' || '500px' => Icons.photo_library_outlined,
  'website' => Icons.language,
  _ => Icons.link,
};

/// Zelfde lijst als het blok "Social media en links" in het profiel op de website: PUT /partner/{id} met links.
class _LinksEditor extends StatefulWidget {
  final int partnerId;
  const _LinksEditor({required this.partnerId});
  @override
  State<_LinksEditor> createState() => _LinksEditorState();
}

class _LinksEditorState extends State<_LinksEditor> {
  List<Map<String, dynamic>>? _links;
  final List<TextEditingController> _urls = [];
  bool _bezig = false;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { for (final c in _urls) { c.dispose(); } super.dispose(); }

  Future<void> _load() async {
    try {
      final r = await Api.get('/partner/mine');
      final p = ((r['data'] as List?) ?? []).firstWhere((x) => x['id'] == widget.partnerId, orElse: () => null);
      _links = [for (final l in ((p?['links'] as List?) ?? [])) Map<String, dynamic>.from(l)];
    } catch (_) { _links = []; }
    for (final c in _urls) { c.dispose(); }
    _urls..clear()..addAll(_links!.map((l) => TextEditingController(text: '${l['url'] ?? ''}')));
    if (mounted) setState(() {});
  }

  Future<void> _opslaan() async {
    setState(() => _bezig = true);
    try {
      final lijst = <Map<String, dynamic>>[];
      for (var i = 0; i < _links!.length; i++) {
        final url = _urls[i].text.trim();
        if (url.isEmpty) continue;
        final soort = '${_links![i]['kind'] ?? 'other'}';
        final oud = '${_links![i]['label'] ?? ''}'.trim();
        // Eigen naam bewaren; anders de naam van het kanaal (zoals op de site).
        final standaard = kLinkSoortenFoto.any((k) => ft(context, 'lk_$k') == oud);
        lijst.add({'kind': soort, 'label': oud.isEmpty || standaard ? ft(context, 'lk_$soort') : oud, 'url': url});
      }
      await Api.put('/partner/${widget.partnerId}', {'links': lijst});
      if (mounted) _melding(context, ft(context, 'saved'));
      await _load();
    } catch (e) { if (mounted) _melding(context, _fout(context, e)); }
    if (mounted) setState(() => _bezig = false);
  }

  @override
  Widget build(BuildContext context) {
    final links = _links;
    if (links == null) return const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(ft(context, 'links_title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
      const SizedBox(height: 4),
      Text(ft(context, 'links_hint'), style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
      const SizedBox(height: 10),
      for (var i = 0; i < links.length; i++) Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
        SizedBox(width: 128, child: DropdownButtonFormField<String>(
          initialValue: kLinkSoortenFoto.contains(links[i]['kind']) ? links[i]['kind'] as String : 'other', isExpanded: true,
          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12)),
          items: [for (final k in kLinkSoortenFoto) DropdownMenuItem(value: k, child: Row(children: [
            Icon(socialIcoon(k), size: 16, color: AppColors.teal), const SizedBox(width: 6),
            Flexible(child: Text(ft(context, 'lk_$k'), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)))]))],
          onChanged: (v) => setState(() => links[i]['kind'] = v))),
        const SizedBox(width: 6),
        Expanded(child: TextField(controller: _urls[i], keyboardType: TextInputType.url,
          decoration: InputDecoration(isDense: true, hintText: ft(context, 'link_url'), border: const OutlineInputBorder()))),
        IconButton(tooltip: ft(context, 'link_remove'), icon: const Icon(Icons.close, size: 20, color: Colors.black45),
          onPressed: () => setState(() { links.removeAt(i); _urls.removeAt(i).dispose(); })),
      ])),
      if (links.length < 12) Align(alignment: Alignment.centerLeft, child: TextButton(
        onPressed: () => setState(() { links.add({'kind': 'instagram', 'label': '', 'url': ''}); _urls.add(TextEditingController()); }),
        child: Text(ft(context, 'add_link')))),
      const SizedBox(height: 6),
      FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(vertical: 14)),
        onPressed: _bezig ? null : _opslaan, child: Text(ft(context, 'save'))),
    ]);
  }
}

// ─────────────────────────────── Naam van je pagina (07-10-2026) ───────────────────────────────
/// Richard: de fotograaf moet zelf de naam van zijn pagina kunnen wijzigen. Het webadres gaat mee (API), oude links
/// sturen door. Zelfde als het naamveld onder Profiel op de website: PUT /partner/{id} met name.
class _NaamEditor extends StatefulWidget {
  final int partnerId;
  const _NaamEditor({required this.partnerId});
  @override
  State<_NaamEditor> createState() => _NaamEditorState();
}

class _NaamEditorState extends State<_NaamEditor> {
  final _naam = TextEditingController();
  String? _slug, _origineel;
  bool _bezig = false;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _naam.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final r = await Api.get('/partner/mine');
      final p = ((r['data'] as List?) ?? []).firstWhere((x) => x['id'] == widget.partnerId, orElse: () => null);
      if (p != null) { _origineel = '${p['name'] ?? ''}'; _naam.text = _origineel!; _slug = '${p['slug'] ?? ''}'; }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _opslaan() async {
    final n = _naam.text.trim();
    if (n.length < 2) { _melding(context, ft(context, 'app_page_name_short')); return; }
    setState(() => _bezig = true);
    try {
      final r = await Api.put('/partner/${widget.partnerId}', {'name': n});
      final d = (r is Map && r['data'] is Map) ? r['data'] : null;
      if (d != null) { _origineel = '${d['name']}'; _slug = '${d['slug']}'; }
      if (mounted) _melding(context, ft(context, 'saved'));
    } catch (e) { if (mounted) _melding(context, _fout(context, e)); }
    if (mounted) setState(() => _bezig = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_origineel == null) return const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(ft(context, 'app_page_name'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
      const SizedBox(height: 8),
      TextField(key: const Key('portaal-naam'), controller: _naam, maxLength: 120, textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, counterText: '')),
      if ((_slug ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6),
        child: Text(ft(context, 'name_url_hint', {'url': 'yessfish.com/fotograaf/$_slug'}), style: const TextStyle(fontSize: 12, color: Colors.black54))),
      const SizedBox(height: 10),
      FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
        onPressed: _bezig ? null : _opslaan, child: Text(ft(context, 'save'))),
    ]);
  }
}
