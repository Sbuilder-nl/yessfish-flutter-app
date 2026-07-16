import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/api.dart';
import '../core/config.dart';

class AlbumDetailScreen extends StatefulWidget {
  final int albumId;
  final String? title;
  const AlbumDetailScreen({super.key, required this.albumId, this.title});
  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  Map? _album;
  List _photos = [];
  bool _loading = true, _adding = false;

  String get _lang => Localizations.localeOf(context).languageCode;
  String _t(Map<String, String> m) => m[_lang] ?? m['en'] ?? m['nl'] ?? '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await Api.get('/albums/${widget.albumId}');
      setState(() {
        _album = r is Map ? r : null;
        _photos = (_album?['photos'] ?? []) as List;
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  String _photoUrl(Map p) {
    final path = '${p['path'] ?? ''}';
    if (path.startsWith('http')) return path;
    return '${Config.origin}/uploads/$path';
  }

  Future<void> _addPhoto(ImageSource src) async {
    // Galerij: meerdere foto's tegelijk selecteren; camera blijft één foto.
    List<XFile> xs = [];
    try {
      if (src == ImageSource.gallery) {
        xs = await ImagePicker().pickMultiImage(maxWidth: 1600, imageQuality: 85);
      } else {
        final x = await ImagePicker().pickImage(source: src, maxWidth: 1600, imageQuality: 85);
        if (x != null) xs = [x];
      }
    }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); return; }
    if (xs.isEmpty) return;
    setState(() => _adding = true);
    final m = ScaffoldMessenger.of(context);
    try {
      for (final x in xs) {
        final up = await Api.uploadImage(x.path);
        await Api.post('/albums/${widget.albumId}/photos', {'path': up['path']});
      }
      await _load();
    } catch (e) {
      m.showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : '$e')));
    } finally { if (mounted) setState(() => _adding = false); }
  }

  // Telefoon: keuze camera of galerij.
  void _pickSource() {
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.camera_alt, color: AppColors.teal), title: Text(_t(_camL)), onTap: () { Navigator.pop(ctx); _addPhoto(ImageSource.camera); }),
      ListTile(leading: const Icon(Icons.photo_library, color: AppColors.teal), title: Text(_t(_galL)), onTap: () { Navigator.pop(ctx); _addPhoto(ImageSource.gallery); }),
    ])));
  }

  Future<void> _delPhoto(int id) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      content: Text(_t(_cDel)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_t(_cancel))),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: Text(_t(_del))),
      ],
    ));
    if (ok != true) return;
    try { await Api.delete('/albums/${widget.albumId}/photos/$id'); await _load(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
  }

  void _openViewer(int start, {bool play = false}) {
    if (_photos.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(fullscreenDialog: true, builder: (_) => _Slideshow(
      urls: _photos.map((p) => _photoUrl(p as Map)).toList(), start: start, autoplay: play, title: '${_album?['title'] ?? ''}',
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_album?['title'] ?? widget.title ?? _t(_titleL)),
        actions: [
          if (_photos.isNotEmpty) IconButton(tooltip: _t(_slideL), icon: const Icon(Icons.slideshow), onPressed: () => _openViewer(0, play: true)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.teal,
        onPressed: _adding ? null : _pickSource,
        icon: _adding ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.add_a_photo, color: Colors.white),
        label: Text(_t(_photoL), style: const TextStyle(color: Colors.white)),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : _photos.isEmpty
          ? Center(child: Text(_t(_emptyL), style: const TextStyle(color: Colors.black45)))
          : RefreshIndicator(onRefresh: _load, child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6),
              itemCount: _photos.length,
              itemBuilder: (_, i) {
                final p = _photos[i] as Map;
                return GestureDetector(
                  onTap: () => _openViewer(i),
                  child: Stack(children: [
                    Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(imageUrl: _photoUrl(p), fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.bg),
                        errorWidget: (_, __, ___) => Container(color: AppColors.bg, child: const Icon(Icons.broken_image, color: Colors.black26))))),
                    if (p['id'] != null) Positioned(right: 3, top: 3, child: GestureDetector(
                      onTap: () => _delPhoto(p['id'] as int),
                      child: Container(decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), padding: const EdgeInsets.all(3), child: const Icon(Icons.close, size: 15, color: Colors.white)))),
                  ]),
                );
              })),
    );
  }
}

// Fullscreen kijker + slideshow (auto-doorbladeren).
class _Slideshow extends StatefulWidget {
  final List urls; final int start; final bool autoplay; final String title;
  const _Slideshow({required this.urls, required this.start, required this.autoplay, required this.title});
  @override
  State<_Slideshow> createState() => _SlideshowState();
}
class _SlideshowState extends State<_Slideshow> {
  late PageController _pc;
  late int _i;
  bool _playing = false;
  @override
  void initState() { super.initState(); _i = widget.start; _pc = PageController(initialPage: _i); _playing = widget.autoplay; if (_playing) _tick(); }
  void _tick() async {
    while (mounted && _playing) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted || !_playing) break;
      final next = (_i + 1) % widget.urls.length;
      _pc.animateToPage(next, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }
  @override
  void dispose() { _pc.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0,
        title: Text('${widget.title} · ${_i + 1}/${widget.urls.length}', style: const TextStyle(fontSize: 14)),
        actions: [
          IconButton(icon: Icon(_playing ? Icons.pause : Icons.play_arrow), onPressed: () { setState(() => _playing = !_playing); if (_playing) _tick(); }),
        ],
      ),
      body: PageView.builder(
        controller: _pc,
        itemCount: widget.urls.length,
        onPageChanged: (v) => setState(() => _i = v),
        itemBuilder: (_, i) => InteractiveViewer(child: Center(child: CachedNetworkImage(imageUrl: '${widget.urls[i]}', fit: BoxFit.contain))),
      ),
    );
  }
}

const _titleL = {'nl': 'Album', 'en': 'Album', 'de': 'Album', 'fr': 'Album', 'es': 'Álbum', 'pl': 'Album'};
const _photoL = {'nl': 'Foto', 'en': 'Photo', 'de': 'Foto', 'fr': 'Photo', 'es': 'Foto', 'pl': 'Zdjęcie'};
const _emptyL = {'nl': 'Nog geen foto\'s in dit album.', 'en': 'No photos in this album yet.', 'de': 'Noch keine Fotos.', 'fr': 'Aucune photo.', 'es': 'Aún no hay fotos.', 'pl': 'Brak zdjęć.'};
const _slideL = {'nl': 'Diavoorstelling', 'en': 'Slideshow', 'de': 'Diashow', 'fr': 'Diaporama', 'es': 'Presentación', 'pl': 'Pokaz slajdów'};
const _camL = {'nl': 'Camera', 'en': 'Camera', 'de': 'Kamera', 'fr': 'Caméra', 'es': 'Cámara', 'pl': 'Aparat'};
const _galL = {'nl': 'Galerij', 'en': 'Gallery', 'de': 'Galerie', 'fr': 'Galerie', 'es': 'Galería', 'pl': 'Galeria'};
const _cDel = {'nl': 'Deze foto verwijderen?', 'en': 'Delete this photo?', 'de': 'Dieses Foto löschen?', 'fr': 'Supprimer cette photo ?', 'es': '¿Eliminar esta foto?', 'pl': 'Usunąć to zdjęcie?'};
const _del = {'nl': 'Verwijderen', 'en': 'Delete', 'de': 'Löschen', 'fr': 'Supprimer', 'es': 'Eliminar', 'pl': 'Usuń'};
const _cancel = {'nl': 'Annuleren', 'en': 'Cancel', 'de': 'Abbrechen', 'fr': 'Annuler', 'es': 'Cancelar', 'pl': 'Anuluj'};
