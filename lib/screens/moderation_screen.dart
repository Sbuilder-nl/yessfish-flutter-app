import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';

/// Moderatie-wachtrij (admin + moderator): meldingen + bewaarde inhoud + sancties.
class ModerationScreen extends StatefulWidget {
  const ModerationScreen({super.key});
  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen> {
  List _reports = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { final r = await Api.get('/admin/reports'); setState(() { _reports = r is List ? r : (r['data'] ?? []); _loading = false; }); }
    catch (e) { setState(() => _loading = false); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : context.tr('moderation.no_access')))); }
  }

  Future<void> _dismiss(int reportId) async {
    try { await Api.put('/admin/reports/$reportId', {'status': 'dismissed'}); _load(); } catch (_) {}
  }

  Future<void> _moderate(String path, int userId, int reportId, Map<String, dynamic> extra) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(_actionTitle(context, path, extra)),
      content: TextField(controller: reason, maxLines: 2, decoration: InputDecoration(labelText: context.tr('moderation.reason_optional'))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('moderation.cancel'))), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('moderation.confirm')))],
    ));
    if (ok != true) return;
    final m = ScaffoldMessenger.of(context);
    try {
      await Api.post('/admin/moderation/$path', {'user_id': userId, 'report_id': reportId, 'reason': reason.text.trim(), ...extra});
      m.showSnackBar(SnackBar(content: Text(context.tr('moderation.action_done'))));
      _load();
    } catch (e) { m.showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : context.tr('moderation.failed')))); }
  }

  String _actionTitle(BuildContext context, String path, Map e) => path == 'warn' ? context.tr('moderation.warn_title')
    : path == 'feed-ban' ? '${context.tr('moderation.feedban_title')} (${e['hours']}${context.tr('moderation.hours_suffix')})'
    : (e.containsKey('days') ? '${context.tr('moderation.ban_title')} ${e['days']} ${context.tr('moderation.days_suffix')}' : context.tr('moderation.perm_ban_title'));

  String _reasonNl(BuildContext context, String? r) => {'spam': context.tr('moderation.reason_spam'), 'abuse': context.tr('moderation.reason_abuse'), 'inappropriate': context.tr('moderation.reason_inappropriate'), 'other': context.tr('moderation.reason_other')}[r] ?? (r ?? '');

  @override
  Widget build(BuildContext context) {
    final open = _reports.where((r) => r['status'] == 'open').toList();
    final rest = _reports.where((r) => r['status'] != 'open').toList();
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('moderation.title'))),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : _reports.isEmpty ? Center(child: Text(context.tr('moderation.empty'), style: const TextStyle(color: Colors.black45)))
        : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(12), children: [
            ...open.map((r) => _card(context, r)),
            if (rest.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(2, 16, 0, 6), child: Text(context.tr('moderation.handled'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black45))),
            ...rest.map((r) => _card(context, r)),
          ])),
    );
  }

  Widget _card(BuildContext context, dynamic rr) {
    final r = rr as Map;
    final snap = r['content_snapshot'] as Map?;
    final authorId = snap?['author_id'];
    final open = r['status'] == 'open';
    return Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('${_reasonNl(context, r['reason'])} · ${r['type']} #${r['target_id']}', style: const TextStyle(fontWeight: FontWeight.bold))),
        if (!open) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)), child: Text(r['status'], style: const TextStyle(fontSize: 11, color: Colors.black45))),
      ]),
      Text('${context.tr('moderation.by')} ${r['reporter']?['username'] ?? '—'}${r['details'] != null ? ' · ${r['details']}' : ''}', style: const TextStyle(fontSize: 12, color: Colors.black45)),
      if (snap != null) Container(width: double.infinity, margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(snap['author'] != null ? '${context.tr('moderation.reported')}: @${snap['author']}' : context.tr('moderation.reported'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
          if (snap['text'] != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('${snap['text']}')),
          if (snap['image'] != null) Padding(padding: const EdgeInsets.only(top: 8), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: snap['image'], height: 130, fit: BoxFit.cover))),
        ])),
      if (open && authorId != null) Padding(padding: const EdgeInsets.only(top: 10), child: Wrap(spacing: 6, runSpacing: 6, children: [
        OutlinedButton(onPressed: () => _moderate('warn', authorId, r['id'], {}), child: Text('⚠️ ${context.tr('moderation.btn_warn')}')),
        OutlinedButton(onPressed: () => _moderate('feed-ban', authorId, r['id'], {'hours': 24}), child: Text('🚫 ${context.tr('moderation.btn_feed24')}')),
        OutlinedButton(onPressed: () => _moderate('ban', authorId, r['id'], {'days': 7}), child: Text('⛔ ${context.tr('moderation.btn_ban7')}')),
        OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger), onPressed: () => _moderate('ban', authorId, r['id'], {}), child: Text('⛔ ${context.tr('moderation.btn_perm')}')),
        TextButton(onPressed: () => _dismiss(r['id']), child: Text(context.tr('moderation.btn_dismiss'))),
      ])),
    ])));
  }
}
