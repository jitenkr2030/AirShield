import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../config/app_config.dart';
import '../models/air_quality_data.dart';
import '../models/prediction_data.dart';
import '../models/photo_data.dart';

class MLService {
  Interpreter? _imageAnalysisModel;
  Interpreter? _predictionModel;
  Interpreter? _healthScoreModel;
  bool _isInitialized = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get hasImageModel => _imageAnalysisModel != null;
  bool get hasPredictionModel => _predictionModel != null;
  bool get hasHealthModel => _healthScoreModel != null;

  MLService();

  Future<void> initialize() async {
    try {
      await _loadImageAnalysisModel();
      await _loadPredictionModel();
      await _loadHealthScoreModel();
      _isInitialized = true;
      print('ML Service initialized successfully');
    } catch (e) {
      print('Error initializing ML service: $e');
      // Continue with partial initialization
      _isInitialized = true;
    }
  }

  Future<void> _loadImageAnalysisModel() async {
    try {
      final options = InterpreterOptions();
      _imageAnalysisModel = await Interpreter.fromAsset(
        AppConfig.imageAnalysisModelPath,
        options: options,
      );
      print('Image analysis model loaded');
    } catch (e) {
      print('Failed to load image analysis model: $e');
      _imageAnalysisModel = null;
    }
  }

  Future<void> _loadPredictionModel() async {
    try {
      final options = InterpreterOptions();
      _predictionModel = await Interpreter.fromAsset(
        AppConfig.predictionModelPath,
        options: options,
      );
      print('Prediction model loaded');
    } catch (e) {
      print('Failed to load prediction model: $e');
      _predictionModel = null;
    }
  }

  Future<void> _loadHealthScoreModel() async {
    try {
      final options = InterpreterOptions();
      _healthScoreModel = await Interpreter.fromAsset(
        AppConfig.healthScoreModelPath,
        options: options,
      );
      print('Health score model loaded');
    } catch (e) {
      print('Failed to load health score model: $e');
      _healthScoreModel = null;
    }
  }

  // Image Analysis (Photo to PM2.5 estimation)
  Future<PhotoAnalysis> analyzePollutionPhoto(String imagePath) async {
    if (_imageAnalysisModel == null) {
      // Fallback to rule-based estimation
      return await _fallbackImageAnalysis(imagePath);
    }

    try {
      final image = await _preprocessImage(imagePath);
      final analysis = await _runImageAnalysis(image);
      return analysis;
    } catch (e) {
      print('Error in image analysis: $e');
      return await _fallbackImageAnalysis(imagePath);
    }
  }

  Future<img.Image> _preprocessImage(String imagePath) async {
    final file = File(imagePath);
    final imageBytes = await file.readAsBytes();
    final image = img.decodeImage(imageBytes);
    
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize image to model input size (224x224 for many models)
    const targetSize = 224;
    final resizedImage = img.copyResize(
      image,
      width: targetSize,
      height: targetSize,
      interpolation: img.Interpolation.linear,
    );

    return resizedImage;
  }

  Future<PhotoAnalysis> _runImageAnalysis(img.Image image) async {
    final input = _imageToTensor(image);
    final output = List.filled(10, 0.0); // Adjust based on model output
    
    _imageAnalysisModel!.run(input, output);
    
    return _parseImageAnalysisOutput(output, image);
  }

  List<List<List<List<double>>>> _imageToTensor(img.Image image) {
    // Convert image to float tensor with shape [1, height, width, 3]
    final input = List.generate(1, (b) => 
      List.generate(image.height, (y) =>
        List.generate(image.width, (x) {
          final pixel = image.getPixel(x, y);
          final r = img.getRed(pixel) / 255.0;
          final g = img.getGreen(pixel) / 255.0;
          final b = img.getBlue(pixel) / 255.0;
          return [r, g, b];
        })
      )
    );
    return input;
  }

  PhotoAnalysis _parseImageAnalysisOutput(List<double> output, img.Image image) {
    // Parse model output to extract PM2.5 estimate and confidence
    // This is a simplified version - actual parsing depends on model architecture
    
    final estimatedPM25 = output[0]; // Model outputs PM2.5 value
    final confidence = output[1].clamp(0.0, 1.0); // Confidence score
    
    // Calculate additional metrics
    final visibilityScore = _calculateVisibilityScore(image);
    final hazeIntensity = _calculateHazeIntensity(image);
    final colorScattering = _calculateColorScattering(image);
    final sunAngle = _estimateSunAngle(image);
    
    // Analyze factors
    final factors = _analyzeImageFactors(
      visibilityScore,
      hazeIntensity,
      colorScattering,
      sunAngle,
    );
    
    final aqi = _calculateAQI(estimatedPM25);
    
    return PhotoAnalysis(
      analysisId: DateTime.now().millisecondsSinceEpoch.toString(),
      estimatedPM25: estimatedPM25,
      estimatedAQI: aqi,
      confidence: confidence,
      visibilityScore: visibilityScore,
      hazeIntensity: hazeIntensity,
      colorScattering: colorScattering,
      sunAngle: sunAngle,
      factors: factors,
      analyzedAt: DateTime.now(),
    );
  }

  double _calculateVisibilityScore(img.Image image) {
    // Calculate how clear the visibility is in the image
    int totalBrightness = 0;
    int pixelCount = 0;
    
    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        final r = img.getRed(pixel);
        final g = img.getGreen(pixel);
        final b = img.getBlue(pixel);
        
        final brightness = (r + g + b) / 3;
        totalBrightness += brightness;
        pixelCount++;
      }
    }
    
    final avgBrightness = totalBrightness / pixelCount;
    return (avgBrightness / 255.0).clamp(0.0, 1.0);
  }

  double _calculateHazeIntensity(img.Image image) {
    // Analyze color saturation to detect haze
    double totalSaturation = 0;
    int pixelCount = 0;
    
    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        final r = img.getRed(pixel);
        final g = img.getGreen(pixel);
        final b = img.getBlue(pixel);
        
        // Calculate saturation using RGB
        final max = [r, g, b].reduce((a, b) => a > b ? a : b);
        final min = [r, g, b].reduce((a, b) => a < b ? a : b);
        
        final saturation = max > 0 ? (max - min) / max : 0;
        totalSaturation += saturation;
        pixelCount++;
      }
    }
    
    return (1.0 - totalSaturation / pixelCount).clamp(0.0, 1.0);
  }

  double _calculateColorScattering(img.Image image) {
    // Analyze color distribution to detect atmospheric scattering
    final colorBins = <int>[0, 0, 0]; // RGB bins
    int totalPixels = 0;
    
    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        final r = img.getRed(pixel);
        final g = img.getGreen(pixel);
        final b = img.getBlue(pixel);
        
        // Find dominant color channel
        if (r >= g && r >= b) colorBins[0]++; // Red dominant
        else if (g >= r && g >= b) colorBins[1]++; // Green dominant
        else colorBins[2]++; // Blue dominant
        
        totalPixels++;
      }
    }
    
    // Calculate color balance (0 = balanced, 1 = very imbalanced)
    final maxBin = colorBins.reduce((a, b) => a > b ? a : b);
    final balance = maxBin / totalPixels;
    
    return (balance - 0.33).clamp(0.0, 1.0); // Normalize around 1/3
  }

  double _estimateSunAngle(img.Image image) {
    // Estimate sun angle based on image brightness distribution
    int topBrightness = 0;
    int bottomBrightness = 0;
    int pixelCount = 0;
    
    // Analyze top and bottom portions
    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        final r = img.getRed(pixel);
        final g = img.getGreen(pixel);
        final b = img.getBlue(pixel);
        
        final brightness = (r + g + b) / 3;
        
        if (y < image.height ~/ 2) {
          topBrightness += brightness;
        } else {
          bottomBrightness += brightness;
        }
        pixelCount++;
      }
    }
    
    final topAvg = topBrightness / (pixelCount ~/ 2);
    const bottomAvg = bottomBrightness / (pixelCount ~/ 2);
    
    // Estimate angle based on brightness gradient
    final gradient = (topAvg - bottomAvg) / 255.0;
    return gradient.clamp(-1.0, 1.0);
  }

  List<AnalysisFactor> _analyzeImageFactors(
    double visibility,
    double hazeIntensity,
    double colorScattering,
    double sunAngle,
  ) {
    final factors = <AnalysisFactor>[];
    
    // Visibility factor
    if (visibility < 0.5) {
      factors.add(AnalysisFactor(
        factor: 'low_visibility',
        name: 'Low Visibility',
        impact: (0.5 - visibility) * 2,
        description: 'Reduced visibility indicates poor air quality',
        weight: 0.3,
      ));
    }
    
    // Haze factor
    if (hazeIntensity > 0.5) {
      factors.add(AnalysisFactor(
        factor: 'high_haze',
        name: 'Atmospheric Haze',
        impact: hazeIntensity * 0.5,
        description: 'High haze intensity suggests pollution particles',
        weight: 0.25,
      ));
    }
    
    // Color scattering factor
    if (colorScattering > 0.3) {
      factors.add(AnalysisFactor(
        factor: 'color_imbalance',
        name: 'Color Imbalance',
        impact: colorScattering * 0.3,
        description: 'Unbalanced colors due to atmospheric scattering',
        weight: 0.2,
      ));
    }
    
    // Sun angle factor
    if (sunAngle > 0.5) {
      factors.add(AnalysisFactor(
        factor: 'sun_angle',
        name: 'Sun Position',
        impact: sunAngle * 0.2,
        description: 'Sun position affects light scattering',
        weight: 0.15,
      ));
    }
    
    return factors;
  }

  Future<PhotoAnalysis> _fallbackImageAnalysis(String imagePath) async {
    // Rule-based analysis when ML model is not available
    try {
      final file = File(imagePath);
      final imageBytes = await file.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      
      final visibilityScore = _calculateVisibilityScore(image);
      final hazeIntensity = _calculateHazeIntensity(image);
      final colorScattering = _calculateColorScattering(image);
      final sunAngle = _estimateSunAngle(image);
      
      // Estimate PM2.5 based on visual indicators
      double estimatedPM25 = 10.0; // Base value
      
      if (visibilityScore < 0.3) {
        estimatedPM25 += 50.0; // Very poor visibility
      } else if (visibilityScore < 0.5) {
        estimatedPM25 += 30.0; // Poor visibility
      } else if (visibilityScore < 0.7) {
        estimatedPM25 += 15.0; // Moderate visibility
      }
      
      if (hazeIntensity > 0.6) {
        estimatedPM25 += 25.0; // Very hazy
      } else if (hazeIntensity > 0.4) {
        estimatedPM25 += 15.0; // Hazy
      }
      
      final confidence = (1.0 - hazeIntensity) * 0.8 + visibilityScore * 0.2;
      final aqi = _calculateAQI(estimatedPM25);
      
      return PhotoAnalysis(
        analysisId: DateTime.now().millisecondsSinceEpoch.toString(),
        estimatedPM25: estimatedPM25,
        estimatedAQI: aqi,
        confidence: confidence,
        visibilityScore: visibilityScore,
        hazeIntensity: hazeIntensity,
        colorScattering: colorScattering,
        sunAngle: sunAngle,
        factors: [],
        analyzedAt: DateTime.now(),
      );
    } catch (e) {
      // Return default analysis
      return PhotoAnalysis(
        analysisId: DateTime.now().millisecondsSinceEpoch.toString(),
        estimatedPM25: 25.0,
        estimatedAQI: 50.0,
        confidence: 0.5,
        visibilityScore: 0.5,
        hazeIntensity: 0.5,
        colorScattering: 0.5,
        sunAngle: 0.0,
        factors: [],
        analyzedAt: DateTime.now(),
      );
    }
  }

  // Pollution Prediction
  Future<double> predictPollution({
    required double latitude,
    required double longitude,
    required Map<String, dynamic> weatherData,
    List<AirQualityData>? historicalData,
    Map<String, dynamic>? satelliteData,
  }) async {
    if (_predictionModel == null) {
      // Fallback to statistical prediction
      return await _fallbackPrediction(weatherData, historicalData);
    }

    try {
      final input = _preparePredictionInput(
        latitude,
        longitude,
        weatherData,
        historicalData,
        satelliteData,
      );
      
      final output = List.filled(1, 0.0); // PM2.5 prediction
      _predictionModel!.run(input, output);
      
      return output[0].clamp(0.0, 500.0); // PM2.5 range
    } catch (e) {
      print('Error in pollution prediction: $e');
      return await _fallbackPrediction(weatherData, historicalData);
    }
  }

  List<List<double>> _preparePredictionInput(
    double latitude,
    double longitude,
    Map<String, dynamic> weatherData,
    List<AirQualityData>? historicalData,
    Map<String, dynamic>? satelliteData,
  ) {
    // Prepare input tensor for prediction model
    final input = <double>[
      latitude,           // 0
      longitude,          // 1
      weatherData['temperature'] ?? 0.0,      // 2
      weatherData['humidity'] ?? 0.0,         // 3
      weatherData['wind_speed'] ?? 0.0,       // 4
      weatherData['wind_direction'] ?? 0.0,   // 5
      weatherData['pressure'] ?? 0.0,         // 6
      weatherData['visibility'] ?? 0.0,       // 7
      satelliteData?['aod'] ?? 0.0,          // 8
      historicalData?.isNotEmpty == true ? 
        historicalData!.last.pm25 : 25.0,     // 9 - Historical PM2.5
    ];
    
    return [input];
  }

  Future<double> _fallbackPrediction(
    Map<String, dynamic> weatherData,
    List<AirQualityData>? historicalData,
  ) async {
    // Simple rule-based prediction
    double basePM25 = 25.0; // Default
    
    final humidity = weatherData['humidity'] ?? 50.0;
    final windSpeed = weatherData['wind_speed'] ?? 5.0;
    final temperature = weatherData['temperature'] ?? 20.0;
    
    // Adjust based on weather conditions
    if (humidity > 70) basePM25 += 10.0; // High humidity traps particles
    if (windSpeed < 2.0) basePM25 += 15.0; // Low wind = more pollution
    if (temperature < 10) basePM25 += 5.0; // Cold weather = more pollution
    if (temperature > 30) basePM25 += 8.0; // Hot weather = more pollution
    
    // Use historical average if available
    if (historicalData != null && historicalData.isNotEmpty) {
      final avgHistorical = historicalData
          .take(24) // Last 24 hours
          .map((e) => e.pm25)
          .reduce((a, b) => a + b) / historicalData.length;
      
      basePM25 = (basePM25 + avgHistorical) / 2; // Average with rule-based
    }
    
    return basePM25.clamp(0.0, 300.0);
  }

  // Health Score Calculation
  Future<double> calculateHealthScore({
    required List<AirQualityData> exposureHistory,
    required Map<String, dynamic> userProfile,
    List<double>? heartRateData,
    int? age,
    List<String>? healthConditions,
  }) async {
    if (_healthScoreModel == null) {
      return await _fallbackHealthScore(exposureHistory, userProfile, age, healthConditions);
    }

    try {
      final input = _prepareHealthScoreInput(
        exposureHistory,
        userProfile,
        heartRateData,
        age,
        healthConditions,
      );
      
      final output = List.filled(1, 0.0); // Health score 0-100
      _healthScoreModel!.run(input, output);
      
      return output[0].clamp(0.0, 100.0);
    } catch (e) {
      print('Error in health score calculation: $e');
      return await _fallbackHealthScore(exposureHistory, userProfile, age, healthConditions);
    }
  }

  List<List<double>> _prepareHealthScoreInput(
    List<AirQualityData> exposureHistory,
    Map<String, dynamic> userProfile,
    List<double>? heartRateData,
    int? age,
    List<String>? healthConditions,
  ) {
    final avgExposure = exposureHistory.isNotEmpty ?
      exposureHistory.map((e) => e.aqi).reduce((a, b) => a + b) / exposureHistory.length : 50.0;
    
    final maxExposure = exposureHistory.isNotEmpty ?
      exposureHistory.map((e) => e.aqi).reduce((a, b) => a > b ? a : b) : 50.0;
    
    final totalExposureTime = exposureHistory.length * 0.5; // Assume 30 min intervals
    final avgHeartRate = heartRateData?.isNotEmpty == true ?
      heartRateData!.reduce((a, b) => a + b) / heartRateData.length : 75.0;
    
    final input = <double>[
      avgExposure,          // 0 - Average AQI exposure
      maxExposure,          // 1 - Maximum AQI exposure
      totalExposureTime,    // 2 - Total exposure time
      avgHeartRate,         // 3 - Average heart rate
      age?.toDouble() ?? 30.0, // 4 - Age
      (healthConditions?.length ?? 0).toDouble(), // 5 - Health conditions count
      userProfile['activity_level_score'] ?? 3.0, // 6 - Activity level
    ];
    
    return [input];
  }

  Future<double> _fallbackHealthScore(
    List<AirQualityData> exposureHistory,
    Map<String, dynamic> userProfile,
    int? age,
    List<String>? healthConditions,
  ) async {
    if (exposureHistory.isEmpty) return 85.0; // Default good score
    
    final avgAQI = exposureHistory.map((e) => e.aqi).reduce((a, b) => a + b) / exposureHistory.length;
    final maxAQI = exposureHistory.map((e) => e.aqi).reduce((a, b) => a > b ? a : b);
    
    // Base score starts at 100
    double score = 100.0;
    
    // Deduct points based on average exposure
    if (avgAQI > 50) score -= (avgAQI - 50) * 0.5;
    if (avgAQI > 100) score -= (avgAQI - 100) * 0.8;
    if (avgAQI > 150) score -= (avgAQI - 150) * 1.2;
    
    // Deduct points for high exposure events
    if (maxAQI > 200) score -= 20.0;
    if (maxAQI > 300) score -= 30.0;
    
    // Age adjustment
    if (age != null) {
      if (age < 18 || age > 65) score -= 5.0; // More vulnerable ages
      if (age > 75) score -= 10.0;
    }
    
    // Health conditions adjustment
    if (healthConditions != null) {
      final respiratoryConditions = healthConditions.where((condition) => 
        condition.toLowerCase().contains('respiratory') ||
        condition.toLowerCase().contains('asthma') ||
        condition.toLowerCase().contains('copd')
      ).length;
      
      final cardiovascularConditions = healthConditions.where((condition) => 
        condition.toLowerCase().contains('heart') ||
        condition.toLowerCase().contains('cardiovascular') ||
        condition.toLowerCase().contains('hypertension')
      ).length;
      
      score -= respiratoryConditions * 10.0;
      score -= cardiovascularConditions * 5.0;
    }
    
    return score.clamp(0.0, 100.0);
  }

  double _calculateAQI(double pm25) {
    // Simplified AQI calculation for PM2.5
    if (pm25 <= 12.0) return (pm25 / 12.0) * 50;
    if (pm25 <= 35.4) return 50 + ((pm25 - 12.0) / (35.4 - 12.0)) * 50;
    if (pm25 <= 55.4) return 100 + ((pm25 - 35.4) / (55.4 - 35.4)) * 50;
    if (pm25 <= 150.4) return 150 + ((pm25 - 55.4) / (150.4 - 55.4)) * 50;
    if (pm25 <= 250.4) return 200 + ((pm25 - 150.4) / (250.4 - 150.4)) * 100;
    return 300 + ((pm25 - 250.4) / (500.0 - 250.4)) * 200;
  }

  void dispose() {
    _imageAnalysisModel?.close();
    _predictionModel?.close();
    _healthScoreModel?.close();
    _isInitialized = false;
  }
}