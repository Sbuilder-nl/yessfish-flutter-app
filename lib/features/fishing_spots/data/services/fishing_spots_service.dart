import 'package:dio/dio.dart';
import '../../domain/models/fishing_spot.dart';
import '../../../../core/api/dio_client.dart';

class FishingSpotsService {
  late final Dio _dio;
  bool _initialized = false;

  FishingSpotsService();

  Future<void> _init() async {
    if (_initialized) return;
    
    final client = await DioClient.getInstance();
    _dio = client.dio;
    _initialized = true;
  }

  /// Fetch all fishing spots
  Future<List<FishingSpot>> getFishingSpots() async {
    try {
      await _init();
      
      final response = await _dio.get('/fishing-spots.php');
      
      if (response.data['success'] == true) {
        final spots = (response.data['spots'] as List)
            .map((spot) => FishingSpot.fromJson(spot))
            .toList();
        return spots;
      } else {
        throw Exception(response.data['error'] ?? 'Failed to load fishing spots');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Search fishing spots by name or location
  Future<List<FishingSpot>> searchSpots(String query) async {
    try {
      final spots = await getFishingSpots();
      return spots.where((spot) {
        return spot.name.toLowerCase().contains(query.toLowerCase()) ||
            (spot.municipality?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
            (spot.region?.toLowerCase().contains(query.toLowerCase()) ?? false);
      }).toList();
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }
}
