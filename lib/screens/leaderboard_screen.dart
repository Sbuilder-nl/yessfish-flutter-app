import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import '../widgets/avatar.dart';
import 'user_profile_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List _rows = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final r = await Api.get('/leaderboard/anglers'); setState(() { _rows = r is List ? r : (r['data'] ?? []); _loading = false; }); }
    catch (_) { setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(context.tr('leaderboard.title'))),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _rows.isEmpty ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(context.tr('leaderboard.empty'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.black45)))) : ListView.builder(
        padding: const EdgeInsets.all(12), itemCount: _rows.length,
        itemBuilder: (_, i) {
          final r = _rows[i] as Map; final u = r['user'] as Map?;
          final medal = i == 0 ? const Color(0xFFFBBF24) : i == 1 ? const Color(0xFF9CA3AF) : i == 2 ? const Color(0xFFB45309) : AppColors.bg;
          return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
            leading: CircleAvatar(backgroundColor: medal, child: Text('${i + 1}', style: TextStyle(color: i < 3 ? Colors.white : Colors.black54, fontWeight: FontWeight.bold))),
            title: Row(children: [Avatar(name: u?['username'], src: u?['avatar_path'], size: 28), const SizedBox(width: 8), Expanded(child: Text(u?['username'] ?? ''))]),
            subtitle: Text('${r['total_catches'] ?? 0} ${context.tr('leaderboard.catches')} · ${context.tr('leaderboard.biggest')} ${r['biggest_kg'] ?? 0} kg'),
            trailing: Text('${r['total_weight_kg'] ?? 0} kg', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.teal)),
            onTap: u?['id'] != null ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: u!['id']))) : null,
          ));
        }));
  }
}
