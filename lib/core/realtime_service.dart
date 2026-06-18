import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api.dart';
import 'realtime.dart';

/// Globale realtime: meldingen-teller + live feed-posts.
class RealtimeService extends ChangeNotifier {
  Realtime? _rt;
  int unread = 0;          // ongelezen meldingen
  int pendingFriends = 0;  // openstaande vriendverzoeken
  int messagesUnread = 0;  // ongelezen berichten
  final Map<int, Map> _online = {}; // wie is er online (presence-online)
  List<Map> get online => _online.values.toList();
  int get onlineCount => _online.length;
  final _feed = StreamController<Map>.broadcast();
  Stream<Map> get feedPosts => _feed.stream;

  /// (Her)laad de tellers voor de badges (meldingen, verzoeken, berichten).
  Future<void> refreshCounts() async {
    try { final r = await Api.get('/notifications/unread-count'); unread = (r['count'] ?? 0) as int; } catch (_) {}
    try { final p = await Api.get('/friends/pending'); pendingFriends = (p is List ? p.length : ((p['data'] as List?)?.length ?? 0)); } catch (_) {}
    try { final m = await Api.get('/messages/unread-count'); messagesUnread = (m['count'] ?? 0) as int; } catch (_) {}
    notifyListeners();
  }

  Future<void> start(int userId) async {
    if (_rt != null) return;
    await refreshCounts();
    final rt = Realtime()..connect();
    rt.events.listen((e) {
      final ev = e['event'].toString();
      final ch = e['channel']?.toString() ?? '';
      if (ev.contains('BroadcastNotificationCreated') && ch.contains('App.Models.User')) {
        unread++; notifyListeners();
      } else if (ev.contains('post.created') && ch == 'feed') {
        final data = e['data'];
        if (data is Map && data['post'] is Map) _feed.add(Map<String, dynamic>.from(data['post']));
      } else if (ev == 'presence:here') {
        _online.clear();
        final hash = e['data'];
        if (hash is Map) hash.forEach((k, v) { final id = int.tryParse('$k'); if (id != null && v is Map) _online[id] = Map.from(v); });
        notifyListeners();
      } else if (ev == 'presence:joined') {
        final d = e['data'];
        if (d is Map && d['user_id'] != null) { _online[int.parse('${d['user_id']}')] = Map.from(d['user_info'] ?? {}); notifyListeners(); }
      } else if (ev == 'presence:left') {
        final d = e['data'];
        if (d is Map && d['user_id'] != null) { _online.remove(int.parse('${d['user_id']}')); notifyListeners(); }
      }
    });
    rt.subscribe('private-App.Models.User.$userId');
    rt.subscribe('feed');
    rt.subscribe('presence-online');
    _rt = rt;
  }

  void clearUnread() { if (unread != 0) { unread = 0; notifyListeners(); } }

  void stop() { _rt?.dispose(); _rt = null; unread = 0; _online.clear(); }
}
