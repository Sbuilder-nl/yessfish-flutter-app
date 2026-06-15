import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api.dart';
import 'realtime.dart';

/// Globale realtime: meldingen-teller + live feed-posts.
class RealtimeService extends ChangeNotifier {
  Realtime? _rt;
  int unread = 0;
  final _feed = StreamController<Map>.broadcast();
  Stream<Map> get feedPosts => _feed.stream;

  Future<void> start(int userId) async {
    if (_rt != null) return;
    try { final r = await Api.get('/notifications/unread-count'); unread = (r['count'] ?? 0) as int; notifyListeners(); } catch (_) {}
    final rt = Realtime()..connect();
    rt.events.listen((e) {
      final ev = e['event'].toString();
      final ch = e['channel']?.toString() ?? '';
      if (ev.contains('BroadcastNotificationCreated') && ch.contains('App.Models.User')) {
        unread++; notifyListeners();
      } else if (ev.contains('post.created') && ch == 'feed') {
        final data = e['data'];
        if (data is Map && data['post'] is Map) _feed.add(Map<String, dynamic>.from(data['post']));
      }
    });
    rt.subscribe('private-App.Models.User.$userId');
    rt.subscribe('feed');
    _rt = rt;
  }

  void clearUnread() { if (unread != 0) { unread = 0; notifyListeners(); } }

  void stop() { _rt?.dispose(); _rt = null; unread = 0; }
}
