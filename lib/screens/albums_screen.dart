import 'package:flutter/material.dart';
import '../core/rondleiding.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import 'album_detail_screen.dart';
import '../widgets/rondleiding_overlay.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});
  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  List _items = [];
  bool _loading = true;
  // De handleiding vraagt om een album te openen (stap "Foto's bekijken"). Komt dat verzoek
  // voordat de lijst er is, dan wachten we tot hij geladen is.
  bool _openGevraagd = false;
  bool _detailOpen = false;

  @override
  void initState() {
    super.initState();
    Rondleiding.luister('albums', _rondleidingVraag);
    // Alleen zolang de rondleiding loopt: anders ging het eerste album ook open als een lid
    // na de rondleiding zelf naar Albums ging (laatsteVraag blijft staan).
    _openGevraagd = Rondleiding.loopt && Rondleiding.laatsteVraag == 'album-open';
    _load();
  }

  @override
  void dispose() {
    Rondleiding.stopLuisteren('albums', _rondleidingVraag);
    super.dispose();
  }

  void _rondleidingVraag(String vraag) {
    if (!mounted) return;
    if (vraag == 'album-open') { _openGevraagd = true; _eersteOpenen(); }
    if (vraag == 'sluit' && _detailOpen) { _detailOpen = false; Navigator.of(context).pop(); }
  }

  void _eersteOpenen() {
    if (!_openGevraagd || _loading || _items.isEmpty || _detailOpen) return;
    _openGevraagd = false;
    final a = _items.first as Map;
    _detailOpen = true;
    Navigator.push(context, MaterialPageRoute(builder: (_) => AlbumDetailScreen(albumId: a['id'], title: a['title'])))
        .then((_) { _detailOpen = false; });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { final r = await Api.get('/albums'); setState(() { _items = r is List ? r : (r['data'] ?? []); _loading = false; }); }
    catch (_) { setState(() => _loading = false); }
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _eersteOpenen(); });
  }

  Future<void> _create() async {
    final title = TextEditingController();
    String privacy = 'public';
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      scrollable: true,
      title: Text(context.tr('albums.create_title')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, decoration: InputDecoration(labelText: context.tr('albums.album_title'))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(initialValue: privacy, decoration: InputDecoration(labelText: context.tr('albums.visibility')),
          items: [
            DropdownMenuItem(value: 'public', child: Text(context.tr('albums.public'))),
            DropdownMenuItem(value: 'friends', child: Text(context.tr('albums.friends_only'))),
            DropdownMenuItem(value: 'private', child: Text(context.tr('albums.private'))),
          ],
          onChanged: (v) => setS(() => privacy = v!)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('albums.cancel'))), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('albums.create')))],
    )));
    if (ok != true || title.text.trim().isEmpty) return;
    final m = ScaffoldMessenger.of(context);
    try { await Api.post('/albums', {'title': title.text.trim(), 'privacy': privacy}); await _load(); }
    catch (e) { m.showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : context.tr('albums.create_failed')))); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(context.tr('albums.title'))),
      floatingActionButton: TourAnker(id: 'albums-maak', child: FloatingActionButton.extended(backgroundColor: AppColors.teal, onPressed: _create, icon: const Icon(Icons.add, color: Colors.white), label: Text(context.tr('albums.album'), style: const TextStyle(color: Colors.white)))),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _items.isEmpty ? Center(child: Text(context.tr('albums.empty'), style: const TextStyle(color: Colors.black45))) : RefreshIndicator(onRefresh: _load, child: TourAnker(id: 'albums-lijst', child: ListView.builder(
        padding: const EdgeInsets.all(12) + EdgeInsets.only(bottom: 16 + MediaQuery.of(context).padding.bottom), itemCount: _items.length,
        itemBuilder: (_, i) { final a = _items[i] as Map; return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: const Icon(Icons.photo_album, color: AppColors.teal), title: Text(a['title'] ?? ''), subtitle: Text('${a['photos_count'] ?? a['photos']?.length ?? 0} ${context.tr('albums.photos')}'), trailing: const Icon(Icons.chevron_right), onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => AlbumDetailScreen(albumId: a['id'], title: a['title']))); _load(); })); }))));
  }
}
