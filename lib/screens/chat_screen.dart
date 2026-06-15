import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/auth.dart';
import '../core/config.dart';
import '../core/realtime.dart';

class ChatScreen extends StatefulWidget {
  final Map conversation;
  const ChatScreen({super.key, required this.conversation});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List _messages = [];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  Realtime? _rt;
  late int _convId;
  int? _otherId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _convId = widget.conversation['id'];
    final others = (widget.conversation['users'] ?? []) as List;
    if (others.isNotEmpty) _otherId = others.first['id'];
    _load();
    _initRealtime();
  }

  @override
  void dispose() {
    _rt?.unsubscribe('private-conversation.$_convId');
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

  void _initRealtime() {
    final me = context.read<AuthState>().user?.id;
    final rt = Realtime()..connect();
    rt.events.listen((e) {
      if (e['event'].toString().contains('message.sent') && e['channel'] == 'private-conversation.$_convId') {
        final data = e['data'];
        if (data is Map && data['sender_id'] != me) {
          setState(() => _messages.add(data));
          _toBottom();
        }
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
    _input.clear();
    try {
      final m = await Api.post('/messages', {'recipient_id': _otherId, 'body': body});
      setState(() => _messages.add(m));
      _toBottom();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthState>().user?.id;
    final others = (widget.conversation['users'] ?? []) as List;
    final title = others.isNotEmpty ? (others.first['username'] ?? 'Gesprek') : 'Gesprek';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(children: [
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
          controller: _scroll, padding: const EdgeInsets.all(12), itemCount: _messages.length,
          itemBuilder: (_, i) {
            final m = _messages[i] as Map;
            final mine = m['sender_id'] == me;
            return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(margin: const EdgeInsets.symmetric(vertical: 3), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
                decoration: BoxDecoration(color: mine ? AppColors.teal : Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Text(m['body'] ?? '', style: TextStyle(color: mine ? Colors.white : Colors.black87))));
          })),
        SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
          Expanded(child: TextField(controller: _input, decoration: const InputDecoration(hintText: 'Bericht…'), onSubmitted: (_) => _send())),
          const SizedBox(width: 8),
          IconButton.filled(style: IconButton.styleFrom(backgroundColor: AppColors.teal), onPressed: _send, icon: const Icon(Icons.send)),
        ]))),
      ]),
    );
  }
}
