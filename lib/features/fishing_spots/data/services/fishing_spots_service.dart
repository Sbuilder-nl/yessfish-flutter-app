import "package:dio/dio.dart";
import "../../domain/models/fishing_spot.dart";
import "../../../../core/api/dio_client.dart";

class PremiumRequiredException implements Exception {
  final String message;
  final Map<String, dynamic>? pricingInfo;
  
  PremiumRequiredException(this.message, {this.pricingInfo});
  
  @override
  String toString() => message;
}

class AuthenticationRequiredException implements Exception {
  final String message;
  
  AuthenticationRequiredException(this.message);
  
  @override
  String toString() => message;
}

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
      
      final response = await _dio.get("/fishing-spots.php");
      
      if (response.data["success"] == true) {
        final spots = (response.data["spots"] as List)
            .map((spot) => FishingSpot.fromJson(spot))
            .toList();
        return spots;
      } else {
        throw Exception(response.data["error"] ?? "Failed to load fishing spots");
      }
    } on DioException catch (e) {
      // Check for 401 Authentication Required
      if (e.response?.statusCode == 401) {
        throw AuthenticationRequiredException(
          e.response?.data["error"] ?? "Je moet ingelogd zijn om visplekken te bekijken"
        );
      }
      
      // Check for 403 Premium Required error
      if (e.response?.statusCode == 403 && 
          e.response?.data != null && 
          e.response!.data["premium_required"] == true) {
        throw PremiumRequiredException(
          e.response!.data["message"] ?? "Premium vereist voor viskaart",
          pricingInfo: e.response!.data["pricing"],
        );
      }
      
      // Network or other errors
      throw Exception("Netwerkfout: Kon visplekken niet laden. Controleer je internetverbinding.");
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
      rethrow;
    }
  }
}
