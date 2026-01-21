import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/air_quality_data.dart';
import '../models/user_profile.dart';
import '../models/prediction_data.dart';
import '../models/photo_data.dart';

class ApiService {
  late final Dio _dio;
  final String baseUrl = AppConfig.baseUrl;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors for logging and authentication
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: false,
      error: true,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add authentication token if available
        final token = AppConfig.prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // Handle common errors
        if (error.response?.statusCode == 401) {
          // Handle unauthorized access
          _handleUnauthorized();
        }
        handler.next(error);
      },
    ));
  }

  void _handleUnauthorized() {
    // Clear auth token and redirect to login
    AppConfig.prefs.remove('auth_token');
    // Navigate to login screen (would need navigator context)
  }

  // Authentication
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/register',
        data: {
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.data['token'] != null) {
        await AppConfig.prefs.setString('auth_token', response.data['token']);
      }

      return response.data;
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/v1/auth/logout');
    } catch (e) {
      // Continue with logout even if API call fails
    }
    await AppConfig.prefs.remove('auth_token');
  }

  // Air Quality Data
  Future<AirQualityData> getCurrentAQIData({
    required double latitude,
    required double longitude,
    String? locationId,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/aqi/current',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          if (locationId != null) 'location_id': locationId,
        },
      );

      return AirQualityData.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<List<AirQualityData>> getAQIHistory({
    required double latitude,
    required double longitude,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      final queryParameters = {
        'latitude': latitude,
        'longitude': longitude,
        'limit': limit,
      };

      if (startDate != null) {
        queryParameters['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParameters['end_date'] = endDate.toIso8601String();
      }

      final response = await _dio.get(
        '/api/v1/aqi/history',
        queryParameters: queryParameters,
      );

      return (response.data as List)
          .map((json) => AirQualityData.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<void> submitSensorData(AirQualityData data) async {
    try {
      await _dio.post(
        '/api/v1/aqi/measurements',
        data: data.toJson(),
      );
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  // Predictions
  Future<List<PredictionData>> getPredictionForecast({
    required double latitude,
    required double longitude,
    int hours = 12,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/prediction/forecast',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'hours': hours,
        },
      );

      return (response.data as List)
          .map((json) => PredictionData.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<MicroZoneForecast> getMicroZoneForecast({
    required double latitude,
    required double longitude,
    double radius = 2.0, // km
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/prediction/microzone',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radius': radius,
        },
      );

      return MicroZoneForecast.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<List<SafeRoute>> getSafeRoutes({
    required String startLocation,
    required String endLocation,
    String routeType = 'walking',
    int alternatives = 3,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/prediction/routes',
        queryParameters: {
          'start': startLocation,
          'end': endLocation,
          'type': routeType,
          'alternatives': alternatives,
        },
      );

      return (response.data as List)
          .map((json) => SafeRoute.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  // Health & Scoring
  Future<double> getPersonalHealthScore({
    String? userId,
    List<AirQualityData>? exposureHistory,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/health/score',
        queryParameters: {
          if (userId != null) 'user_id': userId,
          if (exposureHistory != null) 'exposure_history': exposureHistory
              .map((data) => data.toJson())
              .toList(),
        },
      );

      return response.data['health_score'].toDouble();
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<void> updateHealthProfile(HealthProfile profile) async {
    try {
      await _dio.put(
        '/api/v1/health/profile',
        data: profile.toJson(),
      );
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  // Photo Analysis
  Future<PhotoAnalysis> analyzePhoto({
    required File imageFile,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'pollution_photo.jpg',
        ),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (metadata != null) 'metadata': jsonEncode(metadata),
      });

      final response = await _dio.post(
        '/api/v1/capture/analyze',
        data: formData,
      );

      return PhotoAnalysis.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<PhotoData> submitPhoto(PhotoData photoData) async {
    try {
      final response = await _dio.post(
        '/api/v1/capture/submit',
        data: photoData.toJson(),
      );

      return PhotoData.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<List<PhotoData>> getCommunityPhotos({
    double? latitude,
    double? longitude,
    double radius = 10.0, // km
    int limit = 50,
    String? status,
  }) async {
    try {
      final queryParameters = {
        'limit': limit,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (radius != null) 'radius': radius,
        if (status != null) 'status': status,
      };

      final response = await _dio.get(
        '/api/v1/community/photos',
        queryParameters: queryParameters,
      );

      return (response.data as List)
          .map((json) => PhotoData.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<CommunityPhotoMap> getCommunityMap({
    required double centerLatitude,
    required double centerLongitude,
    double radius = 5.0, // km
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/community/map',
        queryParameters: {
          'latitude': centerLatitude,
          'longitude': centerLongitude,
          'radius': radius,
        },
      );

      return CommunityPhotoMap.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  // Gamification
  Future<GamificationData> getUserGamificationData(String userId) async {
    try {
      final response = await _dio.get(
        '/api/v1/gamification/user/$userId',
      );

      return GamificationData.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<void> updateUserPoints(String userId, int points, String action) async {
    try {
      await _dio.post(
        '/api/v1/gamification/points',
        data: {
          'user_id': userId,
          'points': points,
          'action': action,
        },
      );
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  // Alerts
  Future<void> subscribeToAlerts({
    required String userId,
    required List<String> alertTypes,
    double? threshold,
  }) async {
    try {
      await _dio.post(
        '/api/v1/alerts/subscribe',
        data: {
          'user_id': userId,
          'alert_types': alertTypes,
          if (threshold != null) 'threshold': threshold,
        },
      );
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getActiveAlerts(String userId) async {
    try {
      final response = await _dio.get(
        '/api/v1/alerts/active',
        queryParameters: {'user_id': userId},
      );

      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  // User Profile
  Future<UserProfile> getUserProfile(String userId) async {
    try {
      final response = await _dio.get('/api/v1/users/$userId');
      return UserProfile.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<UserProfile> updateUserProfile(UserProfile profile) async {
    try {
      final response = await _dio.put(
        '/api/v1/users/${profile.id}',
        data: profile.toJson(),
      );

      return UserProfile.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  // File Upload
  Future<String> uploadFile(File file, String fileType) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        'type': fileType,
      });

      final response = await _dio.post(
        '/api/v1/upload',
        data: formData,
      );

      return response.data['url'];
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  // Error Handling
  ApiException _handleApiError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('Connection timeout. Please try again.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'Unknown error';
        
        switch (statusCode) {
          case 400:
            return ApiException('Invalid request: $message');
          case 401:
            return ApiException('Authentication required. Please login again.');
          case 403:
            return ApiException('Access denied.');
          case 404:
            return ApiException('Resource not found.');
          case 422:
            return ApiException('Validation error: $message');
          case 429:
            return ApiException('Rate limit exceeded. Please try again later.');
          case 500:
            return ApiException('Server error. Please try again later.');
          default:
            return ApiException('Error $statusCode: $message');
        }
      case DioExceptionType.cancel:
        return ApiException('Request cancelled.');
      case DioExceptionType.connectionError:
        return ApiException('Network connection error. Please check your internet connection.');
      default:
        return ApiException('Unexpected error: ${error.message}');
    }
  }
}

class ApiException implements Exception {
  final String message;
  
  ApiException(this.message);
  
  @override
  String toString() => 'ApiException: $message';
}