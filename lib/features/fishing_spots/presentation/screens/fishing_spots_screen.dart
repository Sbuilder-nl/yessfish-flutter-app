import 'package:flutter/material.dart';
import '../../domain/models/fishing_spot.dart';
import '../../data/services/fishing_spots_service.dart';

class FishingSpotsScreen extends StatefulWidget {
  const FishingSpotsScreen({super.key});

  @override
  State<FishingSpotsScreen> createState() => _FishingSpotsScreenState();
}

class _FishingSpotsScreenState extends State<FishingSpotsScreen> {
  final FishingSpotsService _spotsService = FishingSpotsService();
  List<FishingSpot> _spots = [];
  List<FishingSpot> _filteredSpots = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSpots();
  }

  Future<void> _loadSpots() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final spots = await _spotsService.getFishingSpots();
      setState(() {
        _spots = spots;
        _filteredSpots = spots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterSpots(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSpots = _spots;
      } else {
        _filteredSpots = _spots.where((spot) {
          return spot.name.toLowerCase().contains(query.toLowerCase()) ||
              (spot.municipality?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
              (spot.region?.toLowerCase().contains(query.toLowerCase()) ?? false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Zoek visplekken...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterSpots('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterSpots,
            ),
          ),

          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Fout bij laden visplekken'),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSpots,
              child: const Text('Opnieuw proberen'),
            ),
          ],
        ),
      );
    }

    if (_filteredSpots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Geen visplekken gevonden'),
            if (_searchController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _filterSpots('');
                },
                child: const Text('Toon alle plekken'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSpots,
      child: ListView.builder(
        itemCount: _filteredSpots.length,
        itemBuilder: (context, index) {
          final spot = _filteredSpots[index];
          return _SpotCard(spot: spot);
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _SpotCard extends StatelessWidget {
  final FishingSpot spot;

  const _SpotCard({required this.spot});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to spot details
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Details voor ${spot.name} komen binnenkort!')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and crowd status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      spot.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _CrowdBadge(
                    level: spot.crowdLevel,
                    label: spot.crowdLabel,
                    activeUsers: spot.activeUsers,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Location
              if (spot.municipality != null || spot.region != null) ...[
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      [spot.municipality, spot.region]
                          .where((e) => e != null)
                          .join(', '),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Description
              Text(
                spot.description,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Fish species
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: spot.fishSpecies.split(',').take(3).map((fish) {
                  return Chip(
                    label: Text(
                      fish.trim(),
                      style: const TextStyle(fontSize: 11),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Stats
              Row(
                children: [
                  _StatChip(
                    icon: Icons.star,
                    label: spot.rating.toStringAsFixed(1),
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    icon: Icons.phishing,
                    label: '${spot.catchCount} vangsten',
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    icon: Icons.chat_bubble_outline,
                    label: '${spot.reviewCount}',
                  ),
                ],
              ),

              // Details
              if (spot.depth != null || spot.surfaceArea != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (spot.depth != null) ...[
                      Icon(Icons.water, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Diepte: ${spot.depth}m',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (spot.surfaceArea != null) ...[
                      Icon(Icons.square_foot, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${spot.surfaceArea} ha',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CrowdBadge extends StatelessWidget {
  final String level;
  final String label;
  final int activeUsers;

  const _CrowdBadge({
    required this.level,
    required this.label,
    required this.activeUsers,
  });

  Color _getColor() {
    switch (level) {
      case 'very_high':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow[700]!;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people, size: 14, color: _getColor()),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _getColor(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _StatChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
