import "package:flutter/material.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";
import "package:geolocator/geolocator.dart";
import "../../domain/models/fishing_spot.dart";
import "../../data/services/fishing_spots_service.dart";
import "../../../premium/presentation/screens/premium_screen.dart";

class FishingMapScreen extends StatefulWidget {
  const FishingMapScreen({super.key});

  @override
  State<FishingMapScreen> createState() => _FishingMapScreenState();
}

class _FishingMapScreenState extends State<FishingMapScreen> {
  final FishingSpotsService _spotsService = FishingSpotsService();
  GoogleMapController? _mapController;
  
  List<FishingSpot> _spots = [];
  Set<Marker> _markers = {};
  bool _isLoading = true;
  bool _premiumRequired = false;
  String? _error;
  Map<String, dynamic>? _pricingInfo;
  Position? _userLocation;
  FishingSpot? _selectedSpot;

  // Netherlands center coordinates
  static const LatLng _netherlandsCenter = LatLng(52.1326, 5.2913);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _getUserLocation();
    await _loadSpots();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _userLocation = position;
        });
        
        // Move camera to user location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            12.0,
          ),
        );
      }
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  Future<void> _loadSpots() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _premiumRequired = false;
    });

    try {
      final spots = await _spotsService.getFishingSpots();
      
      if (mounted) {
        setState(() {
          _spots = spots;
          _isLoading = false;
        });
        
        _createMarkers();
      }
    } on PremiumRequiredException catch (e) {
      if (mounted) {
        setState(() {
          _premiumRequired = true;
          _error = e.message;
          _pricingInfo = e.pricingInfo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _createMarkers() {
    final Set<Marker> markers = {};

    // Add user location marker
    if (_userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("user_location"),
          position: LatLng(_userLocation!.latitude, _userLocation!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: "Jouw locatie",
            snippet: "Je bent hier",
          ),
        ),
      );
    }

    // Add fishing spot markers
    for (final spot in _spots) {
      if (spot.latitude != null && spot.longitude != null) {
        // Color based on crowd level
        double hue = BitmapDescriptor.hueGreen; // Low crowd
        if (spot.crowdLevel == "high") {
          hue = BitmapDescriptor.hueOrange;
        } else if (spot.crowdLevel == "very_high") {
          hue = BitmapDescriptor.hueRed;
        } else if (spot.crowdLevel == "medium") {
          hue = BitmapDescriptor.hueYellow;
        }

        markers.add(
          Marker(
            markerId: MarkerId(spot.id),
            position: LatLng(spot.latitude!, spot.longitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
            infoWindow: InfoWindow(
              title: spot.name,
              snippet: "${spot.fishSpecies} • ${spot.crowdLabel}",
            ),
            onTap: () {
              setState(() {
                _selectedSpot = spot;
              });
            },
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  void _navigateToPremium() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PremiumScreen(),
      ),
    ).then((_) {
      // Refresh after returning
      _loadSpots();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_premiumRequired) {
      return _buildPremiumRequired();
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && !_premiumRequired) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text("Fout bij laden viskaart"),
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadSpots,
                child: const Text("Opnieuw proberen"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _userLocation != null
                  ? LatLng(_userLocation!.latitude, _userLocation!.longitude)
                  : _netherlandsCenter,
              zoom: _userLocation != null ? 12.0 : 7.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapToolbarEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onTap: (_) {
              // Close bottom sheet when tapping map
              setState(() {
                _selectedSpot = null;
              });
            },
          ),

          // Spot count badge
          Positioned(
            top: 60,
            left: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${_spots.length} visplekken",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Filter button
          Positioned(
            top: 60,
            right: 16,
            child: FloatingActionButton(
              heroTag: "filter",
              mini: true,
              onPressed: () {
                // TODO: Implement filter dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Filters komen binnenkort!")),
                );
              },
              child: const Icon(Icons.filter_list),
            ),
          ),

          // Selected spot bottom sheet
          if (_selectedSpot != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildSpotBottomSheet(_selectedSpot!),
            ),

          // Legend
          Positioned(
            bottom: _selectedSpot != null ? 240 : 100,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Drukte",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(Colors.green, "Rustig"),
                    _buildLegendItem(Colors.yellow, "Gemiddeld"),
                    _buildLegendItem(Colors.orange, "Druk"),
                    _buildLegendItem(Colors.red, "Zeer druk"),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotBottomSheet(FishingSpot spot) {
    final theme = Theme.of(context);

    return Material(
      elevation: 16,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 300),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Name and crowd badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      spot.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildCrowdBadge(spot),
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
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Description
              Text(
                spot.description,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),

              // Stats
              Row(
                children: [
                  _buildStat(Icons.star, spot.rating.toStringAsFixed(1), Colors.amber),
                  const SizedBox(width: 20),
                  _buildStat(Icons.phishing, "${spot.catchCount}", theme.colorScheme.primary),
                  const SizedBox(width: 20),
                  _buildStat(Icons.people, "${spot.activeUsers}", Colors.blue),
                ],
              ),
              const SizedBox(height: 16),

              // Fish species
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: spot.fishSpecies.split(",").map((fish) {
                  return Chip(
                    label: Text(fish.trim()),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Navigate to spot
                        if (spot.latitude != null && spot.longitude != null) {
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLngZoom(
                              LatLng(spot.latitude!, spot.longitude!),
                              15.0,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.navigation),
                      label: const Text("Navigeer"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        // TODO: Navigate to spot details
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Details voor ${spot.name} komen binnenkort!")),
                        );
                      },
                      icon: const Icon(Icons.info_outline),
                      label: const Text("Details"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCrowdBadge(FishingSpot spot) {
    Color color;
    switch (spot.crowdLevel) {
      case "very_high":
        color = Colors.red;
        break;
      case "high":
        color = Colors.orange;
        break;
      case "medium":
        color = Colors.yellow[700]!;
        break;
      default:
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            spot.crowdLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumRequired() {
    final theme = Theme.of(context);
    final features = _pricingInfo?["features"] as List? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Viskaart"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                  Icons.map,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Premium Vereist",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? "De interactieve viskaart met GPS markers is alleen beschikbaar voor premium leden",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
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
              Text(
                "Je kunt op elk moment opzeggen",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
