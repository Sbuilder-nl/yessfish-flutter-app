class FishingCatch {
  final String id;
  final String userId;
  final String fishSpecies;
  final double? weight;
  final double? length;
  final String? location;
  final String? waterName;
  final String? imageUrl;
  final String? notes;
  final String createdAt;
  final String timeAgo;

  FishingCatch({
    required this.id,
    required this.userId,
    required this.fishSpecies,
    this.weight,
    this.length,
    this.location,
    this.waterName,
    this.imageUrl,
    this.notes,
    required this.createdAt,
    required this.timeAgo,
  });

  factory FishingCatch.fromJson(Map<String, dynamic> json) {
    return FishingCatch(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      fishSpecies: json['fish_species'] ?? 'Onbekend',
      weight: json['weight'] != null ? (json['weight']).toDouble() : null,
      length: json['length'] != null ? (json['length']).toDouble() : null,
      location: json['location'],
      waterName: json['water_name'],
      imageUrl: json['image_url'],
      notes: json['notes'],
      createdAt: json['created_at'] ?? '',
      timeAgo: json['time_ago'] ?? '',
    );
  }
}
