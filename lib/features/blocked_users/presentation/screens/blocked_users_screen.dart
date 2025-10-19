import "package:flutter/material.dart";
import "../../data/services/blocked_users_service.dart";

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final _blockedUsersService = BlockedUsersService();
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);

    try {
      final blockedUsers = await _blockedUsersService.getBlockedUsers();
      setState(() {
        _blockedUsers = blockedUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fout: $e")),
        );
      }
    }
  }

  Future<void> _unblockUser(String userId, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Gebruiker deblokkeren"),
        content: const Text("Weet je zeker dat je deze gebruiker wilt deblokkeren?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuleren"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Deblokkeren"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _blockedUsersService.unblockUser(userId);
        
        if (mounted) {
          setState(() {
            _blockedUsers.removeAt(index);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Gebruiker gedeblokkeerd"),
              backgroundColor: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF51CF66) 
                  : Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Fout: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Geblokkeerde gebruikers"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blockedUsers.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  onRefresh: _loadBlockedUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _blockedUsers.length,
                    itemBuilder: (context, index) {
                      final user = _blockedUsers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user["profile_photo"] != null
                                ? NetworkImage(user["profile_photo"])
                                : null,
                            child: user["profile_photo"] == null
                                ? Text(
                                    (user["name"] ?? "?")[0].toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          title: Text(
                            user["name"] ?? "Onbekend",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: user["username"] != null
                              ? Text("@${user["username"]}")
                              : null,
                          trailing: OutlinedButton(
                            onPressed: () => _unblockUser(
                              user["blocked_user_id"].toString(),
                              index,
                            ),
                            child: const Text("Deblokkeren"),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              "Geen geblokkeerde gebruikers",
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              "Je hebt nog niemand geblokkeerd",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
