import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth.dart';
import '../core/config.dart';
import '../core/realtime_service.dart';
import 'feed_screen.dart';
import 'catches_screen.dart';
import 'bite_screen.dart';
import 'clubs_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _i = 0;
  static const _titles = ['Feed', 'Vangsten', 'Bijtkans', 'Clubs', 'Profiel'];
  final _screens = const [FeedScreen(), CatchesScreen(), BiteScreen(), ClubsScreen(), ProfileScreen()];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthState>();
    if (auth.user != null) context.read<RealtimeService>().start(auth.user!.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Icon(Icons.set_meal, color: Colors.white),
          const SizedBox(width: 8),
          Text(_titles[_i], style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
        actions: [
          Consumer<RealtimeService>(builder: (_, rt, __) => Stack(alignment: Alignment.center, children: [
            IconButton(icon: const Icon(Icons.notifications_outlined),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
            if (rt.unread > 0) Positioned(top: 8, right: 8, child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Color(0xFFFF5A5A), shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(rt.unread > 9 ? '9+' : '${rt.unread}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)))),
          ])),
        ],
      ),
      body: IndexedStack(index: _i, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.teal.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dynamic_feed_outlined), selectedIcon: Icon(Icons.dynamic_feed), label: 'Feed'),
          NavigationDestination(icon: Icon(Icons.set_meal_outlined), selectedIcon: Icon(Icons.set_meal), label: 'Vangsten'),
          NavigationDestination(icon: Icon(Icons.water_outlined), selectedIcon: Icon(Icons.water), label: 'Bijtkans'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Clubs'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profiel'),
        ],
      ),
    );
  }
}
