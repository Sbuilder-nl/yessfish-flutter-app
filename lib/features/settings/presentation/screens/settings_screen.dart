import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Notification settings
  bool _notifyNewPosts = true;
  bool _notifyComments = true;
  bool _notifyLikes = true;
  bool _notifyFriendRequests = true;
  
  // Privacy settings
  bool _profilePublic = true;
  bool _shareLocation = true;
  
  // App preferences
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Instellingen'),
      ),
      body: ListView(
        children: [
          // Account Section
          _buildSectionHeader('Account', theme),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Wachtwoord wijzigen'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showChangePasswordDialog(context);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('E-mailadres wijzigen'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showChangeEmailDialog(context);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                  title: Text(
                    'Account verwijderen',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showDeleteAccountDialog(context);
                  },
                ),
              ],
            ),
          ),

          // Notifications Section
          _buildSectionHeader('Notificaties', theme),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.post_add_outlined),
                  title: const Text('Nieuwe vangsten'),
                  subtitle: const Text('Van mensen die je volgt'),
                  value: _notifyNewPosts,
                  onChanged: (value) {
                    setState(() => _notifyNewPosts = value);
                    _saveNotificationSettings();
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.comment_outlined),
                  title: const Text('Reacties'),
                  subtitle: const Text('Op je posts en vangsten'),
                  value: _notifyComments,
                  onChanged: (value) {
                    setState(() => _notifyComments = value);
                    _saveNotificationSettings();
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.favorite_outline),
                  title: const Text('Likes'),
                  subtitle: const Text('Op je posts'),
                  value: _notifyLikes,
                  onChanged: (value) {
                    setState(() => _notifyLikes = value);
                    _saveNotificationSettings();
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.person_add_outlined),
                  title: const Text('Vriendverzoeken'),
                  subtitle: const Text('Nieuwe vriendverzoeken'),
                  value: _notifyFriendRequests,
                  onChanged: (value) {
                    setState(() => _notifyFriendRequests = value);
                    _saveNotificationSettings();
                  },
                ),
              ],
            ),
          ),

          // Privacy Section
          _buildSectionHeader('Privacy', theme),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.public),
                  title: const Text('Publiek profiel'),
                  subtitle: const Text('Iedereen kan je profiel zien'),
                  value: _profilePublic,
                  onChanged: (value) {
                    setState(() => _profilePublic = value);
                    _savePrivacySettings();
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.location_on_outlined),
                  title: const Text('Locatie delen'),
                  subtitle: const Text('Toon locatie bij posts'),
                  value: _shareLocation,
                  onChanged: (value) {
                    setState(() => _shareLocation = value);
                    _savePrivacySettings();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text('Geblokkeerde gebruikers'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Geblokkeerde gebruikers komt binnenkort')),
                    );
                  },
                ),
              ],
            ),
          ),

          // App Preferences Section
          _buildSectionHeader('App voorkeuren', theme),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Donkere modus'),
                  subtitle: const Text('Komt binnenkort'),
                  value: _darkMode,
                  onChanged: null, // Disabled for now
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Taal'),
                  subtitle: const Text('Nederlands'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Meertaligheid komt binnenkort')),
                    );
                  },
                ),
              ],
            ),
          ),

          // About Section
          _buildSectionHeader('Over', theme),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('App versie'),
                  subtitle: const Text('1.0.31 (build 32)'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacybeleid'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacybeleid komt binnenkort')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Algemene voorwaarden'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Algemene voorwaarden komt binnenkort')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help komt binnenkort')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _saveNotificationSettings() {
    // TODO: Save to backend API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notificatie instellingen opgeslagen')),
    );
  }

  void _savePrivacySettings() {
    // TODO: Save to backend API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy instellingen opgeslagen')),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wachtwoord wijzigen'),
        content: const Text('Deze functie komt binnenkort beschikbaar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showChangeEmailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('E-mailadres wijzigen'),
        content: const Text('Deze functie komt binnenkort beschikbaar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account verwijderen'),
        content: const Text(
          'Weet je zeker dat je je account wilt verwijderen? Dit kan niet ongedaan worden gemaakt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account verwijderen komt binnenkort')),
              );
            },
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );
  }
}
