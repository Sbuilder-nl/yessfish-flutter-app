import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/parental_i18n.dart';

/// Ouderlijk toezicht in de app: ouder koppelt kind (via code), beheert veilige instellingen,
/// kijkt (alleen-lezen) mee met gesprekken; kind maakt zelf een koppelcode.
class ParentalScreen extends StatefulWidget {
  const ParentalScreen({super.key});
  @override
  State<ParentalScreen> createState() => _ParentalScreenState();
}

class _ParentalScreenState extends State<ParentalScreen> {
  List _kids = [];
  bool _loading = true;
  final _codeCtrl = TextEditingController();
  String? _linkMsg;
  String? _myCode;
  bool _makingCode = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { final r = await Api.get('/parent/children'); setState(() { _kids = r['children'] ?? []; _loading = false; }); }
    catch (_) { setState(() => _loading = false); }
  }

  Future<void> _save(Map k, Map<String, dynamic> patch) async {
    setState(() => (k['settings'] as Map).addAll(patch));
    try { await Api.put('/parent/children/${k['id']}', patch); } catch (_) { _load(); }
  }

  Future<void> _link() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _linkMsg = null);
    try {
      final r = await Api.post('/parent/link', {'code': code});
      final name = (r is Map && r['child'] is Map) ? r['child']['username'] : '';
      setState(() { _linkMsg = '${pt(context, 'linked_with')} @$name.'; _codeCtrl.clear(); });
      _load();
    } catch (e) {
      setState(() => _linkMsg = e is ApiException ? e.message : pt(context, 'link_fail'));
    }
  }

  Future<void> _unlink(Map k) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      content: Text(pt(context, 'unlink_confirm')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(pt(context, 'cancel'))),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(ctx, true), child: Text(pt(context, 'unlink'))),
      ]));
    if (ok != true) return;
    try { await Api.delete('/parent/children/${k['id']}'); setState(() => _kids.remove(k)); } catch (_) {}
  }

  Future<void> _makeCode() async {
    setState(() => _makingCode = true);
    try { final r = await Api.post('/parent/code'); setState(() => _myCode = r['code']?.toString()); }
    catch (_) {} finally { setState(() => _makingCode = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(pt(context, 'title'))),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : ListView(padding: const EdgeInsets.all(14), children: [
            Text(pt(context, 'intro'), style: const TextStyle(color: Colors.black54, fontSize: 13.5)),
            const SizedBox(height: 16),
            if (_kids.isEmpty)
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF1F5F8), borderRadius: BorderRadius.circular(12)),
                child: Text(pt(context, 'none'), style: const TextStyle(color: Colors.black54, fontSize: 13.5)))
            else ..._kids.map((k) => _childCard(k as Map)),

            const SizedBox(height: 20),
            _linkCard(),
            const SizedBox(height: 20),
            _childCodeCard(),
          ]),
    );
  }

  Widget _childCard(Map k) {
    final s = (k['settings'] ?? {}) as Map;
    return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('@${k['username']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy, fontSize: 16)),
        const SizedBox(width: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0x141F8A70), borderRadius: BorderRadius.circular(20)),
          child: Text(pt(context, 'youth'), style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600, fontSize: 11))),
        const Spacer(),
        IconButton(icon: const Icon(Icons.link_off, size: 20, color: Colors.black38), tooltip: pt(context, 'unlink'), onPressed: () => _unlink(k)),
      ]),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text(pt(context, 'profile_to'), style: const TextStyle(fontSize: 14))),
        DropdownButton<String>(
          value: (s['profile_visibility'] ?? 'public').toString(),
          underline: const SizedBox.shrink(),
          items: [
            DropdownMenuItem(value: 'private', child: Text(pt(context, 'only_me'))),
            DropdownMenuItem(value: 'friends_only', child: Text(pt(context, 'friends'))),
            DropdownMenuItem(value: 'public', child: Text(pt(context, 'everyone'))),
          ],
          onChanged: (v) { if (v != null) _save(k, {'profile_visibility': v}); },
        ),
      ]),
      _toggle(pt(context, 'loc'), s['show_location'] == true, (v) => _save(k, {'show_location': v})),
      _toggle(pt(context, 'auto'), s['auto_checkin'] == true, (v) => _save(k, {'auto_checkin': v})),
      _toggle(pt(context, 'share'), s['share_catches_community'] == true, (v) => _save(k, {'share_catches_community': v})),
      Padding(padding: const EdgeInsets.only(top: 4), child: Text(pt(context, 'rec'), style: const TextStyle(color: Colors.black38, fontSize: 11.5))),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildMessagesScreen(childId: k['id'], childUsername: k['username']?.toString() ?? ''))),
        icon: const Icon(Icons.chat_bubble_outline, size: 18), label: Text(pt(context, 'view_msgs'))),
    ])));
  }

  Widget _toggle(String label, bool on, ValueChanged<bool> onChanged) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
      Switch(value: on, activeThumbColor: AppColors.teal, onChanged: onChanged),
    ]));

  Widget _linkCard() => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(pt(context, 'link_title'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
    const SizedBox(height: 4),
    Text(pt(context, 'link_intro'), style: const TextStyle(color: Colors.black54, fontSize: 13)),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: TextField(controller: _codeCtrl, textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(hintText: pt(context, 'code_ph'), border: const OutlineInputBorder(), isDense: true),
        style: const TextStyle(letterSpacing: 3, fontWeight: FontWeight.bold))),
      const SizedBox(width: 8),
      FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.teal), onPressed: _link, child: Text(pt(context, 'link_btn'))),
    ]),
    if (_linkMsg != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_linkMsg!, style: const TextStyle(fontSize: 13, color: Colors.black54))),
  ])));

  Widget _childCodeCard() => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(pt(context, 'child_section'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
    const SizedBox(height: 4),
    Text(pt(context, 'child_intro'), style: const TextStyle(color: Colors.black54, fontSize: 13)),
    const SizedBox(height: 10),
    if (_myCode == null)
      FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: AppColors.navy), onPressed: _makingCode ? null : _makeCode,
        icon: _makingCode ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.qr_code_2, size: 18),
        label: Text(pt(context, 'make_code')))
    else Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0x141F8A70), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(pt(context, 'your_code'), style: const TextStyle(color: Colors.black54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(_myCode!, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 6, color: AppColors.teal)),
        const SizedBox(height: 2),
        Text(pt(context, 'code_valid'), style: const TextStyle(color: Colors.black38, fontSize: 11)),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: _myCode!)); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pt(context, 'copied')))); },
          icon: const Icon(Icons.copy, size: 16), label: Text(pt(context, 'copy'))),
      ])),
  ])));
}

/// Alleen-lezen: gesprekken van het kind → berichten.
class ChildMessagesScreen extends StatefulWidget {
  final int childId; final String childUsername;
  const ChildMessagesScreen({super.key, required this.childId, required this.childUsername});
  @override
  State<ChildMessagesScreen> createState() => _ChildMessagesScreenState();
}

class _ChildMessagesScreenState extends State<ChildMessagesScreen> {
  List _convs = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final r = await Api.get('/parent/children/${widget.childId}/conversations'); setState(() { _convs = r['conversations'] ?? []; _loading = false; }); }
    catch (_) { setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${pt(context, 'msgs_of')} @${widget.childUsername}')),
      body: Column(children: [
        Container(width: double.infinity, color: const Color(0xFFFFF7E6), padding: const EdgeInsets.all(10),
          child: Text(pt(context, 'readonly'), style: const TextStyle(fontSize: 12, color: Color(0xFF8A6D00)))),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator())
          : _convs.isEmpty ? Center(child: Text(pt(context, 'no_convs'), style: const TextStyle(color: Colors.black45)))
          : ListView.separated(itemCount: _convs.length, separatorBuilder: (_, __) => const Divider(height: 1), itemBuilder: (_, i) {
              final c = _convs[i] as Map;
              final users = (c['users'] ?? []) as List;
              final other = users.firstWhere((u) => u['id'] != widget.childId, orElse: () => {'username': '—'});
              final last = c['last_message'] as Map?;
              return ListTile(
                leading: const CircleAvatar(backgroundColor: AppColors.bg, child: Icon(Icons.person, color: AppColors.teal)),
                title: Text('@${other['username']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: last != null ? Text(last['body']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                trailing: const Icon(Icons.chevron_right, color: Colors.black26),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _ChildThreadScreen(childId: widget.childId, childUsername: widget.childUsername, convId: c['id'], otherName: other['username']?.toString() ?? ''))),
              );
            })),
      ]),
    );
  }
}

class _ChildThreadScreen extends StatefulWidget {
  final int childId; final String childUsername; final int convId; final String otherName;
  const _ChildThreadScreen({required this.childId, required this.childUsername, required this.convId, required this.otherName});
  @override
  State<_ChildThreadScreen> createState() => _ChildThreadScreenState();
}

class _ChildThreadScreenState extends State<_ChildThreadScreen> {
  List _msgs = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final r = await Api.get('/parent/children/${widget.childId}/conversations/${widget.convId}/messages');
      setState(() { _msgs = (r is Map ? (r['data'] ?? []) : []) as List; _loading = false; }); }
    catch (_) { setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('@${widget.otherName}')),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : _msgs.isEmpty ? Center(child: Text(pt(context, 'no_msgs'), style: const TextStyle(color: Colors.black45)))
        : ListView(padding: const EdgeInsets.all(12), children: _msgs.map((m) {
            final mm = m as Map;
            final fromChild = mm['sender_id'] == widget.childId;
            return Align(alignment: fromChild ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(margin: const EdgeInsets.symmetric(vertical: 3), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                decoration: BoxDecoration(color: fromChild ? const Color(0x141F8A70) : const Color(0xFFF1F1F1), borderRadius: BorderRadius.circular(14)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('@${(mm['sender'] as Map?)?['username'] ?? (fromChild ? widget.childUsername : widget.otherName)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black45)),
                  Text(mm['body']?.toString() ?? ''),
                ])));
          }).toList()),
    );
  }
}
