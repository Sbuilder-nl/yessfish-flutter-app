class FishingSpot {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String description;
  final String waterType;
  final String fishSpecies;
  final double rating;
  final int reviewCount;
  final int catchCount;
  final String? facilities;
  final double? depth;
  final double? surfaceArea;
  final String? municipality;
  final String? region;
  final String crowdLevel;
  final String crowdLabel;
  final int activeUsers;

  FishingSpot({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.waterType,
    required this.fishSpecies,
    required this.rating,
    required this.reviewCount,
    required this.catchCount,
    this.facilities,
    this.depth,
    this.surfaceArea,
    this.municipality,
    this.region,
    required this.crowdLevel,
    required this.crowdLabel,
    required this.activeUsers,
  });

  factory FishingSpot.fromJson(Map<String, dynamic> json) {
    return FishingSpot(
      id: json['id'].toString(),
      name: json['name'] ?? 'Onbekend',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      waterType: json['water_type'] ?? 'meer',
      fishSpecies: json['fish_species'] ?? 'Diverse vissoorten',
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      catchCount: json['catch_count'] ?? 0,
      facilities: json['facilities'],
      depth: json['depth'] != null ? (json['depth']).toDouble() : null,
      surfaceArea: json['surface_area'] != null ? (json['surface_area']).toDouble() : null,
      municipality: json['municipality'],
      region: json['region'],
      crowdLevel: json['crowd_level'] ?? 'low',
      crowdLabel: json['crowd_label'] ?? 'Rustig',
      activeUsers: json['active_users'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'water_type': waterType,
      'fish_species': fishSpecies,
      'rating': rating,
      'review_count': reviewCount,
      'catch_count': catchCount,
      'facilities': facilities,
      'depth': depth,
      'surface_area': surfaceArea,
      'municipality': municipality,
      'region': region,
      'crowd_level': crowdLevel,
      'crowd_label': crowdLabel,
      'active_users': activeUsers,
    };
  }
}
