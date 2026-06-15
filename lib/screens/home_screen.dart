import 'package:flutter/material.dart';
import '../core/config.dart';
import 'feed_screen.dart';
import 'catches_screen.dart';
import 'bite_screen.dart';
import 'clubs_screen.dart';
import 'profile_screen.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Icon(Icons.set_meal, color: Colors.white),
          const SizedBox(width: 8),
          Text(_titles[_i], style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
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
