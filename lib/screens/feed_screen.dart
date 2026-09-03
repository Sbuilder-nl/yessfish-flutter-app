import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import '../widgets/dobber_loader.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/auth.dart';
import '../core/config.dart';
import '../core/realtime_service.dart';
import '../core/i18n.dart';
import '../widgets/avatar.dart';
import '../widgets/photo_viewer.dart';
import '../widgets/report.dart';
import '../widgets/feed_video.dart';
import '../widgets/media_carousel.dart';
import '../widgets/sponsored_feed_card.dart';
import 'user_profile_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List _posts = [];
  bool _loading = true;
  final _composer = TextEditingController();
  // Gekozen media voor het nieuwe bericht: foto's en video's gemengd, max 10.
  // Elk item: {type: image|video, path: server-pad, url: preview-URL (foto's)}.
  final List<Map> _media = [];
  String? _youtube;            // YouTube-link/ID (sluit media uit)
  bool _videoUploading = false;
  bool _posting = false;
  final Map<int, Map> _trans = {}; // post-id → {content, shown, busy}
  StreamSubscription? _liveSub;

  @override
  void initState() {
    super.initState();
    _load();
    _composer.addListener(_composerChanged);
    _liveSub = context.read<RealtimeService>().feedPosts.listen((post) {
      if (mounted && !_posts.any((p) => p['id'] == post['id'])) setState(() => _posts.insert(0, post));
    });
  }

  @override
  void dispose() { _liveSub?.cancel(); super.dispose(); }

  // Korte plaatsingsdatum bij elk bericht: vandaag = tijd, dit jaar = dag-maand, ouder = met jaar.
  static String _postDate(dynamic raw) {
    final dt = DateTime.tryParse('$raw')?.toLocal();
    if (dt == null) return '';
    final nu = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    if (dt.year == nu.year && dt.month == nu.month && dt.day == nu.day) return '${two(dt.hour)}:${two(dt.minute)}';
    if (dt.year == nu.year) return '${dt.day}-${dt.month} ${two(dt.hour)}:${two(dt.minute)}';
    return '${dt.day}-${dt.month}-${dt.year}';
  }

  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  Future<void> _load() async {
    try {
      final r = await Api.get('/feed');
      final meta = r is Map ? r['meta'] : null;
      setState(() {
        _posts = r['data'] ?? [];
        _loading = false;
        _page = 1;
        _hasMore = meta is Map ? ((meta['current_page'] ?? 1) as num) < ((meta['last_page'] ?? 1) as num) : false;
      });
    }
    catch (_) { setState(() { _loading = false; }); }
  }

  // Volgende pagina ophalen zodra je bijna onderaan bent (oneindig scrollen zoals de site).
  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    if (mounted) setState(() {});
    try {
      final r = await Api.get('/feed?page=${_page + 1}');
      final meta = r is Map ? r['meta'] : null;
      final nieuwe = (r['data'] ?? []) as List;
      if (mounted) setState(() {
        // dubbelen eruit (live-stream kan een post al toegevoegd hebben)
        _posts.addAll(nieuwe.where((n) => !_posts.any((p) => p['id'] == n['id'])));
        _page += 1;
        _hasMore = meta is Map ? ((meta['current_page'] ?? _page) as num) < ((meta['last_page'] ?? _page) as num) : false;
      });
    } catch (_) {}
    _loadingMore = false;
    if (mounted) setState(() {});
  }

  // Voegt een gekozen foto/video toe aan het bericht (max 10, YouTube vervalt dan).
  bool _voegMediaToe(Map m) {
    if (_media.length >= 10) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('feed.media_max'))));
      return false;
    }
    setState(() { _media.add(m); _youtube = null; });
    return true;
  }

  Future<void> _pickPhoto(ImageSource src) async {
    XFile? x;
    try { x = await ImagePicker().pickImage(source: src, maxWidth: 1600, imageQuality: 85); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${src == ImageSource.camera ? context.tr('feed.openCameraFail') : context.tr('feed.openGalleryFail')}: $e'))); return; }
    if (x == null) return;
    try { final r = await Api.uploadImage(x.path); _voegMediaToe({'type': 'image', 'path': r['path'], 'url': r['url']}); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? '${context.tr('feed.uploadFail')}: ${e.message}' : '${context.tr('feed.uploadFail')}: $e'))); }
  }

  // Video: bron = camera → filmen, gallery → bestaande video kiezen.
  Future<void> _pickVideo(ImageSource source) async {
    XFile? x;
    try { x = await ImagePicker().pickVideo(source: source, maxDuration: const Duration(seconds: 90)); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.tr('feed.uploadFail')}: $e'))); return; }
    if (x != null) await _uploadPickedVideo(x);
  }

  // Galerij: kies meerdere foto's en/of video's tegelijk (gemengd mag).
  Future<void> _pickMedia() async {
    List<XFile> xs = [];
    try { xs = await ImagePicker().pickMultipleMedia(imageQuality: 85, maxWidth: 1600); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.tr('feed.openGalleryFail')}: $e'))); return; }
    for (final x in xs) {
      if (_media.length >= 10) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('feed.media_max'))));
        break;
      }
      final p = x.path.toLowerCase();
      final isVideo = ['.mp4', '.mov', '.m4v', '.avi', '.webm', '.mkv', '.3gp'].any(p.endsWith);
      if (isVideo) { await _uploadPickedVideo(x); continue; }
      try { final r = await Api.uploadImage(x.path); _voegMediaToe({'type': 'image', 'path': r['path'], 'url': r['url']}); }
      catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? '${context.tr('feed.uploadFail')}: ${e.message}' : '${context.tr('feed.uploadFail')}: $e'))); }
    }
  }

  Future<void> _uploadPickedVideo(XFile x) async {
    setState(() => _videoUploading = true);
    final info = ValueNotifier<UploadState>(const UploadState('compress', 0));
    if (mounted) showDialog(context: context, barrierDismissible: false, builder: (_) => UploadOverlay(info));
    final sub = VideoCompress.compressProgress$.subscribe((p) => info.value = UploadState('compress', p / 100.0));
    try {
      final mi = await VideoCompress.compressVideo(x.path, quality: VideoQuality.MediumQuality, deleteOrigin: false, includeAudio: true);
      final path = mi?.path ?? x.path;
      info.value = const UploadState('upload', 0);
      final r = await Api.uploadVideo(path);
      _voegMediaToe({'type': 'video', 'path': r['path']});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : '${context.tr('feed.uploadFail')}: $e')));
    } finally {
      sub.unsubscribe();
      try { await VideoCompress.cancelCompression(); } catch (_) {}
      if (mounted) { Navigator.of(context, rootNavigator: true).pop(); setState(() => _videoUploading = false); }
    }
  }

  Future<void> _addYoutube() async {
    final c = TextEditingController(text: _youtube ?? '');
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      scrollable: true,
      title: Text(context.tr('feed.youtube')),
      content: TextField(controller: c, autofocus: true, decoration: InputDecoration(hintText: context.tr('feed.youtubeHint'))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('feed.cancel'))),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('feed.save'))),
      ],
    ));
    if (ok == true) setState(() { final v = c.text.trim(); _youtube = v.isEmpty ? null : v; if (v.isNotEmpty) _media.clear(); });
  }

  // @-taggen: vriendenlijst (lui geladen) + suggesties zodra je @+letters typt.
  List<Map> _vrienden = [];
  bool _vriendenGeladen = false;
  List<Map> _mentionSuggesties = [];

  Future<void> _laadVrienden() async {
    if (_vriendenGeladen) return;
    _vriendenGeladen = true;
    try {
      final r = await Api.get('/friends');
      final data = (r is Map ? r['data'] : r) as List? ?? [];
      _vrienden = data.map((f) {
        final u = (f is Map ? (f['user'] ?? f) : {}) as Map;
        return {'id': u['id'], 'username': u['username'], 'avatar_path': u['avatar_path']};
      }).where((u) => u['id'] != null && u['username'] != null).toList();
    } catch (_) {}
  }

  void _composerChanged() {
    final text = _composer.text;
    final sel = _composer.selection.baseOffset;
    final tot = sel >= 0 && sel <= text.length ? text.substring(0, sel) : text;
    final m = RegExp(r'@([\w.]{1,20})\$').firstMatch(tot);
    if (m == null) {
      if (_mentionSuggesties.isNotEmpty) setState(() => _mentionSuggesties = []);
      return;
    }
    _laadVrienden().then((_) {
      final q = m.group(1)!.toLowerCase();
      final sugg = _vrienden.where((f) => '${f['username']}'.toLowerCase().contains(q)).take(6).toList();
      if (mounted) setState(() => _mentionSuggesties = sugg);
    });
  }

  void _kiesMention(Map f) {
    final text = _composer.text;
    final sel = _composer.selection.baseOffset;
    final tot = sel >= 0 && sel <= text.length ? text.substring(0, sel) : text;
    final rest = sel >= 0 && sel <= text.length ? text.substring(sel) : '';
    final nieuw = tot.replaceFirst(RegExp(r'@[\w.]{1,20}\$'), '@${f['username']} ');
    _composer.text = nieuw + rest;
    _composer.selection = TextSelection.collapsed(offset: nieuw.length);
    setState(() => _mentionSuggesties = []);
  }

  Future<void> _post() async {
    if (_composer.text.trim().isEmpty && _media.isEmpty && (_youtube == null || _youtube!.isEmpty)) return;
    if (_videoUploading) return;
    setState(() => _posting = true);
    try {
      await Api.post('/posts', {
        'content': _composer.text.trim().isEmpty ? ' ' : _composer.text.trim(), 'visibility': 'public',
        if (_media.isNotEmpty) 'media': [for (final m in _media) {'type': m['type'], 'path': m['path']}],
        if (_youtube != null && _youtube!.isNotEmpty) 'youtube_id': _youtube,
        // vrienden wiens @naam in de tekst staat als tag meesturen (zoals de site)
        'tagged_ids': _vrienden.where((f) => RegExp('@' + RegExp.escape('${f['username']}') + r'(?![\w.])').hasMatch(_composer.text)).map((f) => f['id']).toList(),
      });
      _composer.clear();
      setState(() { _media.clear(); _youtube = null; });
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'Er ging iets mis')));
    } finally { setState(() => _posting = false); }
  }

  Future<void> _deletePost(Map p) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      scrollable: true,
      title: Text(context.tr('feed.deleteTitle')),
      content: Text(context.tr('feed.deleteBody')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('feed.no'))),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('feed.delete'))),
      ]));
    if (ok != true) return;
    try { await Api.delete('/posts/${p['id']}'); _load(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : context.tr('feed.deleteFail')))); }
  }

  Future<void> _toggleLike(Map p) async {
    final liked = p['liked_by_me'] == true;
    setState(() { p['liked_by_me'] = !liked; p['likes_count'] = (p['likes_count'] ?? 0) + (liked ? -1 : 1); });
    try { await (liked ? Api.delete('/posts/${p['id']}/like') : Api.post('/posts/${p['id']}/like')); } catch (_) { _load(); }
  }

  Future<void> _translate(Map p) async {
    final id = p['id'] as int;
    final cur = _trans[id];
    if (cur != null && cur['content'] != null) { setState(() => cur['shown'] = !(cur['shown'] == true)); return; }
    setState(() => _trans[id] = {'shown': false, 'busy': true});
    try {
      final loc = context.read<I18n>().locale;
      final r = await Api.post('/posts/$id/translate', {'lang': loc});
      setState(() => _trans[id] = {'content': r['content'], 'shown': r['same'] != true, 'busy': false});
    } catch (_) { setState(() => _trans.remove(id)); }
  }

  /// Serverpad terugwinnen uit een volledige uploads-URL (voor oude posts zonder media-rijen).
  static String? _uploadsPad(dynamic url) {
    final s = '$url';
    final i = s.indexOf('/uploads/');
    return i < 0 ? null : s.substring(i + 9);
  }

  // Bewerken van een eigen bericht: tekst én de foto's/video's (verwijderen + foto's toevoegen).
  Future<void> _editPost(Map p) async {
    final c = TextEditingController(text: (p['content'] ?? '').toString());
    // Huidige media; oude posts zonder media-rijen → afleiden uit de losse velden.
    final List<Map> media = [];
    if (p['media'] is List && (p['media'] as List).isNotEmpty) {
      media.addAll((p['media'] as List).map((m) => {'type': m['type'], 'path': m['path'], 'url': m['url']}));
    } else {
      final ip = _uploadsPad(p['image_path']);
      if (ip != null) media.add({'type': 'image', 'path': ip, 'url': '${p['image_path']}'});
      final vp = _uploadsPad(p['video_path']);
      if (vp != null) media.add({'type': 'video', 'path': vp});
    }
    bool mediaGewijzigd = false;
    bool uploadBezig = false;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
      scrollable: true,
      title: Text(context.tr('feed.edit_title')),
      content: SizedBox(width: double.maxFinite, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(controller: c, maxLines: 5, autofocus: true, textCapitalization: TextCapitalization.sentences),
        if (media.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: SizedBox(height: 64, child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: media.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final m = media[i];
            return Stack(children: [
              ClipRRect(borderRadius: BorderRadius.circular(8), child: m['type'] == 'video'
                ? Container(width: 64, height: 64, color: AppColors.navy, child: const Icon(Icons.videocam, color: Colors.white, size: 24))
                : CachedNetworkImage(imageUrl: '${m['url']}', width: 64, height: 64, fit: BoxFit.cover)),
              Positioned(right: 2, top: 2, child: InkWell(
                onTap: () => setD(() { media.removeAt(i); mediaGewijzigd = true; }),
                child: Container(decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), padding: const EdgeInsets.all(3), child: const Icon(Icons.close, size: 13, color: Colors.white)))),
            ]);
          }))),
        Row(children: [
          IconButton(tooltip: context.tr('feed.camera'), onPressed: uploadBezig ? null : () async {
            XFile? x;
            try { x = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 85); } catch (_) { return; }
            if (x == null) return;
            setD(() => uploadBezig = true);
            try { final r = await Api.uploadImage(x.path); setD(() { media.add({'type': 'image', 'path': r['path'], 'url': r['url']}); mediaGewijzigd = true; }); }
            catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : '$e'))); }
            finally { setD(() => uploadBezig = false); }
          }, icon: const Icon(Icons.camera_alt, color: AppColors.teal)),
          IconButton(tooltip: context.tr('feed.gallery'), onPressed: uploadBezig ? null : () async {
            List<XFile> xs = [];
            try { xs = await ImagePicker().pickMultiImage(maxWidth: 1600, imageQuality: 85); } catch (_) { return; }
            if (xs.isEmpty) return;
            setD(() => uploadBezig = true);
            for (final x in xs) {
              if (media.length >= 10) break;
              try { final r = await Api.uploadImage(x.path); setD(() { media.add({'type': 'image', 'path': r['path'], 'url': r['url']}); mediaGewijzigd = true; }); }
              catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : '$e'))); }
            }
            setD(() => uploadBezig = false);
          }, icon: const Icon(Icons.photo_library, color: AppColors.teal)),
          if (uploadBezig) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal)),
        ]),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('feed.cancel'))),
        FilledButton(onPressed: uploadBezig ? null : () => Navigator.pop(ctx, true), child: Text(context.tr('feed.save'))),
      ],
    )));
    if (ok != true || !mounted) return;
    try {
      final r = await Api.put('/posts/${p['id']}', {
        'content': c.text.trim(),
        // alleen meesturen als er echt iets aan de media veranderd is
        if (mediaGewijzigd) 'media': [for (final m in media) {'type': m['type'], 'path': m['path']}],
      });
      final d = (r is Map && r['data'] is Map) ? r['data'] as Map : null;
      setState(() {
        p['content'] = d?['content'] ?? c.text.trim();
        if (d != null) { p['media'] = d['media']; p['image_path'] = d['image_path']; }
      });
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : '$e'))); }
  }

  void _openComments(Map p) {
    final meId = context.read<AuthState>().user?.id;
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => CommentsSheet(
      postId: p['id'], meId: meId,
      onCount: (d) => setState(() => p['comments_count'] = (((p['comments_count'] ?? 0) as num).toInt() + d).clamp(0, 1 << 31)),
    ));
  }

  Widget _mediaChip(IconData icon, String label, VoidCallback onRemove) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: const Color(0xFFECF1F4), borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: AppColors.teal), const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
      const SizedBox(width: 6),
      InkWell(onTap: onRemove, child: const Icon(Icons.close, size: 16, color: Colors.black38)),
    ]),
  );

  Widget _onlineBar(BuildContext context) {
    final rt = context.watch<RealtimeService>();
    if (rt.onlineCount == 0) return const SizedBox.shrink();
    final list = rt.online;
    return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Row(children: [
      Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text('${rt.onlineCount} ${context.tr('online.now')}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy)),
      const SizedBox(width: 12),
      Expanded(child: SizedBox(height: 34, child: ListView.separated(
        scrollDirection: Axis.horizontal, itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) { final u = list[i]; return GestureDetector(
          onTap: u['id'] != null ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: u['id']))) : null,
          child: Avatar(name: u['username'], src: u['avatar_path'], size: 32)); }))),
    ])));
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthState>().user;
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels > n.metrics.maxScrollExtent - 600) _loadMore();
          return false;
        },
        child: ListView.builder(
        padding: const EdgeInsets.all(12) + EdgeInsets.only(bottom: 16 + MediaQuery.of(context).padding.bottom),
        itemCount: _posts.length + 3,
        itemBuilder: (_, idx) {
          if (idx == _posts.length + 2) {
            // Onderste rij: spinner tijdens bijladen, of een nette afsluiting aan het einde.
            if (_loadingMore) return const Padding(padding: EdgeInsets.all(16), child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))));
            if (!_hasMore && _posts.isNotEmpty) return Padding(padding: const EdgeInsets.all(16), child: Center(child: Text('🎣', style: const TextStyle(fontSize: 20))));
            return const SizedBox(height: 24);
          }
          if (idx == 0) return _onlineBar(context);
          if (idx == 1) {
            return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
              Row(children: [
                Avatar(name: me?.username, src: me?.avatarPath, size: 38), const SizedBox(width: 10),
                Expanded(child: TextField(controller: _composer, maxLines: null, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(hintText: context.tr('feed.composerHint'), border: InputBorder.none, filled: false))),
              ]),
              if (_mentionSuggesties.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Align(alignment: Alignment.centerLeft, child: Wrap(spacing: 6, runSpacing: 6, children: [
                for (final f in _mentionSuggesties) ActionChip(
                  avatar: Avatar(name: f['username'], src: f['avatar_path'], size: 22),
                  label: Text('@${f['username']}', style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _kiesMention(f)),
              ]))),
              if (_media.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: SizedBox(height: 76, child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _media.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final m = _media[i];
                  return Stack(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(10), child: m['type'] == 'video'
                      ? Container(width: 76, height: 76, color: AppColors.navy, child: const Icon(Icons.videocam, color: Colors.white, size: 28))
                      : CachedNetworkImage(imageUrl: '${m['url']}', width: 76, height: 76, fit: BoxFit.cover)),
                    Positioned(right: 3, top: 3, child: InkWell(
                      onTap: () => setState(() => _media.removeAt(i)),
                      child: Container(decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), padding: const EdgeInsets.all(3), child: const Icon(Icons.close, size: 14, color: Colors.white)))),
                  ]);
                }))),
              if (_youtube != null && _youtube!.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: _mediaChip(Icons.play_circle_fill, 'YouTube', () => setState(() => _youtube = null))),
              Row(children: [
                IconButton(onPressed: () => _pickPhoto(ImageSource.camera), icon: const Icon(Icons.camera_alt, color: AppColors.teal), tooltip: context.tr('feed.camera')),
                IconButton(onPressed: _videoUploading ? null : () => _pickVideo(ImageSource.camera), icon: _videoUploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal)) : const Icon(Icons.videocam, color: AppColors.teal), tooltip: context.tr('feed.record')),
                IconButton(onPressed: _videoUploading ? null : _pickMedia, icon: const Icon(Icons.photo_library, color: AppColors.teal), tooltip: context.tr('feed.gallery')),
                IconButton(onPressed: _addYoutube, icon: const Icon(Icons.play_circle_fill, color: Colors.redAccent), tooltip: 'YouTube'),
                const Spacer(),
                FilledButton(onPressed: _posting ? null : _post, child: Text(context.tr('feed.post'))),
              ]),
            ])));
          }
          final p = _posts[idx - 2] as Map;
          if (p['is_sponsored'] == true) return SponsoredFeedCard(p);
          final u = p['user'] as Map?;
          final mine = u?['username'] == me?.username;
          return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              GestureDetector(onTap: (!mine && u?['id'] != null) ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: u!['id']))) : null,
                child: Avatar(name: u?['username'], src: u?['avatar_path'], size: 38)), const SizedBox(width: 10),
              Expanded(child: GestureDetector(onTap: (!mine && u?['id'] != null) ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: u!['id']))) : null,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(u?['username'] ?? context.tr('feed.angler'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
                  Text(_postDate(p['created_at']), style: const TextStyle(fontSize: 11, color: Colors.black38)),
                ]))),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20, color: Colors.black26),
                onSelected: (v) {
                  if (v == 'edit') _editPost(p);
                  if (v == 'delete') _deletePost(p);
                  if (v == 'report') showReportSheet(context, type: 'post', targetId: p['id']);
                },
                itemBuilder: (_) => [
                  if (mine) PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit_outlined, size: 18, color: Colors.black54), const SizedBox(width: 8), Text(context.tr('feed.menu_edit'))])),
                  if (mine) PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, size: 18, color: Colors.red), const SizedBox(width: 8), Text(context.tr('feed.menu_delete'), style: const TextStyle(color: Colors.red))])),
                  if (!mine) PopupMenuItem(value: 'report', child: Row(children: [const Icon(Icons.flag_outlined, size: 18, color: Colors.black54), const SizedBox(width: 8), Text(context.tr('feed.menu_report'))])),
                ],
              ),
            ]),
            if ((p['content'] ?? '').toString().trim().isNotEmpty) ...[
              Padding(padding: const EdgeInsets.only(top: 8), child: Text((_trans[p['id']]?['shown'] == true && _trans[p['id']]?['content'] != null) ? _trans[p['id']]!['content'] : p['content'], style: const TextStyle(fontSize: 15))),
              Padding(padding: const EdgeInsets.only(top: 4), child: InkWell(onTap: () => _translate(p), child: Row(mainAxisSize: MainAxisSize.min, children: [
                _trans[p['id']]?['busy'] == true ? const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal)) : const Icon(Icons.translate, size: 14, color: AppColors.teal),
                const SizedBox(width: 4),
                Text(_trans[p['id']]?['shown'] == true ? context.tr('feed.show_original') : context.tr('feed.translate'), style: const TextStyle(fontSize: 12, color: AppColors.teal, fontWeight: FontWeight.w600)),
              ]))),
            ],
            // Nieuw formaat: media-carrousel (meerdere foto's/video's); anders de oude enkele velden.
            if (p['media'] is List && (p['media'] as List).isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 10), child: MediaCarousel(media: p['media'] as List))
            else ...[
              if (p['image_path'] != null) Padding(padding: const EdgeInsets.only(top: 10), child: GestureDetector(onTap: () => PhotoViewer.open(context, [p['image_path'].toString()]), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: p['image_path'], width: double.infinity, fit: BoxFit.cover)))),
              if (p['video_path'] != null) Padding(padding: const EdgeInsets.only(top: 10), child: FeedVideo(videoUrl: p['video_path']?.toString(), poster: p['video_poster']?.toString(), ready: p['video_ready'] != false)),
            ],
            if (p['youtube_id'] != null) Padding(padding: const EdgeInsets.only(top: 10), child: FeedVideo(youtubeId: p['youtube_id']?.toString())),
            const Divider(height: 22),
            Row(children: [
              InkWell(onTap: () => _toggleLike(p), child: Row(children: [Icon(Icons.thumb_up, size: 18, color: p['liked_by_me'] == true ? AppColors.teal : Colors.black38), const SizedBox(width: 5), Text('${p['likes_count'] ?? 0}')])),
              const SizedBox(width: 20),
              InkWell(onTap: () => _openComments(p), child: Row(children: [const Icon(Icons.mode_comment_outlined, size: 18, color: Colors.black38), const SizedBox(width: 5), Text('${p['comments_count'] ?? 0}')])),
              if ((p['visibility'] ?? 'public') == 'public') ...[
                const SizedBox(width: 20),
                InkWell(onTap: () {
                  Clipboard.setData(ClipboardData(text: 'https://yessfish.com/deel/bericht/${p['id']}'));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link gekopieerd — plak \'m om te delen 🔗')));
                }, child: const Row(children: [Icon(Icons.share_outlined, size: 18, color: Colors.black38), SizedBox(width: 5), Text('Delen', style: TextStyle(color: Colors.black54))])),
              ],
            ]),
          ])));
        },
      ),
      ),
    );
  }
}

class CommentsSheet extends StatefulWidget {
  final int postId;
  final int? meId;
  final void Function(int delta) onCount;
  const CommentsSheet({super.key, required this.postId, required this.meId, required this.onCount});
  @override
  State<CommentsSheet> createState() => CommentsSheetState();
}

class CommentsSheetState extends State<CommentsSheet> {
  List _comments = [];
  final _input = TextEditingController();
  bool _loading = true;
  Map? _replyTo; // reactie waarop geantwoord wordt (1 niveau)
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final r = await Api.get('/posts/${widget.postId}/comments'); setState(() { _comments = r['data'] ?? []; _loading = false; }); }
    catch (_) { setState(() => _loading = false); }
  }
  // Top-level reacties (of wees-antwoorden) met hun antwoorden ingesprongen eronder.
  List<Widget> _grouped(BuildContext context) {
    final ids = _comments.map((c) => c['id']).toSet();
    final tops = _comments.where((c) => c['parent_id'] == null || !ids.contains(c['parent_id'])).toList();
    final out = <Widget>[];
    for (final c in tops) {
      out.add(_row(context, c, false));
      final kids = _comments.where((k) => k['parent_id'] == c['id']).toList().reversed;
      for (final k in kids) { out.add(Padding(padding: const EdgeInsets.only(left: 34), child: _row(context, k, true))); }
    }
    return out;
  }

  Widget _row(BuildContext context, dynamic c, bool isReply) {
    final u = c['user'] as Map?;
    final mineC = widget.meId != null && (c['user_id'] == widget.meId || u?['id'] == widget.meId);
    return ListTile(
      dense: isReply,
      contentPadding: EdgeInsets.zero,
      leading: Avatar(name: u?['username'], src: u?['avatar_path'], size: isReply ? 26 : 32),
      title: Text(u?['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(c['body'] ?? ''),
        if (!isReply) InkWell(onTap: () => setState(() => _replyTo = c), child: Padding(padding: const EdgeInsets.only(top: 2), child: Text(context.tr('feed.reply'), style: const TextStyle(fontSize: 11, color: AppColors.teal, fontWeight: FontWeight.w600)))),
      ]),
      trailing: mineC ? IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.black26), onPressed: () => _del(c)) : null,
    );
  }

  Future<void> _del(Map c) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      scrollable: true,
      content: Text(context.tr('feed.comment_del_confirm')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('feed.cancel'))),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('feed.menu_delete'))),
      ],
    ));
    if (ok != true || !mounted) return;
    try {
      await Api.delete('/posts/${widget.postId}/comments/${c['id']}');
      setState(() => _comments.remove(c)); widget.onCount(-1);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : '$e'))); }
  }

  Future<void> _add() async {
    if (_input.text.trim().isEmpty) return;
    final body = _input.text.trim(); _input.clear();
    final parentId = _replyTo?['id'];
    try { final c = await Api.post('/posts/${widget.postId}/comments', {'body': body, if (parentId != null) 'parent_id': parentId}); setState(() { _comments.insert(0, c); _replyTo = null; }); widget.onCount(1); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'Er ging iets mis'))); }
  }
  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(height: MediaQuery.of(context).size.height * 0.7, child: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: Text(context.tr('feed.comments'), style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.symmetric(horizontal: 12) + EdgeInsets.only(bottom: 16 + MediaQuery.of(context).padding.bottom), children: _grouped(context))),
        if (_replyTo != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [
          Expanded(child: Text('${context.tr('feed.replying_to')} ${(_replyTo!['user'] as Map?)?['username'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.teal, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
          IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.black38), onPressed: () => setState(() => _replyTo = null)),
        ])),
        SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
          Expanded(child: TextField(controller: _input, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(hintText: context.tr('feed.commentHint')))),
          IconButton.filled(style: IconButton.styleFrom(backgroundColor: AppColors.teal), onPressed: _add, icon: const Icon(Icons.send)),
        ]))),
      ])));
  }
}
