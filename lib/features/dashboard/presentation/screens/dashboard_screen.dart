import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.waves, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'YessFish',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Navigate to search
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _FeedTab(),
          _CatchesTab(),
          _SpotsTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.phishing_outlined),
            selectedIcon: Icon(Icons.phishing),
            label: 'Vangsten',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Plekken',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profiel',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                // TODO: Navigate to create post
              },
              icon: const Icon(Icons.add),
              label: const Text('Post'),
            )
          : null,
    );
  }
}

// Feed Tab
class _FeedTab extends StatelessWidget {
  const _FeedTab();

  @override
  Widget build(BuildContext context) {
    // Demo posts
    final posts = List.generate(
      10,
      (index) => _DemoPost(
        username: 'visser${index + 1}',
        timeAgo: '${index + 1}u geleden',
        content: index % 3 == 0
            ? 'Mooie snoek gevangen van 85cm! 🎣'
            : index % 3 == 1
                ? 'Perfecte dag voor karpervissen. Wie gaat er mee?'
                : 'Net een prachtige karper van 12kg gevangen! 💪',
        likes: (index + 1) * 5,
        comments: (index + 1) * 2,
        hasImage: index % 2 == 0,
      ),
    );

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Implement refresh
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) => _PostCard(post: posts[index]),
      ),
    );
  }
}

// Catches Tab
class _CatchesTab extends StatelessWidget {
  const _CatchesTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.phishing, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Je vangsten',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Hier komen al je vangsten te staan',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// Spots Tab
class _SpotsTab extends StatelessWidget {
  const _SpotsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Visplekken',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Ontdek de beste visplekken',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 16),
          Chip(
            avatar: Icon(Icons.star, size: 16),
            label: Text('Premium Viskaart binnenkort beschikbaar!'),
          ),
        ],
      ),
    );
  }
}

// Profile Tab
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 48,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Demo Gebruiker',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '@demo_user',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatColumn(label: 'Vangsten', value: '0'),
                    _StatColumn(label: 'Volgers', value: '0'),
                    _StatColumn(label: 'Volgend', value: '0'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Settings
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Profiel bewerken'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to edit profile
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Instellingen'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to settings
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.workspace_premium,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Premium Upgrade'),
                subtitle: const Text('Ontgrendel alle features'),
                trailing: Chip(
                  label: const Text('PRO'),
                  backgroundColor: theme.colorScheme.primaryContainer,
                ),
                onTap: () {
                  // TODO: Navigate to premium
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Logout
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Uitloggen',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              // TODO: Implement logout
            },
          ),
        ),
      ],
    );
  }
}

// Stat Column Widget
class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// Demo Post Model
class _DemoPost {
  final String username;
  final String timeAgo;
  final String content;
  final int likes;
  final int comments;
  final bool hasImage;

  _DemoPost({
    required this.username,
    required this.timeAgo,
    required this.content,
    required this.likes,
    required this.comments,
    required this.hasImage,
  });
}

// Post Card Widget
class _PostCard extends StatelessWidget {
  final _DemoPost post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                post.username[0].toUpperCase(),
                style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
              ),
            ),
            title: Text(post.username),
            subtitle: Text(post.timeAgo),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // TODO: Show post options
              },
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(post.content),
          ),
          const SizedBox(height: 8),

          // Image placeholder
          if (post.hasImage)
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.image,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () {},
                ),
                Text('${post.likes}'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: () {},
                ),
                Text('${post.comments}'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () {},
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.bookmark_border),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
