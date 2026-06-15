import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth.dart';
import '../core/config.dart';
import '../widgets/avatar.dart';
import 'licenses_screen.dart';
import 'leaderboard_screen.dart';
import 'friends_screen.dart';
import 'species_screen.dart';
import 'weather_screen.dart';
import 'messages_screen.dart';
import 'notifications_screen.dart';
import 'tournaments_screen.dart';
import 'albums_screen.dart';
import 'tackle_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AuthState>().user;
    Widget item(IconData ic, String label, Widget screen) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(ic, color: AppColors.teal),
            title: Text(label),
            trailing: const Icon(Icons.chevron_right, color: Colors.black26),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
          ),
        );
    return ListView(padding: const EdgeInsets.all(16), children: [
      const SizedBox(height: 8),
      Center(child: Avatar(name: u?.username, src: u?.avatarPath, size: 84)),
      const SizedBox(height: 10),
      Center(child: Text(u?.firstName ?? u?.username ?? '', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: AppColors.navy))),
      Center(child: Text('@${u?.username ?? ''}', style: const TextStyle(color: Colors.black54))),
      const SizedBox(height: 24),
      item(Icons.notifications_outlined, 'Meldingen', const NotificationsScreen()),
      item(Icons.chat_bubble_outline, 'Berichten', const MessagesScreen()),
      item(Icons.people_outline, 'Vrienden', const FriendsScreen()),
      item(Icons.emoji_events_outlined, 'Ranglijst', const LeaderboardScreen()),
      item(Icons.military_tech_outlined, 'Toernooien', const TournamentsScreen()),
      item(Icons.photo_album_outlined, 'Albums', const AlbumsScreen()),
      item(Icons.phishing, 'Uitrusting', const TackleScreen()),
      item(Icons.menu_book_outlined, 'Soortengids', const SpeciesScreen()),
      item(Icons.cloud_outlined, 'Visweer', const WeatherScreen()),
      item(Icons.badge_outlined, 'Visdocumenten', const LicensesScreen()),
      item(Icons.settings_outlined, 'Instellingen', const SettingsScreen()),
    ]);
  }
}
