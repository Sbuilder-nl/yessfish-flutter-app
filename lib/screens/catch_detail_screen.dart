import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/units.dart';
import '../core/auth.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import '../widgets/photo_viewer.dart';

const _moonNl = {
  'new': 'Nieuwe maan', 'waxing_crescent': 'Wassende sikkel', 'first_quarter': 'Eerste kwartier',
  'waxing_gibbous': 'Wassende maan', 'full': 'Volle maan', 'waning_gibbous': 'Afnemende maan',
  'last_quarter': 'Laatste kwartier', 'waning_crescent': 'Afnemende sikkel',
};

class CatchDetailScreen extends StatefulWidget {
  final int catchId;
  const CatchDetailScreen({super.key, required this.catchId});
  @override
  State<CatchDetailScreen> createState() => _CatchDetailScreenState();
}

class _CatchDetailScreenState extends State<CatchDetailScreen> {
  Map? _c;
  bool _loading = true, _storyBusy = false, _addingPhoto = false;

  List<String> _photoUrls(Map c) {
    final ph = (c['photos'] as List?)?.map((p) => (p as Map)['url'].toString()).toList() ?? [];
    if (ph.isNotEmpty) return ph;
    if (c['photo_path'] != null) return [c['photo_path'].toString()];
    return [];
  }

  Future<void> _addPhoto(ImageSource src) async {
    XFile? x;
    try { x = await ImagePicker().pickImage(source: src, maxWidth: 1600, imageQuality: 85); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${src == ImageSource.camera ? context.tr('catchdetail.openCameraFail') : context.tr('catchdetail.openGalleryFail')}: $e'))); return; }
    if (x == null) return;
    setState(() => _addingPhoto = true);
    final m = ScaffoldMessenger.of(context);
    final failedPrefix = context.tr('catchdetail.failed');
    final addPhotoFail = context.tr('catchdetail.addPhotoFail');
    try {
      final up = await Api.uploadImage(x.path);
      await Api.post('/catches/${widget.catchId}/photos', {'path': up['path']});
      await _load();
    } catch (e) { m.showSnackBar(SnackBar(content: Text(e is ApiException ? '$failedPrefix: ${e.message}' : addPhotoFail))); }
    finally { if (mounted) setState(() => _addingPhoto = false); }
  }

  void _addPhotoSheet() => showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
    ListTile(leading: const Icon(Icons.camera_alt, color: AppColors.teal), title: Text(context.tr('catchdetail.camera')), onTap: () { Navigator.pop(context); _addPhoto(ImageSource.camera); }),
    ListTile(leading: const Icon(Icons.photo, color: AppColors.teal), title: Text(context.tr('catchdetail.gallery')), onTap: () { Navigator.pop(context); _addPhoto(ImageSource.gallery); }),
  ])));

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final r = await Api.get('/catches/${widget.catchId}'); setState(() { _c = r['data']; _loading = false; }); }
    catch (_) { setState(() => _loading = false); }
  }


  Future<void> _edit() async {
    final c = _c!;
    final species = TextEditingController(text: c['species']?.toString() ?? '');
    final weight = TextEditingController(text: c['weight_kg']?.toString() ?? '');
    final length = TextEditingController(text: c['length_cm']?.toString() ?? '');
    final bait = TextEditingController(text: c['bait']?.toString() ?? '');
    final technique = TextEditingController(text: c['technique']?.toString() ?? '');
    final notes = TextEditingController(text: c['notes']?.toString() ?? '');
    String privacy = (c['privacy'] ?? 'public').toString();
    final saved = await showModalBottomSheet<bool>(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(ctx.tr('catchdetail.editTitle'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 12),
          TextField(controller: species, decoration: InputDecoration(labelText: ctx.tr('newcatch.species'))),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: weight, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: ctx.tr('newcatch.weight')))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: length, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: ctx.tr('newcatch.length')))),
          ]),
          const SizedBox(height: 10),
          TextField(controller: bait, decoration: InputDecoration(labelText: ctx.tr('catchdetail.bait'))),
          const SizedBox(height: 10),
          TextField(controller: technique, decoration: InputDecoration(labelText: ctx.tr('catchdetail.technique'))),
          const SizedBox(height: 10),
          TextField(controller: notes, maxLines: 3, decoration: InputDecoration(labelText: ctx.tr('catchdetail.notes'))),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: privacy,
            decoration: InputDecoration(labelText: ctx.tr('newcatch.visibility')),
            items: [
              DropdownMenuItem(value: 'public', child: Text(ctx.tr('newcatch.public'))),
              DropdownMenuItem(value: 'friends', child: Text(ctx.tr('newcatch.friends'))),
              DropdownMenuItem(value: 'private', child: Text(ctx.tr('newcatch.private'))),
            ],
            onChanged: (v) => setSheet(() => privacy = v ?? 'public'),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.tr('newcatch.save'))),
        ])))));
    if (saved != true) return;
    try {
      final r = await Api.put('/catches/${widget.catchId}', {
        'species_text': species.text.trim(),
        'weight_kg': double.tryParse(weight.text.replaceAll(',', '.')),
        'length_cm': double.tryParse(length.text.replaceAll(',', '.')),
        'bait': bait.text.trim().isEmpty ? null : bait.text.trim(),
        'technique': technique.text.trim().isEmpty ? null : technique.text.trim(),
        'notes': notes.text.trim().isEmpty ? null : notes.text.trim(),
        'privacy': privacy,
      });
      if (mounted) { setState(() => _c = r['data']); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('catchdetail.saved')))); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'Er ging iets mis')));
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(context.tr('catchdetail.deleteTitle')), actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('catchdetail.no'))),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('catchdetail.delete'))),
      ]));
    if (ok != true) return;
    try {
      await Api.delete('/catches/${widget.catchId}');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'Er ging iets mis')));
    }
  }

  Future<void> _aiStory() async {
    setState(() => _storyBusy = true);
    try {
      final r = await Api.post('/catches/${widget.catchId}/story', {'lang': 'nl'});
      final story = (r['text'] ?? r['story'] ?? r['content'] ?? '').toString();
      if (!mounted) return;
      final ctrl = TextEditingController(text: story);
      final post = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: Text(context.tr('catchdetail.storyTitle')),
        content: TextField(controller: ctrl, maxLines: 6, decoration: const InputDecoration(border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('catchdetail.close'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('catchdetail.postToFeed'))),
        ]));
      if (post == true) {
        await Api.post('/posts', {'content': ctrl.text, 'visibility': 'public', if (_c?['photo_path'] != null) 'image_path': _c!['photo_path']});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('catchdetail.postedToFeed'))));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'Er ging iets mis')));
    } finally { if (mounted) setState(() => _storyBusy = false); }
  }

  Widget _chip(String t) => Chip(label: Text(t), backgroundColor: AppColors.bg, visualDensity: VisualDensity.compact);

  // Vangst-moment (datum + tijd) als chip.
  Widget _dateChip(BuildContext context, dynamic caughtAt) {
    final dt = DateTime.tryParse('$caughtAt')?.toLocal();
    if (dt == null) return const SizedBox.shrink();
    final s = '${MaterialLocalizations.of(context).formatMediumDate(dt)} · ${TimeOfDay.fromDateTime(dt).format(context)}';
    return Chip(avatar: const Icon(Icons.event, size: 16, color: AppColors.teal), label: Text(s), backgroundColor: AppColors.bg, visualDensity: VisualDensity.compact);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_c == null) return Scaffold(body: Center(child: Text(context.tr('catchdetail.notFound'))));
    final c = _c!;
    final me = context.read<AuthState>().user;
    final mine = c['user'] == null || (c['user'] as Map)['id'] == me?.id;
    final cond = [
      if (c['moon_phase'] != null) _moonNl[c['moon_phase']] ?? c['moon_phase'],
      if (c['pressure_hpa'] != null) '${c['pressure_hpa']} hPa',
      if (c['wind_ms'] != null) '${c['wind_ms']} m/s',
      if (c['cloud_pct'] != null) '${c['cloud_pct']}% ${context.tr('catchdetail.clouds')}',
    ];
    return Scaffold(
      appBar: AppBar(title: Text(c['species'] ?? context.tr('catchdetail.catch')), actions: [
        IconButton(icon: const Icon(Icons.share_outlined), tooltip: 'Delen', onPressed: () {
          Clipboard.setData(ClipboardData(text: 'https://yessfish.com/deel/${widget.catchId}'));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link gekopieerd — plak \'m om te delen 🔗')));
        }),
        if (mine) IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _edit),
        if (mine) IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (_photoUrls(c).length == 1)
          GestureDetector(onTap: () => PhotoViewer.open(context, _photoUrls(c)), child: ClipRRect(borderRadius: BorderRadius.circular(14), child: CachedNetworkImage(imageUrl: _photoUrls(c).first, width: double.infinity, fit: BoxFit.cover)))
        else if (_photoUrls(c).length > 1)
          SizedBox(height: 220, child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _photoUrls(c).length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => GestureDetector(onTap: () => PhotoViewer.open(context, _photoUrls(c), i), child: ClipRRect(borderRadius: BorderRadius.circular(14), child: CachedNetworkImage(imageUrl: _photoUrls(c)[i], width: 300, fit: BoxFit.cover))),
          )),
        const SizedBox(height: 14),
        Text(c['species'] ?? context.tr('catchdetail.fish'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (c['caught_at'] != null) _dateChip(context, c['caught_at']),
          if (c['weight_kg'] != null) _chip(Units.weight(c['weight_kg'])),
          if (c['length_cm'] != null) _chip('${c['length_cm']} cm'),
          if (c['bait'] != null) _chip(c['bait']),
          if (c['technique'] != null) _chip(c['technique']),
        ]),
        if (cond.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(context.tr('catchdetail.conditions'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: cond.map((e) => _chip(e.toString())).toList()),
        ],
        if (c['notes'] != null) ...[const SizedBox(height: 18), Text(c['notes'], style: const TextStyle(color: Colors.black54))],
        if (mine) ...[
          const SizedBox(height: 24),
          OutlinedButton.icon(onPressed: _addingPhoto ? null : _addPhotoSheet,
            icon: _addingPhoto ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add_a_photo),
            label: Text(context.tr('catchdetail.addPhoto'))),
          const SizedBox(height: 10),
          FilledButton.icon(onPressed: _storyBusy ? null : _aiStory,
            icon: _storyBusy ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome),
            label: Text(context.tr('catchdetail.makeStory'))),
        ],
      ]),
    );
  }
}
