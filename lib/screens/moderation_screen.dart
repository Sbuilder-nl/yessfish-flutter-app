import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';

// Compacte 6-talige labels voor het uitgebreide moderator-dashboard.
const Map<String, Map<String, String>> _ml = {
  'tab_reports': {'nl': 'Meldingen', 'en': 'Reports', 'de': 'Meldungen', 'fr': 'Signalements', 'es': 'Reportes', 'pl': 'Zgłoszenia'},
  'tab_media':   {'nl': 'Media', 'en': 'Media', 'de': 'Medien', 'fr': 'Médias', 'es': 'Multimedia', 'pl': 'Media'},
  'tab_shapes':  {'nl': 'Intekenen', 'en': 'Draw requests', 'de': 'Einzeichnen', 'fr': 'À tracer', 'es': 'Dibujar', 'pl': 'Do naniesienia'},
  'no_shapes':   {'nl': 'Geen intekenen-aanvragen.', 'en': 'No draw requests.', 'de': 'Keine Einzeichnen-Anfragen.', 'fr': 'Aucune demande de tracé.', 'es': 'Sin solicitudes de dibujo.', 'pl': 'Brak próśb o naniesienie.'},
  'go_water':    {'nl': 'Ga naar water', 'en': 'Go to water', 'de': 'Zum Gewässer', 'fr': 'Aller à l\'eau', 'es': 'Ir al agua', 'pl': 'Do wody'},
  'times_asked': {'nl': 'x gevraagd', 'en': 'x asked', 'de': 'x angefragt', 'fr': 'x demandé', 'es': 'x pedido', 'pl': 'x proszono'},
  'tab_members': {'nl': 'Leden', 'en': 'Members', 'de': 'Mitglieder', 'fr': 'Membres', 'es': 'Miembros', 'pl': 'Członkowie'},
  'online':      {'nl': 'online', 'en': 'online', 'de': 'online', 'fr': 'en ligne', 'es': 'en línea', 'pl': 'online'},
  'total':       {'nl': 'leden', 'en': 'members', 'de': 'Mitglieder', 'fr': 'membres', 'es': 'miembros', 'pl': 'członków'},
  'checkedin':   {'nl': 'ingecheckt', 'en': 'checked in', 'de': 'eingecheckt', 'fr': 'enregistrés', 'es': 'registrados', 'pl': 'zameldowani'},
  'new7':        {'nl': 'nieuw (7d)', 'en': 'new (7d)', 'de': 'neu (7T)', 'fr': 'nouveaux (7j)', 'es': 'nuevos (7d)', 'pl': 'nowi (7d)'},
  'approve':     {'nl': 'Goedkeuren', 'en': 'Approve', 'de': 'Freigeben', 'fr': 'Approuver', 'es': 'Aprobar', 'pl': 'Zatwierdź'},
  'reject':      {'nl': 'Afkeuren', 'en': 'Reject', 'de': 'Ablehnen', 'fr': 'Rejeter', 'es': 'Rechazar', 'pl': 'Odrzuć'},
  'no_media':    {'nl': 'Geen media in de wachtrij.', 'en': 'No media awaiting review.', 'de': 'Keine Medien in der Warteschlange.', 'fr': 'Aucun média en attente.', 'es': 'No hay multimedia en cola.', 'pl': 'Brak mediów w kolejce.'},
  'no_members':  {'nl': 'Geen leden gevonden.', 'en': 'No members found.', 'de': 'Keine Mitglieder gefunden.', 'fr': 'Aucun membre trouvé.', 'es': 'No se encontraron miembros.', 'pl': 'Nie znaleziono członków.'},
  'video':       {'nl': 'Video', 'en': 'Video', 'de': 'Video', 'fr': 'Vidéo', 'es': 'Vídeo', 'pl': 'Film'},
  'search':      {'nl': 'Zoek lid…', 'en': 'Search member…', 'de': 'Mitglied suchen…', 'fr': 'Rechercher…', 'es': 'Buscar…', 'pl': 'Szukaj…'},
  'f_pending':   {'nl': 'Wachtrij', 'en': 'Queue', 'de': 'Warteschlange', 'fr': 'File', 'es': 'Cola', 'pl': 'Kolejka'},
  'f_approved':  {'nl': 'Goedgekeurd', 'en': 'Approved', 'de': 'Freigegeben', 'fr': 'Approuvés', 'es': 'Aprobados', 'pl': 'Zatwierdzone'},
  'f_rejected':  {'nl': 'Afgekeurd', 'en': 'Rejected', 'de': 'Abgelehnt', 'fr': 'Rejetés', 'es': 'Rechazados', 'pl': 'Odrzucone'},
  'unban':       {'nl': 'Deblokkeren', 'en': 'Unban', 'de': 'Entsperren', 'fr': 'Débloquer', 'es': 'Desbloquear', 'pl': 'Odblokuj'},
  'warnings':    {'nl': 'waarschuwingen', 'en': 'warnings', 'de': 'Verwarnungen', 'fr': 'avertissements', 'es': 'avisos', 'pl': 'ostrzeżenia'},
  'banned_until':{'nl': 'Geschorst tot', 'en': 'Banned until', 'de': 'Gesperrt bis', 'fr': 'Banni jusqu\'au', 'es': 'Suspendido hasta', 'pl': 'Zbanowany do'},
  'feedban_until':{'nl': 'Feed-verbod tot', 'en': 'Feed-ban until', 'de': 'Feed-Sperre bis', 'fr': 'Interdit (feed) jusqu\'au', 'es': 'Veto de feed hasta', 'pl': 'Zakaz feed do'},
  'member_actions':{'nl': 'Actie op lid', 'en': 'Member action', 'de': 'Mitglieder-Aktion', 'fr': 'Action sur le membre', 'es': 'Acción sobre miembro', 'pl': 'Akcja na członku'},
  'revoke':      {'nl': 'Intrekken', 'en': 'Revoke', 'de': 'Zurückziehen', 'fr': 'Retirer', 'es': 'Retirar', 'pl': 'Cofnij'},
  'tab_log':     {'nl': 'Logboek', 'en': 'Log', 'de': 'Protokoll', 'fr': 'Journal', 'es': 'Registro', 'pl': 'Dziennik'},
  'no_log':      {'nl': 'Nog geen acties.', 'en': 'No actions yet.', 'de': 'Noch keine Aktionen.', 'fr': 'Aucune action.', 'es': 'Sin acciones.', 'pl': 'Brak akcji.'},
  'posts':       {'nl': 'posts', 'en': 'posts', 'de': 'Beiträge', 'fr': 'posts', 'es': 'posts', 'pl': 'posty'},
  'catches':     {'nl': 'vangsten', 'en': 'catches', 'de': 'Fänge', 'fr': 'prises', 'es': 'capturas', 'pl': 'połowy'},
  'media_c':     {'nl': 'media', 'en': 'media', 'de': 'Medien', 'fr': 'médias', 'es': 'multimedia', 'pl': 'media'},
  'history':     {'nl': 'Moderatie-historie', 'en': 'Moderation history', 'de': 'Moderationsverlauf', 'fr': 'Historique', 'es': 'Historial', 'pl': 'Historia'},
};

/// Moderatie-dashboard (admin + moderator): overzicht + meldingen + media-wachtrij + leden.
class ModerationScreen extends StatefulWidget {
  const ModerationScreen({super.key});
  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen> {
  List _reports = [];
  List _media = [];
  List _shapeReqs = [];
  List _members = [];
  List _log = [];
  Map _overview = {};
  bool _loading = true;
  String _mediaStatus = 'pending';
  final _searchCtrl = TextEditingController();

  String _lbl(String k) {
    final loc = context.read<I18n>().locale;
    return _ml[k]?[loc] ?? _ml[k]?['en'] ?? k;
  }

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { final o = await Api.get('/admin/overview'); if (o is Map) _overview = o; } catch (_) {}
    try { final r = await Api.get('/admin/reports'); _reports = r is List ? r : (r['data'] ?? []); } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : context.tr('moderation.no_access'))));
    }
    try { final m = await Api.get('/admin/media?status=$_mediaStatus'); _media = m is List ? m : []; } catch (_) {}
    try { final sq = await Api.get('/admin/shape-requests'); _shapeReqs = (sq is Map && sq['requests'] is List) ? sq['requests'] : []; } catch (_) {}
    try { final u = await Api.get('/admin/users'); _members = u is List ? u : []; } catch (_) {}
    try { final l = await Api.get('/admin/moderation/log'); _log = l is List ? l : []; } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadMembers(String q) async {
    try { final u = await Api.get('/admin/users?q=${Uri.encodeComponent(q)}'); if (mounted) setState(() => _members = u is List ? u : []); } catch (_) {}
  }

  Future<void> _dismiss(int reportId) async {
    try { await Api.put('/admin/reports/$reportId', {'status': 'dismissed'}); _load(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : context.tr('moderation.failed')))); }
  }

  Future<void> _moderateMedia(int id, String status) async {
    try { await Api.put('/admin/media/$id', {'status': status}); _loadMedia(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : context.tr('moderation.failed')))); }
  }

  Future<void> _loadMedia() async {
    try { final m = await Api.get('/admin/media?status=$_mediaStatus'); if (mounted) setState(() => _media = m is List ? m : []); } catch (_) {}
  }

  // Directe moderatie-actie op een lid (zonder melding) — met reden-dialoog.
  Future<void> _moderateUser(String path, int userId, Map<String, dynamic> extra) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(_actionTitle(context, path, extra)),
      content: TextField(controller: reason, maxLines: 2, decoration: InputDecoration(labelText: context.tr('moderation.reason_optional'))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('moderation.cancel'))), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('moderation.confirm')))],
    ));
    if (ok != true) return;
    final m = ScaffoldMessenger.of(context);
    final doneMsg = context.tr('moderation.action_done'); final failMsg = context.tr('moderation.failed');
    try {
      await Api.post('/admin/moderation/$path', {'user_id': userId, 'reason': reason.text.trim(), ...extra});
      m.showSnackBar(SnackBar(content: Text(doneMsg)));
      _load();
    } catch (e) { m.showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : failMsg))); }
  }

  Future<void> _unban(int userId) async {
    final m = ScaffoldMessenger.of(context);
    final doneMsg = context.tr('moderation.action_done'); final failMsg = context.tr('moderation.failed');
    try { await Api.post('/admin/moderation/unban', {'user_id': userId}); m.showSnackBar(SnackBar(content: Text(doneMsg))); _load(); }
    catch (e) { m.showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : failMsg))); }
  }

  Widget _logTile(Map a) {
    final icon = {'warning': '⚠️', 'feed_ban': '🚫', 'ban': '⛔', 'unban': '🔓'}[a['action']] ?? '•';
    return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(dense: true, isThreeLine: true,
      leading: Text(icon, style: const TextStyle(fontSize: 18)),
      title: Text('${a['moderator']?['username'] ?? '?'} → ${a['user']?['username'] ?? '?'}', style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${a['action']}${a['reason'] != null ? ' · ${a['reason']}' : ''}\n${(a['created_at'] ?? '').toString().replaceFirst('T', ' ').padRight(16).substring(0, 16)}', style: const TextStyle(fontSize: 11)),
    ));
  }

  // Lid-review: haalt detail op (profiel + aantallen + recente content + historie) en toont sancties.
  Future<void> _memberActions(Map u) async {
    final uid = u['id'] as int;
    Map detail = {};
    try { final d = await Api.get('/admin/users/$uid/detail'); if (d is Map) detail = d; } catch (_) {}
    if (!mounted) return;
    final du = (detail['user'] as Map?) ?? u;
    final counts = (detail['counts'] as Map?) ?? {};
    final history = (detail['history'] as List?) ?? [];
    final recent = (detail['recent_posts'] as List?) ?? [];
    final banned = du['banned_until'] != null;
    final feedBanned = du['feed_banned_until'] != null;
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => DraggableScrollableSheet(
      expand: false, initialChildSize: 0.7, minChildSize: 0.4, maxChildSize: 0.95,
      builder: (_, scroll) => ListView(controller: scroll, padding: const EdgeInsets.all(16), children: [
        Text('${du['username'] ?? ''}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        Text('${du['email'] ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.black45)),
        const SizedBox(height: 6),
        Text('${du['warnings_count'] ?? 0} ${_lbl('warnings')} · ${counts['posts'] ?? 0} ${_lbl('posts')} · ${counts['catches'] ?? 0} ${_lbl('catches')} · ${counts['media'] ?? 0} ${_lbl('media_c')}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
        if (banned) Text('${_lbl('banned_until')}: ${du['banned_until']}', style: const TextStyle(fontSize: 12, color: AppColors.danger)),
        if (feedBanned) Text('${_lbl('feedban_until')}: ${du['feed_banned_until']}', style: const TextStyle(fontSize: 12, color: Color(0xFFEA580C))),
        const Divider(height: 20),
        if (du['is_admin'] != true) Wrap(spacing: 6, runSpacing: 6, children: [
          OutlinedButton(onPressed: () { Navigator.pop(context); _moderateUser('warn', uid, {}); }, child: Text('⚠️ ${context.tr('moderation.btn_warn')}')),
          OutlinedButton(onPressed: () { Navigator.pop(context); _moderateUser('feed-ban', uid, {'hours': 24}); }, child: Text('🚫 ${context.tr('moderation.btn_feed24')}')),
          OutlinedButton(onPressed: () { Navigator.pop(context); _moderateUser('ban', uid, {'days': 7}); }, child: Text('⛔ ${context.tr('moderation.btn_ban7')}')),
          OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger), onPressed: () { Navigator.pop(context); _moderateUser('ban', uid, {}); }, child: Text('⛔ ${context.tr('moderation.btn_perm')}')),
          if (banned || feedBanned) FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)), onPressed: () { Navigator.pop(context); _unban(uid); }, icon: const Icon(Icons.lock_open, size: 16), label: Text(_lbl('unban'))),
        ]) else const Text('Admin', style: TextStyle(color: Colors.black45)),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(_lbl('posts'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black45)),
          ...recent.take(5).map((p) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text('• ${(p['content'] ?? '').toString().replaceAll('\n', ' ')}${p['deleted_at'] != null ? '  (verwijderd)' : ''}', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: p['deleted_at'] != null ? Colors.black38 : Colors.black87)))),
        ],
        if (history.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(_lbl('history'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black45)),
          ...history.take(20).map((h) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('${h['action']} · ${h['moderator']?['username'] ?? '?'}${h['reason'] != null ? ' — ${h['reason']}' : ''}', style: const TextStyle(fontSize: 11, color: Colors.black54)))),
        ],
      ]),
    ));
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
    final doneMsg = context.tr('moderation.action_done');
    final failMsg = context.tr('moderation.failed');
    try {
      await Api.post('/admin/moderation/$path', {'user_id': userId, 'report_id': reportId, 'reason': reason.text.trim(), ...extra});
      m.showSnackBar(SnackBar(content: Text(doneMsg)));
      _load();
    } catch (e) { m.showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : failMsg))); }
  }

  String _actionTitle(BuildContext context, String path, Map e) => path == 'warn' ? context.tr('moderation.warn_title')
    : path == 'feed-ban' ? '${context.tr('moderation.feedban_title')} (${e['hours']}${context.tr('moderation.hours_suffix')})'
    : (e.containsKey('days') ? '${context.tr('moderation.ban_title')} ${e['days']} ${context.tr('moderation.days_suffix')}' : context.tr('moderation.perm_ban_title'));

  String _reasonNl(BuildContext context, String? r) => {'spam': context.tr('moderation.reason_spam'), 'abuse': context.tr('moderation.reason_abuse'), 'inappropriate': context.tr('moderation.reason_inappropriate'), 'other': context.tr('moderation.reason_other')}[r] ?? (r ?? '');

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(title: Text(context.tr('moderation.title'))), body: const Center(child: CircularProgressIndicator()));
    final openReports = _reports.where((r) => r['status'] == 'open').toList();
    final restReports = _reports.where((r) => r['status'] != 'open').toList();
    return DefaultTabController(length: 5, child: Scaffold(
      appBar: AppBar(title: Text(context.tr('moderation.title')), bottom: TabBar(tabs: [
        Tab(text: '${_lbl('tab_reports')}${openReports.isNotEmpty ? ' (${openReports.length})' : ''}'),
        Tab(text: '${_lbl('tab_media')}${_media.isNotEmpty ? ' (${_media.length})' : ''}'),
        Tab(text: '${_lbl('tab_shapes')}${_shapeReqs.isNotEmpty ? ' (${_shapeReqs.length})' : ''}'),
        Tab(text: _lbl('tab_members')),
        Tab(text: _lbl('tab_log')),
      ])),
      body: Column(children: [
        _statsBar(),
        Expanded(child: TabBarView(children: [
          // Meldingen
          _reports.isEmpty ? Center(child: Text(context.tr('moderation.empty'), style: const TextStyle(color: Colors.black45)))
            : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(12), children: [
                ...openReports.map((r) => _card(context, r)),
                if (restReports.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(2, 16, 0, 6), child: Text(context.tr('moderation.handled'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black45))),
                ...restReports.map((r) => _card(context, r)),
              ])),
          // Media-wachtrij + historie (filter)
          Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(10, 8, 10, 4), child: Row(children: [
              for (final s in const ['pending', 'approved', 'rejected'])
                Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(
                  label: Text(_lbl('f_$s')), selected: _mediaStatus == s,
                  onSelected: (_) { setState(() => _mediaStatus = s); _loadMedia(); })),
            ])),
            Expanded(child: _media.isEmpty ? Center(child: Text(_lbl('no_media'), style: const TextStyle(color: Colors.black45)))
              : RefreshIndicator(onRefresh: _loadMedia, child: ListView(padding: const EdgeInsets.all(12), children: _media.map<Widget>((m) => _mediaCard(m as Map)).toList()))),
          ]),
          // Intekenen-aanvragen
          _shapeReqs.isEmpty ? Center(child: Text(_lbl('no_shapes'), style: const TextStyle(color: Colors.black45)))
            : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(12), children: _shapeReqs.map<Widget>((r) {
                final m = r as Map;
                return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
                  title: Text('${m['name'] ?? '—'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${m['place'] ?? ''}  •  ${m['count'] ?? 0} ${_lbl('times_asked')}'),
                  trailing: FilledButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen(focusWaterId: (m['id'] is num) ? (m['id'] as num).toInt() : int.tryParse('${m['id']}')))),
                    child: Text(_lbl('go_water'))),
                ));
              }).toList())),
          // Leden
          Column(children: [
            Padding(padding: const EdgeInsets.all(10), child: TextField(controller: _searchCtrl, decoration: InputDecoration(prefixIcon: const Icon(Icons.search, size: 20), hintText: _lbl('search'), isDense: true, border: const OutlineInputBorder()), onChanged: _loadMembers)),
            Expanded(child: _members.isEmpty ? Center(child: Text(_lbl('no_members'), style: const TextStyle(color: Colors.black45)))
              : ListView(children: _members.map<Widget>((u) => _memberTile(u as Map)).toList())),
          ]),
          // Logboek
          _log.isEmpty ? Center(child: Text(_lbl('no_log'), style: const TextStyle(color: Colors.black45)))
            : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(12), children: _log.map<Widget>((a) => _logTile(a as Map)).toList())),
        ])),
      ]),
    ));
  }

  Widget _statChip(String value, String label, Color c) => Column(mainAxisSize: MainAxisSize.min, children: [
    Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: c)),
    Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45)),
  ]);

  Widget _statsBar() => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    decoration: const BoxDecoration(color: Color(0xFFF1F5F9), border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _statChip('${_overview['online'] ?? 0}', _lbl('online'), const Color(0xFF16A34A)),
      _statChip('${_overview['checked_in'] ?? 0}', _lbl('checkedin'), AppColors.teal),
      _statChip('${_overview['users'] ?? 0}', _lbl('total'), AppColors.navy),
      _statChip('${_overview['new_7d'] ?? 0}', _lbl('new7'), const Color(0xFF2563EB)),
    ]),
  );

  Widget _mediaCard(Map m) {
    final isVideo = m['type'] == 'video';
    final thumb = isVideo ? m['thumb'] : m['url'];
    final water = m['water'] as Map?;
    return Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        GestureDetector(
          onTap: () { final u = m['url']; if (u != null) launchUrl(Uri.parse('$u'), mode: LaunchMode.externalApplication); },
          child: ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 84, height: 84, child: Stack(fit: StackFit.expand, children: [
            if (thumb != null) Image.network('$thumb', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.black12, child: const Icon(Icons.broken_image, color: Colors.black26)))
            else Container(color: Colors.black87, child: const Icon(Icons.play_circle_outline, color: Colors.white70, size: 30)),
            if (isVideo) const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 30)),
          ])))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${isVideo ? _lbl('video') : 'Foto'} · ${water?['name'] ?? '?'}', style: const TextStyle(fontWeight: FontWeight.w600)),
          if (water?['country'] != null) Text('${water!['country']}', style: const TextStyle(fontSize: 12, color: Colors.black45)),
          Text('${context.tr('moderation.by')} ${m['by'] ?? '—'}', style: const TextStyle(fontSize: 12, color: Colors.black45)),
          if (m['caption'] != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text('${m['caption']}', style: const TextStyle(fontSize: 12))),
        ])),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        if (m['status'] != 'approved') Expanded(child: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)), onPressed: () => _moderateMedia(m['id'], 'approved'), icon: const Icon(Icons.check, size: 16), label: Text(_lbl('approve')))),
        if (m['status'] != 'approved' && m['status'] != 'rejected') const SizedBox(width: 8),
        if (m['status'] != 'rejected') Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger), onPressed: () => _moderateMedia(m['id'], 'rejected'), icon: const Icon(Icons.close, size: 16), label: Text(m['status'] == 'approved' ? _lbl('revoke') : _lbl('reject')))),
      ]),
    ])));
  }

  Widget _memberTile(Map u) {
    final online = u['last_seen_at'] != null && DateTime.tryParse('${u['last_seen_at']}')?.isAfter(DateTime.now().toUtc().subtract(const Duration(minutes: 5))) == true;
    final role = u['is_admin'] == true ? '🛡️' : u['is_moderator'] == true ? '🛠️' : '';
    final banned = u['banned_until'] != null;
    return ListTile(
      dense: true,
      onTap: () => _memberActions(u),
      leading: CircleAvatar(radius: 6, backgroundColor: online ? const Color(0xFF16A34A) : Colors.black26),
      title: Text('${u['username'] ?? ''} $role'),
      subtitle: Text('${u['email'] ?? ''}', style: const TextStyle(fontSize: 11)),
      trailing: u['is_active'] == false || banned ? const Icon(Icons.block, size: 16, color: Colors.red) : const Icon(Icons.chevron_right, size: 18, color: Colors.black26),
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
