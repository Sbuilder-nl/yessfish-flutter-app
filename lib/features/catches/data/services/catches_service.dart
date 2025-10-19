import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';
import '../../domain/models/fishing_catch.dart';

class CatchesService {
  late final Dio _dio;
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    final client = await DioClient.getInstance();
    _dio = client.dio;
    _initialized = true;
  }

  /// Get all catches for a user
  Future<List<FishingCatch>> getCatches({String? userId}) async {
    await _init();
    
    try {
      final params = <String, dynamic>{};
      if (userId != null) params['user_id'] = userId;

      final response = await _dio.get('/catches.php', queryParameters: params);

      if (response.data['success'] == true) {
        final List catches = response.data['catches'] ?? [];
        return catches.map((json) => FishingCatch.fromJson(json)).toList();
      } else {
        throw Exception(response.data['error'] ?? 'Vangsten ophalen mislukt');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['error'] ?? 'Vangsten ophalen mislukt');
      } else {
        throw Exception('Geen internet verbinding');
      }
    }
  }

  /// Log a new catch
  Future<FishingCatch> logCatch({
    required String fishSpecies,
    double? weight,
    double? length,
    double? latitude,
    double? longitude,
    String? photoUrl,
    String? description,
    String? baitUsed,
    String? weatherConditions,
    double? waterTemp,
    String? caughtAt,
    bool isPublic = true,
  }) async {
    await _init();
    
    try {
      final data = <String, dynamic>{
        'fish_species': fishSpecies,
        'is_public': isPublic,
      };

      if (weight != null) data['weight'] = weight;
      if (length != null) data['length'] = length;
      if (latitude != null) data['latitude'] = latitude;
      if (longitude != null) data['longitude'] = longitude;
      if (photoUrl != null) data['photo_url'] = photoUrl;
      if (description != null) data['description'] = description;
      if (baitUsed != null) data['bait_used'] = baitUsed;
      if (weatherConditions != null) data['weather_conditions'] = weatherConditions;
      if (waterTemp != null) data['water_temp'] = waterTemp;
      if (caughtAt != null) data['caught_at'] = caughtAt;

      final response = await _dio.post('/catches.php', data: data);

      if (response.data['success'] == true) {
        return FishingCatch.fromJson(response.data['catch']);
      } else {
        throw Exception(response.data['error'] ?? 'Vangst loggen mislukt');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['error'] ?? 'Vangst loggen mislukt');
      } else {
        throw Exception('Geen internet verbinding');
      }
    }
  }

  /// Update catch location
  Future<void> updateCatchLocation({
    required String catchId,
    required double latitude,
    required double longitude,
  }) async {
    await _init();
    
    try {
      final response = await _dio.put(
        '/catches.php',
        data: {
          'catch_id': catchId,
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Locatie update mislukt');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['error'] ?? 'Locatie update mislukt');
      } else {
        throw Exception('Geen internet verbinding');
      }
    }
  }

  /// Upload catch photo
  Future<String> uploadCatchPhoto(String filePath) async {
    await _init();
    
    try {
      final formData = FormData.fromMap({
        'catch_photo': await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(
        '/upload-catch-photo.php',
        data: formData,
      );

      if (response.data['success'] == true) {
        return response.data['photo_url'];
      } else {
        throw Exception(response.data['error'] ?? 'Foto uploaden mislukt');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['error'] ?? 'Foto uploaden mislukt');
      } else {
        throw Exception('Geen internet verbinding');
      }
    }
  }

  /// Delete catch
  Future<void> deleteCatch(String catchId) async {
    await _init();
    
    try {
      final response = await _dio.delete(
        '/catches.php',
        data: {'catch_id': catchId},
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Vangst verwijderen mislukt');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['error'] ?? 'Vangst verwijderen mislukt');
      } else {
        throw Exception('Geen internet verbinding');
      }
    }
  }
}
