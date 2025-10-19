import 'package:flutter/material.dart';
import '../data/services/catches_service.dart';
import '../../domain/models/fishing_catch.dart';
import 'add_catch_screen.dart';

class CatchesScreen extends StatefulWidget {
  const CatchesScreen({super.key});

  @override
  State<CatchesScreen> createState() => _CatchesScreenState();
}

class _CatchesScreenState extends State<CatchesScreen> {
  final _catchesService = CatchesService();
  List<FishingCatch> _catches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCatches();
  }

  Future<void> _loadCatches() async {
    setState(() => _isLoading = true);

    try {
      final catches = await _catchesService.getCatches();
      setState(() {
        _catches = catches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij laden: $e')),
        );
      }
    }
  }

  Future<void> _navigateToAddCatch() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCatchScreen(),
      ),
    );

    if (result == true) {
      _loadCatches(); // Refresh list
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _catches.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  onRefresh: _loadCatches,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _catches.length,
                    itemBuilder: (context, index) {
                      return _CatchCard(catch_: _catches[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddCatch,
        icon: const Icon(Icons.add),
        label: const Text('Vangst Toevoegen'),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.phishing,
            size: 80,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Je Vangsten',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Hier komen al je vangsten te staan. Log je vangsten om je visavonturen bij te houden!',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _navigateToAddCatch,
            icon: const Icon(Icons.add),
            label: const Text('Voeg je eerste vangst toe'),
          ),
        ],
      ),
    );
  }
}

class _CatchCard extends StatelessWidget {
  final FishingCatch catch_;

  const _CatchCard({required this.catch_});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (catch_.imageUrl != null)
            Image.network(
              catch_.imageUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Species
                Row(
                  children: [
                    Icon(
                      Icons.phishing,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      catch_.fishSpecies,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stats
                Row(
                  children: [
                    if (catch_.weight != null) ...[
                      Icon(
                        Icons.scale,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${catch_.weight} kg',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (catch_.length != null) ...[
                      Icon(
                        Icons.straighten,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${catch_.length} cm',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),

                // Location and time
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (catch_.location != null) ...[
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        catch_.waterName ?? catch_.location!,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      catch_.timeAgo,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),

                // Notes
                if (catch_.notes != null && catch_.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    catch_.notes!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
