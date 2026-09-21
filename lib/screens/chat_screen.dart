import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/berichtregels.dart';
import '../core/auth.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import '../core/realtime.dart';
import '../widgets/report.dart';
import '../core/rondleiding.dart';

class ChatScreen extends StatefulWidget {
  final Map? conversation;
  final int? recipientId;
  final String? recipientName;
  const ChatScreen({super.key, this.conversation, this.recipientId, this.recipientName});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List _messages = [];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  Realtime? _rt;
  int? _convId;
  int? _otherId;
  String? _title;
  bool _onderToezicht = false;   // gesprekspartner staat onder ouderlijk toezicht
  bool _zelfToezicht = false;    // ik sta zelf onder ouderlijk toezicht
  bool _bewaren = false;         // dit gesprek niet automatisch opruimen
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.conversation != null) {
      _convId = widget.conversation!['id'];
      final myId = context.read<AuthState>().user?.id;
      final users = (widget.conversation!['users'] ?? []) as List;
      final others = users.where((u) => (u as Map)['id'] != myId).toList();
      _zelfToezicht = users.any((u) => (u as Map)['id'] == myId && u['onder_toezicht'] == true);
      final other = (others.isNotEmpty ? others.first : (users.isNotEmpty ? users.first : null)) as Map?;
      if (other != null) {
        _otherId = other['id'];
        _title = other['username'];
        _onderToezicht = other['onder_toezicht'] == true;
        _bewaren = widget.conversation!['bewaren'] == true;
      }
      _load();
      _subscribe();
    } else {
      _otherId = widget.recipientId;
      _title = widget.recipientName;
      _loadByRecipient();
    }
  }

  @override
  void dispose() {
    if (_convId != null) _rt?.unsubscribe('private-conversation.$_convId');
    _rt?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await Api.get('/conversations/$_convId/messages');
      final data = (r['data'] ?? []) as List;
      setState(() { _messages.addAll(data.reversed); _loading = false; });
      Api.post('/conversations/$_convId/read').catchError((_) => null);
      _toBottom();
    } catch (_) { setState(() => _loading = false); }
  }

  // Chat geopend vanaf een vriend (recipientId, geen gesprek-object): haal het bestaande
  // 1-op-1 gesprek + berichten op, zodat eerder verstuurde berichten niet "verdwijnen".
  Future<void> _loadByRecipient() async {
    try {
      final r = await Api.get('/messages/with/$_otherId');
      _convId = r['conversation_id'];
      final data = (r['data'] ?? []) as List;
      // Titel = naam van de ander (uit een bericht van hem/haar) als die nog niet bekend is
      // (bv. geopend vanuit een bericht-melding, waar alleen het user-id bekend is).
      if (_title == null) {
        for (final m in data) {
          final sn = (m as Map)['sender'] as Map?;
          if (sn != null && sn['id'] == _otherId) { _title = sn['username']?.toString(); break; }
        }
      }
      setState(() { _messages.addAll(data.reversed); _loading = false; });
      if (_convId != null) {
        _subscribe();
        Api.post('/conversations/$_convId/read').catchError((_) => null);
      }
      _toBottom();
    } catch (_) { setState(() => _loading = false); }
  }

  void _subscribe() {
    if (_convId == null) return;
    final me = context.read<AuthState>().user?.id;
    final rt = _rt ?? (Realtime()..connect());
    rt.events.listen((e) {
      if (e['event'].toString().contains('message.sent') && e['channel'] == 'private-conversation.$_convId') {
        final data = e['data'];
        if (data is Map && data['sender_id'] != me) { setState(() => _messages.add(data)); _toBottom(); }
      }
    });
    rt.subscribe('private-conversation.$_convId');
    _rt = rt;
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  });

  Future<void> _send() async {
    final body = _input.text.trim();
    if (body.isEmpty || _otherId == null) return;
    if (lijktOpHandel(body) && !await _bevestigVerzenden()) return;
    _input.clear();
    try {
      final m = await Api.post('/messages', {'recipient_id': _otherId, 'body': body});
      setState(() => _messages.add(m));
      _toBottom();
      // Nieuw gesprek? haal conversation_id op en abonneer alsnog op realtime.
      if (_convId == null && m is Map && m['conversation_id'] != null) {
        _convId = m['conversation_id'];
        _subscribe();
      }
    } catch (e) {
      _input.text = body; // bericht terugzetten zodat het niet verloren gaat
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : context.tr('common.error'))));
    }
  }

  /// Duwtje vooraf bij een bericht dat op verboden handel lijkt. Draait hier op het toestel:
  /// de tekst gaat niet naar ons toe, want privéberichten mogen we niet meelezen.
  Future<bool> _bevestigVerzenden() async {
    final taal = Localizations.localeOf(context).languageCode;
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      scrollable: true,
      title: Text(br(waarschuwingTitel, taal)),
      content: Text(br(waarschuwingTekst, taal)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(br(waarschuwingTerug, taal))),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(br(waarschuwingDoor, taal))),
      ],
    ));
    return ok == true;
  }

  String _bt(Map<String, String> m) => br(m, Localizations.localeOf(context).languageCode);

  Future<void> _bewaarWissel() async {
    final aan = !_bewaren;
    setState(() => _bewaren = aan);
    try {
      await Api.post('/conversations//bewaren', {'bewaren': aan});
    } catch (_) {
      if (mounted) setState(() => _bewaren = !aan);
    }
  }

  Future<void> _wisGesprek() async {
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      scrollable: true,
      content: Text(_bt(beheerWisVraag)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(MaterialLocalizations.of(c).cancelButtonLabel)),
        FilledButton(onPressed: () => Navigator.pop(c, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade400),
          child: Text(_bt(beheerWis))),
      ],
    ));
    if (ok != true || _convId == null) return;
    try {
      await Api.delete('/conversations/');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('common.error'))));
    }
  }

  Future<void> _wisBericht(int id) async {
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      scrollable: true,
      content: Text(_bt(beheerWisBericht)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(MaterialLocalizations.of(c).cancelButtonLabel)),
        FilledButton(onPressed: () => Navigator.pop(c, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade400),
          child: Text(_bt(beheerVerwijderKnop))),
      ],
    ));
    if (ok != true) return;
    try {
      await Api.delete('/messages/');
      if (mounted) setState(() => _messages.removeWhere((m) => (m as Map)['id'] == id));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('common.error'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthState>().user?.id;
    return Scaffold(
      appBar: AppBar(
        title: Text(_title ?? context.tr('chat.new_message')),
        actions: _convId == null ? null : [
          TourAnker(id: 'berichten-beheer', child: IconButton(
            tooltip: _bt(beheerUitleg),
            onPressed: _bewaarWissel,
            icon: Icon(_bewaren ? Icons.bookmark : Icons.bookmark_border,
                color: _bewaren ? AppColors.teal : null),
          )),
          IconButton(tooltip: _bt(beheerWis), onPressed: _wisGesprek, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: Column(children: [
        // Eerlijk zijn over wat we wel en niet doen: meelezen mag niet, melden werkt wel.
        Container(
          width: double.infinity,
          color: const Color(0xFFEFF4F6),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.lock_outline, size: 15, color: AppColors.teal),
            const SizedBox(width: 6),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(br(privacyRegel, Localizations.localeOf(context).languageCode),
                  style: const TextStyle(fontSize: 11.5, height: 1.35, color: Colors.black54)),
              // Praat je met een kind, dan kan een ouder dit gesprek lezen. Dat hoor je te weten.
              if (_zelfToezicht) Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(br(eigenToezichtRegel, Localizations.localeOf(context).languageCode),
                    style: const TextStyle(fontSize: 11.5, height: 1.35, color: Colors.black87,
                        fontWeight: FontWeight.w600)),
              ),
              if (_onderToezicht) Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(br(toezichtRegel, Localizations.localeOf(context).languageCode),
                    style: const TextStyle(fontSize: 11.5, height: 1.35, color: Colors.black87,
                        fontWeight: FontWeight.w600)),
              ),
            ])),
          ]),
        ),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
          controller: _scroll, padding: const EdgeInsets.all(12) + EdgeInsets.only(bottom: 16 + MediaQuery.of(context).padding.bottom), itemCount: _messages.length,
          itemBuilder: (_, i) {
            final m = _messages[i] as Map;
            final mine = m['sender_id'] == me;
            return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
              child: GestureDetector(
                onLongPress: m['id'] == null ? null : (mine
                    ? () => _wisBericht(m['id'] as int)
                    : () => showReportSheet(context, type: 'message', targetId: m['id'])),
                child: Container(margin: const EdgeInsets.symmetric(vertical: 3), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
                  decoration: BoxDecoration(color: mine ? AppColors.teal : Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Text(m['body'] ?? '', style: TextStyle(color: mine ? Colors.white : Colors.black87)))));
          })),
        SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
          Expanded(child: TextField(controller: _input, decoration: InputDecoration(hintText: context.tr('chat.message_hint')), onSubmitted: (_) => _send())),
          const SizedBox(width: 8),
          IconButton.filled(style: IconButton.styleFrom(backgroundColor: AppColors.teal), onPressed: _send, icon: const Icon(Icons.send)),
        ]))),
      ]),
    );
  }
}
