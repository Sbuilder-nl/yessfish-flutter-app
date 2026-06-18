import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';

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

  Future<void> _addPhoto() async {
    XFile? x;
    try { x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.tr('albumdetail.gallery_failed')}: $e'))); return; }
    if (x == null) return;
    setState(() => _adding = true);
    final m = ScaffoldMessenger.of(context);
    try {
      final up = await Api.uploadImage(x.path);
      await Api.post('/albums/${widget.albumId}/photos', {'path': up['path']});
      await _load();
    } catch (e) {
      m.showSnackBar(SnackBar(content: Text(e is ApiException ? '${context.tr('albumdetail.failed')}: ${e.message}' : context.tr('albumdetail.add_failed'))));
    } finally { if (mounted) setState(() => _adding = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_album?['title'] ?? widget.title ?? context.tr('albumdetail.title'))),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.teal,
        onPressed: _adding ? null : _addPhoto,
        icon: _adding ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.add_a_photo, color: Colors.white),
        label: Text(context.tr('albumdetail.photo'), style: const TextStyle(color: Colors.white)),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : _photos.isEmpty
          ? Center(child: Text(context.tr('albumdetail.empty'), style: const TextStyle(color: Colors.black45)))
          : RefreshIndicator(onRefresh: _load, child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6),
              itemCount: _photos.length,
              itemBuilder: (_, i) {
                final p = _photos[i] as Map;
                return ClipRRect(borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(imageUrl: _photoUrl(p), fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.bg),
                    errorWidget: (_, __, ___) => Container(color: AppColors.bg, child: const Icon(Icons.broken_image, color: Colors.black26))));
              })),
    );
  }
}
