import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String? userName;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.userName,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late final Dio _dio;
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  String _friendshipStatus = 'none'; // none, request_sent, request_received, friends
  bool _sendingRequest = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final client = await DioClient.getInstance();
    _dio = client.dio;
    await _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final response = await _dio.get(
        '/user-profile.php',
        queryParameters: {'user_id': widget.userId},
      );

      if (response.data['success'] == true) {
        setState(() {
          _profile = response.data['profile'];
          _friendshipStatus = response.data['friendship_status'] ?? 'none';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij laden: $e')),
        );
      }
    }
  }

  Future<void> _sendFriendRequest() async {
    setState(() => _sendingRequest = true);

    try {
      final response = await _dio.post(
        '/friends.php',
        data: {'friend_id': widget.userId},
      );

      if (response.data['success'] == true) {
        setState(() {
          _friendshipStatus = 'request_sent';
          _sendingRequest = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? 'Vriendschapsverzoek verstuurd!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _sendingRequest = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    // Navigate to chat screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat openen komt binnenkort')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.userName ?? 'Profiel'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profiel')),
        body: const Center(child: Text('Profiel niet gevonden')),
      );
    }

    final profile = _profile!;
    final isOwnProfile = _profile!['is_own_profile'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(profile['name'] ?? 'Profiel'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: profile['profile_photo'] != null
                        ? NetworkImage(profile['profile_photo'])
                        : null,
                    child: profile['profile_photo'] == null
                        ? Text(
                            (profile['name'] ?? '?')[0].toUpperCase(),
                            style: const TextStyle(fontSize: 32),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile['name'] ?? 'Onbekend',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (profile['username'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '@${profile['username']}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (profile['bio'] != null && profile['bio'].isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      profile['bio'],
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatColumn(
                        label: 'Posts',
                        value: '${profile['posts_count'] ?? 0}',
                      ),
                      _StatColumn(
                        label: 'Vangsten',
                        value: '${profile['catches_count'] ?? 0}',
                      ),
                      _StatColumn(
                        label: 'Vrienden',
                        value: '${profile['friends_count'] ?? 0}',
                      ),
                    ],
                  ),

                  // Action buttons
                  if (!isOwnProfile) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        // Friend request button
                        Expanded(
                          child: _buildFriendButton(theme),
                        ),
                        const SizedBox(width: 12),
                        // Message button
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _sendMessage,
                            icon: const Icon(Icons.message),
                            label: const Text('Bericht'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Additional info
          if (profile['location'] != null || profile['website'] != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (profile['location'] != null) ...[
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 20, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Text(profile['location']),
                        ],
                      ),
                    ],
                    if (profile['website'] != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.link, size: 20, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              profile['website'],
                              style: TextStyle(color: theme.colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Recent activity section would go here
        ],
      ),
    );
  }

  Widget _buildFriendButton(ThemeData theme) {
    if (_friendshipStatus == 'friends') {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle),
        label: const Text('Vrienden'),
      );
    } else if (_friendshipStatus == 'request_sent') {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.schedule),
        label: const Text('Verzoek verstuurd'),
      );
    } else if (_friendshipStatus == 'request_received') {
      return FilledButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ga naar vriendschapsverzoeken om te accepteren')),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Verzoek ontvangen'),
      );
    } else {
      return FilledButton.icon(
        onPressed: _sendingRequest ? null : _sendFriendRequest,
        icon: _sendingRequest
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.person_add),
        label: Text(_sendingRequest ? 'Versturen...' : 'Vriend toevoegen'),
      );
    }
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
