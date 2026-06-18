import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api.dart';
import 'config.dart';

/// Lichte Reverb/Pusher-protocol client over een rauwe WebSocket.
class Realtime {
  WebSocketChannel? _ch;
  String? _socketId;
  bool _connected = false;
  final _events = StreamController<Map<String, dynamic>>.broadcast();
  final _pending = <String>[];

  Stream<Map<String, dynamic>> get events => _events.stream;

  void connect() {
    final url =
        'wss://${Config.reverbHost}:${Config.reverbPort}/app/${Config.reverbKey}?protocol=7&client=flutter&version=1.0';
    _ch = WebSocketChannel.connect(Uri.parse(url));
    _ch!.stream.listen((raw) {
      final Map msg = jsonDecode(raw as String);
      final event = msg['event']?.toString() ?? '';
      if (event == 'pusher:connection_established') {
        _socketId = jsonDecode(msg['data'])['socket_id'];
        _connected = true;
        for (final c in _pending) { _doSubscribe(c); }
        _pending.clear();
      } else if (event == 'pusher_internal:subscription_succeeded' && (msg['channel']?.toString() ?? '').startsWith('presence-')) {
        dynamic d = msg['data']; if (d is String) { try { d = jsonDecode(d); } catch (_) {} }
        final pres = (d is Map && d['presence'] is Map) ? d['presence'] as Map : const {};
        _events.add({'event': 'presence:here', 'channel': msg['channel'], 'data': pres['hash'] ?? {}});
      } else if (event == 'pusher_internal:member_added') {
        dynamic d = msg['data']; if (d is String) { try { d = jsonDecode(d); } catch (_) {} }
        _events.add({'event': 'presence:joined', 'channel': msg['channel'], 'data': d});
      } else if (event == 'pusher_internal:member_removed') {
        dynamic d = msg['data']; if (d is String) { try { d = jsonDecode(d); } catch (_) {} }
        _events.add({'event': 'presence:left', 'channel': msg['channel'], 'data': d});
      } else if (event.isNotEmpty && !event.startsWith('pusher')) {
        dynamic data = msg['data'];
        if (data is String) { try { data = jsonDecode(data); } catch (_) {} }
        _events.add({'event': event, 'channel': msg['channel'], 'data': data});
      }
    }, onError: (_) => _connected = false, onDone: () => _connected = false);
  }

  Future<void> subscribe(String channel) async {
    if (!_connected || _socketId == null) { _pending.add(channel); return; }
    await _doSubscribe(channel);
  }

  Future<void> _doSubscribe(String channel) async {
    final data = <String, dynamic>{'channel': channel};
    if (channel.startsWith('private-') || channel.startsWith('presence-')) {
      try {
        final r = await Api.post('/broadcasting/auth', {'socket_id': _socketId, 'channel_name': channel});
        data['auth'] = r['auth'];
        if (r['channel_data'] != null) data['channel_data'] = r['channel_data'];
      } catch (_) { return; }
    }
    _ch?.sink.add(jsonEncode({'event': 'pusher:subscribe', 'data': data}));
  }

  void unsubscribe(String channel) =>
      _ch?.sink.add(jsonEncode({'event': 'pusher:unsubscribe', 'data': {'channel': channel}}));

  void dispose() { _ch?.sink.close(); _events.close(); }
}
