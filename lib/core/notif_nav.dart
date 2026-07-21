import 'package:flutter/material.dart';
import '../screens/post_detail_screen.dart';
import '../screens/messages_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/friends_screen.dart';
import '../screens/map_screen.dart';
import '../screens/feed_screen.dart';

/// Bepaalt naar welk scherm een melding/push moet navigeren op basis van de `link`
/// (en optioneel het event-type). Gedeeld door de meldingenlijst én de push-tik.
///  - /feed?post=X   → de post openen (met reacties bij een comment-melding)
///  - /berichten...  → berichten
///  - /vrienden      → vrienden
///  - /kaart?w=X     → kaart op dat water
Widget? screenForLink(String link, {String? event}) {
  final l = link;
  final postMatch = RegExp(r'post=(\d+)').firstMatch(l);
  if (postMatch != null) {
    final id = int.tryParse(postMatch.group(1) ?? '');
    if (id != null) return PostDetailScreen(postId: id, openComments: event == 'comment');
  }
  if (l.contains('berichten') || event == 'message') {
    // bericht-melding → open direct het gesprek met die persoon (user=X), anders de lijst
    final uid = int.tryParse(RegExp(r'user=(\d+)').firstMatch(l)?.group(1) ?? '');
    if (uid != null) return ChatScreen(recipientId: uid);
    return const MessagesScreen();
  }
  if (l.contains('vrienden') || event == 'friend_request') return const FriendsScreen();
  if (l.contains('kaart') && l.contains('w=')) {
    final wid = int.tryParse(RegExp(r'w=(\d+)').firstMatch(l)?.group(1) ?? '');
    if (wid != null) return MapScreen(focusWaterId: wid);
  }
  // Fallback: oudere like/comment/tag-meldingen hadden alleen "/feed" (geen post-id) →
  // open dan gewoon de feed i.p.v. nergens heen te gaan.
  if (l.contains('/feed') || event == 'like' || event == 'comment' || event == 'tag') {
    return const _NotifFeedScreen();
  }
  return null;
}

/// Feed met een terug-knop, geopend vanuit een melding zonder specifieke post.
class _NotifFeedScreen extends StatelessWidget {
  const _NotifFeedScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('YessFish')),
        body: const FeedScreen(),
      );
}
