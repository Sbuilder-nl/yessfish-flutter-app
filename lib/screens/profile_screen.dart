import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth.dart';
import '../core/config.dart';
import '../core/api.dart';
import '../core/units.dart';
import '../core/realtime_service.dart';
import '../core/i18n.dart';
import '../widgets/avatar.dart';
import 'licenses_screen.dart';
import 'leaderboard_screen.dart';
import 'clubs_screen.dart';
import 'friends_screen.dart';
import 'species_screen.dart';
import 'weather_screen.dart';
import 'messages_screen.dart';
import 'notifications_screen.dart';
import 'map_screen.dart';
import 'edit_profile_screen.dart';
import 'tournaments_screen.dart';
import 'albums_screen.dart';
import 'tackle_screen.dart';
import 'identify_screen.dart';
import 'moderation_screen.dart';
import 'settings_screen.dart';
import 'discipline_dashboards_screen.dart';
import '../core/disciplines_i18n.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map? _stats;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<RealtimeService>().refreshCounts());
    _loadStats();
  }

  Future<void> _loadStats() async {
    try { final r = await Api.get('/profile/stats'); if (mounted) setState(() => _stats = r is Map ? r : null); } catch (_) {}
  }

  Widget _statsCard() {
    final s = _stats;
    if (s == null) return const SizedBox.shrink();
    Widget pill(IconData ic, String val, String lbl) => Expanded(child: Column(children: [
      Icon(ic, color: AppColors.teal, size: 20), const SizedBox(height: 4),
      Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.navy)),
      Text(lbl, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black54)),
    ]));
    final big = s['biggest'];
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(children: [
        Row(children: [
          pill(Icons.set_meal, '${s['catches'] ?? 0}', context.tr('stats.catches')),
          pill(Icons.calendar_month, '${s['this_month'] ?? 0}', context.tr('stats.this_month')),
          pill(Icons.menu_book_outlined, '${s['species'] ?? 0}', context.tr('stats.species')),
        ]),
        if (big != null && big['weight_kg'] != null) ...[
          const Divider(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.emoji_events, color: Color(0xFFD4A017), size: 18), const SizedBox(width: 6),
            Text('${context.tr('stats.biggest')}: ', style: const TextStyle(color: Colors.black54)),
            Flexible(child: Text('${big['species'] ?? ''} \u00b7 ${Units.weight(big['weight_kg'])}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy))),
          ]),
        ],
      ]),
    );
  }

  void _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) context.read<RealtimeService>().refreshCounts();
  }

  Widget _tile(IconData ic, String label, Widget screen, {int badge = 0}) => InkWell(
    onTap: () => _open(screen),
    borderRadius: BorderRadius.circular(14),
    child: Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Stack(clipBehavior: Clip.none, children: [
          Icon(ic, color: AppColors.teal, size: 26),
          if (badge > 0) Positioned(right: -8, top: -6, child: Container(
            padding: const EdgeInsets.all(4), constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
            decoration: const BoxDecoration(color: Color(0xFFFF5A5A), shape: BoxShape.circle),
            child: Text(badge > 9 ? '9+' : '$badge', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)))),
        ]),
        const SizedBox(height: 7),
        Text(label, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 11.5, height: 1.1, color: Color(0xFF334155), fontWeight: FontWeight.w500)),
      ]),
    ),
  );

  Widget _section(String title, List<Widget> tiles) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.fromLTRB(2, 18, 0, 8), child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navy))),
    GridView.count(crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.92, children: tiles),
  ]);

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AuthState>().user;
    final rt = context.watch<RealtimeService>();
    return ListView(padding: const EdgeInsets.all(16), children: [
      const SizedBox(height: 8),
      Center(child: Avatar(name: u?.username, src: u?.avatarPath, size: 84)),
      const SizedBox(height: 10),
      Center(child: Text(u?.firstName ?? u?.username ?? '', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: AppColors.navy))),
      Center(child: Text('@${u?.username ?? ''}', style: const TextStyle(color: Colors.black54))),
      const SizedBox(height: 12),
      Center(child: OutlinedButton.icon(onPressed: () => _open(const EditProfileScreen()), icon: const Icon(Icons.edit, size: 16), label: Text(context.tr('p.edit')))),
      _statsCard(),
      _section(context.tr('sec.social'), [
        _tile(Icons.notifications_outlined, context.tr('p.notifications'), const NotificationsScreen(), badge: rt.unread),
        _tile(Icons.chat_bubble_outline, context.tr('p.messages'), const MessagesScreen(), badge: rt.messagesUnread),
        _tile(Icons.people_outline, context.tr('p.friends'), const FriendsScreen(), badge: rt.pendingFriends),
        _tile(Icons.emoji_events_outlined, context.tr('p.leaderboard'), const LeaderboardScreen()),
        _tile(Icons.groups_outlined, context.tr('nav.clubs'), const ClubsScreen()),
      ]),
      _section(context.tr('sec.fishing'), [
        _tile(Icons.style_outlined, dui(context, 'title'), const DisciplineDashboardsScreen()),
        _tile(Icons.photo_album_outlined, context.tr('p.albums'), const AlbumsScreen()),
        _tile(Icons.phishing, context.tr('p.tackle'), const TackleScreen()),
        _tile(Icons.military_tech_outlined, context.tr('p.tournaments'), const TournamentsScreen()),
        _tile(Icons.map_outlined, context.tr('p.map'), const MapScreen()),
      ]),
      _section(context.tr('sec.tools'), [
        _tile(Icons.auto_awesome, context.tr('p.identify'), const IdentifyScreen()),
        _tile(Icons.menu_book_outlined, context.tr('p.species'), const SpeciesScreen()),
        _tile(Icons.cloud_outlined, context.tr('p.weather'), const WeatherScreen()),
        _tile(Icons.badge_outlined, context.tr('p.docs'), const LicensesScreen()),
      ]),
      _section(context.tr('sec.account'), [
        _tile(Icons.settings_outlined, context.tr('p.settings'), const SettingsScreen()),
        if (u?.canModerate == true) _tile(Icons.shield_outlined, context.tr('p.moderation'), const ModerationScreen()),
      ]),
    ]);
  }
}
