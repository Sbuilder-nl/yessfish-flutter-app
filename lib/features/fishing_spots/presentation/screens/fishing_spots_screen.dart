import "package:flutter/material.dart";
import "../../domain/models/fishing_spot.dart";
import "../../data/services/fishing_spots_service.dart";
import "../../../premium/presentation/screens/premium_screen.dart";
import "fishing_map_screen.dart";

class FishingSpotsScreen extends StatefulWidget {
  const FishingSpotsScreen({super.key});

  @override
  State<FishingSpotsScreen> createState() => _FishingSpotsScreenState();
}

class _FishingSpotsScreenState extends State<FishingSpotsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FishingSpotsService _spotsService = FishingSpotsService();
  List<FishingSpot> _spots = [];
  List<FishingSpot> _filteredSpots = [];
  bool _isLoading = true;
  String? _error;
  bool _premiumRequired = false;
  bool _authRequired = false;
  Map<String, dynamic>? _pricingInfo;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSpots();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSpots() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _premiumRequired = false;
    });

    try {
      final spots = await _spotsService.getFishingSpots();
      setState(() {
        _spots = spots;
        _filteredSpots = spots;
        _isLoading = false;
      });
    } on AuthenticationRequiredException catch (e) {
      setState(() {
        _authRequired = true;
        _error = e.message;
        _isLoading = false;
      });
    } on PremiumRequiredException catch (e) {
      setState(() {
        _premiumRequired = true;
        _error = e.message;
        _pricingInfo = e.pricingInfo;
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

  void _navigateToPremium() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PremiumScreen(),
      ),
    ).then((_) {
      // Refresh after returning from premium screen
      _loadSpots();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Visplekken"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: "Lijst"),
            Tab(icon: Icon(Icons.map), text: "Kaart"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListView(),
          const FishingMapScreen(),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return Column(
      children: [
          // Search bar (alleen tonen als niet premium required)
          if (!_premiumRequired) 
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Zoek visplekken...",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterSpots("");
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
      );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_authRequired) {
      return _buildAuthRequired();
    }

    if (_premiumRequired) {
      return _buildPremiumRequired();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text("Fout bij laden visplekken"),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSpots,
              child: const Text("Opnieuw proberen"),
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
            const Text("Geen visplekken gevonden"),
            if (_searchController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _filterSpots("");
                },
                child: const Text("Toon alle plekken"),
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

  Widget _buildAuthRequired() {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Login icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.login,
                size: 64,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              Inloggen Vereist,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Message
            Text(
              _error ?? Je moet ingelogd zijn om de viskaart te bekijken,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),

            // Login button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  // Navigate to login screen
                  Navigator.pushNamed(context, '/login').then((_) {
                    // Refresh after login
                    _loadSpots();
                  });
                },
                icon: const Icon(Icons.login),
                label: const Text(
                  Inloggen,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Register link
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register').then((_) {
                  _loadSpots();
                });
              },
              child: const Text("Nog geen account? Registreer hier"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumRequired() {
    final theme = Theme.of(context);
    final features = _pricingInfo?["features"] as List? ?? [];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Premium icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              "Premium Vereist",
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Message
            Text(
              _error ?? "De viskaart met GPS markers is alleen beschikbaar voor premium leden",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),

            // Pricing card
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "€4,99",
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "/ maand",
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "30 dagen gratis!",
                        style: TextStyle(
                          color: theme.colorScheme.onSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Features
            if (features.isNotEmpty) ...[
              Text(
                "Premium voordelen:",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature.toString(),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 32),
            ],

            // Upgrade button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _navigateToPremium,
                icon: const Icon(Icons.workspace_premium),
                label: const Text(
                  "Upgrade naar Premium",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Info text
            Text(
              "Je kunt op elk moment opzeggen",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
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
            SnackBar(content: Text("Details voor ${spot.name} komen binnenkort!")),
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
                          .join(", "),
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
                children: spot.fishSpecies.split(",").take(3).map((fish) {
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
                    label: "${spot.catchCount} vangsten",
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    icon: Icons.chat_bubble_outline,
                    label: "${spot.reviewCount}",
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
                        "Diepte: ${spot.depth}m",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (spot.surfaceArea != null) ...[
                      Icon(Icons.square_foot, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        "${spot.surfaceArea} ha",
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
      case "very_high":
        return Colors.red;
      case "high":
        return Colors.orange;
      case "medium":
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
