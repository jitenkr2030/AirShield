import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/air_quality_data.dart';

/// Photo-based AQI estimation service
/// Uses computer vision to analyze photos for air quality indicators
class PhotoAnalysisService {
  static final PhotoAnalysisService _instance = PhotoAnalysisService._internal();
  factory PhotoAnalysisService() => _instance;
  PhotoAnalysisService._internal();

  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isInitialized = false;

  // Analysis thresholds and confidence levels
  static const double _hazeDetectionThreshold = 0.6;
  static const double _smogDetectionThreshold = 0.7;
  static const double _dustDetectionThreshold = 0.8;
  static const double _highConfidenceThreshold = 0.8;
  static const double _mediumConfidenceThreshold = 0.6;

  // Visual indicators that correlate with poor air quality
  static const Map<String, double> _visualIndicators = {
    'haze_opacity': 0.8,
    'visibility_reduction': 0.7,
    'color_distortion': 0.6,
    'atmospheric_particles': 0.9,
    'sky_obscuration': 0.5,
  };

  /// Initialize the photo analysis service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load TensorFlow Lite model
      await _loadModel();
      
      // Load labels
      await _loadLabels();
      
      _isInitialized = true;
      print('Photo Analysis Service initialized successfully');
    } catch (e) {
      print('Failed to initialize Photo Analysis Service: $e');
      rethrow;
    }
  }

  /// Load TensorFlow Lite model for air quality detection
  Future<void> _loadModel() async {
    try {
      // Try to load custom air quality model first
      _interpreter = await Interpreter.fromAsset('assets/ml_models/air_quality_model.tflite');
    } catch (e) {
      // Fallback to a general image classification model
      print('Custom model not found, using fallback classification: $e');
      _interpreter = await Interpreter.fromAsset('assets/ml_models/image_classification.tflite');
    }
  }

  /// Load labels for the ML model
  Future<void> _loadLabels() async {
    try {
      final labelsData = await rootBundle.loadString('assets/labels/air_quality_labels.txt');
      _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();
    } catch (e) {
      // Fallback labels
      _labels = [
        'clear_sky',
        'hazy',
        'smoggy',
        'dusty',
        'foggy',
        'polluted',
        'clean_air',
        'moderate_pollution',
        'heavy_pollution'
      ];
      print('Using fallback labels: $e');
    }
  }

  /// Analyze photo for air quality indicators
  Future<PhotoAnalysisResult> analyzePhoto(File imageFile) async {
    if (!_isInitialized) {
      throw Exception('Photo Analysis Service not initialized');
    }

    final startTime = DateTime.now();

    try {
      // Preprocess image
      final processedImage = await _preprocessImage(imageFile);
      
      // Run ML inference
      final predictions = await _runInference(processedImage);
      
      // Analyze visual indicators
      final visualAnalysis = await _analyzeVisualIndicators(imageFile);
      
      // Calculate air quality estimate
      final estimate = _calculateAirQualityEstimate(predictions, visualAnalysis);
      
      // Generate confidence score
      final confidence = _calculateConfidence(predictions, visualAnalysis);
      
      final analysisTime = DateTime.now().difference(startTime).inMilliseconds;

      return PhotoAnalysisResult(
        id: const Uuid().v4(),
        imagePath: imageFile.path,
        estimatedPM25: estimate.pm25,
        estimatedAQI: estimate.aqi,
        confidence: confidence,
        analysisTime: analysisTime,
        visualIndicators: visualAnalysis,
        predictions: predictions,
        qualityLevel: _getQualityLevel(estimate.aqi),
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw PhotoAnalysisException('Failed to analyze photo: $e');
    }
  }

  /// Real-time analysis from camera stream
  Future<PhotoAnalysisResult?> analyzeCameraFrame(CameraImage image) async {
    if (!_isInitialized || _interpreter == null) return null;

    try {
      // Convert CameraImage to analyzable format
      final input = _convertCameraImage(image);
      
      // Run inference
      final output = List.filled(1, [0.0]);
      _interpreter!.run(input, output);
      
      // Get prediction
      final prediction = output[0][0];
      
      // If confidence is high enough, estimate AQI
      if (prediction > _mediumConfidenceThreshold) {
        final estimatedAQI = _predictionToAQI(prediction);
        final estimatedPM25 = _estimatePM25FromAQI(estimatedAQI);
        
        return PhotoAnalysisResult(
          id: const Uuid().v4(),
          imagePath: '',
          estimatedPM25: estimatedPM25,
          estimatedAQI: estimatedAQI,
          confidence: prediction,
          analysisTime: 0,
          visualIndicators: {},
          predictions: {'prediction': prediction},
          qualityLevel: _getQualityLevel(estimatedAQI),
          timestamp: DateTime.now(),
        );
      }
      
      return null;
    } catch (e) {
      print('Real-time analysis error: $e');
      return null;
    }
  }

  /// Preprocess image for ML inference
  Future<List<List<List<List<double>>>>> _preprocessImage(File imageFile) async {
    // Read and resize image
    final imageBytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(imageBytes);
    
    if (originalImage == null) {
      throw Exception('Could not decode image');
    }

    // Resize to model input size (224x224)
    final resizedImage = img.copyResize(originalImage, width: 224, height: 224);
    
    // Convert to float32 array
    final input = List.generate(
      1,
      (i) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) {
            final pixel = resizedImage.getPixel(x, y);
            final r = img.getRed(pixel) / 255.0;
            final g = img.getGreen(pixel) / 255.0;
            final b = img.getBlue(pixel) / 255.0;
            return [r, g, b];
          },
        ),
      ),
    );

    return input;
  }

  /// Run ML inference on preprocessed image
  Future<Map<String, double>> _runInference(List<List<List<List<double>>>> input) async {
    final output = List.filled(1, [0.0, 0.0, 0.0, 0.0, 0.0]);
    _interpreter!.run(input, output);

    final Map<String, double> predictions = {};
    
    if (_labels != null && _labels!.length >= output[0].length) {
      for (int i = 0; i < output[0].length; i++) {
        predictions[_labels![i]] = output[0][i];
      }
    } else {
      // Fallback to generic predictions
      predictions.addAll({
        'clear_air': output[0][0],
        'haze': output[0][1],
        'smog': output[0][2],
        'dust': output[0][3],
        'pollution': output[0][4],
      });
    }

    return predictions;
  }

  /// Analyze visual indicators in the image
  Future<Map<String, double>> _analyzeVisualIndicators(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(imageBytes);
    
    if (originalImage == null) {
      return {};
    }

    final analysis = <String, double>{};

    // Analyze sky region for haze
    analysis['sky_haze'] = _analyzeSkyHaze(originalImage);
    
    // Analyze contrast for visibility reduction
    analysis['contrast_reduction'] = _analyzeContrast(originalImage);
    
    // Analyze color saturation for pollution indicators
    analysis['color_distortion'] = _analyzeColorDistortion(originalImage);
    
    // Analyze atmospheric particles
    analysis['particle_density'] = _analyzeParticleDensity(originalImage);

    return analysis;
  }

  /// Analyze sky region for haze indicators
  double _analyzeSkyHaze(img.Image image) {
    int skyPixelCount = 0;
    int hazyPixelCount = 0;
    
    // Assume upper portion of image contains sky
    final skyRegion = img.Rectangle(0, 0, image.width, (image.height * 0.4).round());
    
    for (int y = skyRegion.y; y < skyRegion.y + skyRegion.height && y < image.height; y++) {
      for (int x = skyRegion.x; x < skyRegion.x + skyRegion.width && x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = img.getRed(pixel);
        final g = img.getGreen(pixel);
        final b = img.getBlue(pixel);
        
        skyPixelCount++;
        
        // Check for hazy appearance (low contrast, grayish tones)
        final brightness = (r + g + b) / 3;
        final saturation = _calculateSaturation(r, g, b);
        
        if (brightness > 100 && brightness < 200 && saturation < 30) {
          hazyPixelCount++;
        }
      }
    }
    
    return skyPixelCount > 0 ? hazyPixelCount / skyPixelCount : 0.0;
  }

  /// Analyze overall contrast for visibility reduction
  double _analyzeContrast(img.Image image) {
    int pixelCount = 0;
    int lowContrastPixels = 0;
    
    for (int y = 0; y < image.height; y += 4) { // Sample every 4th pixel for performance
      for (int x = 0; x < image.width; x += 4) {
        final pixel = image.getPixel(x, y);
        final r = img.getRed(pixel);
        final g = img.getGreen(pixel);
        final b = img.getBlue(pixel);
        
        pixelCount++;
        
        // Check for low contrast (similar RGB values indicate poor visibility)
        final maxVal = [r, g, b].reduce((a, b) => a > b ? a : b);
        final minVal = [r, g, b].reduce((a, b) => a < b ? a : b);
        final contrast = maxVal - minVal;
        
        if (contrast < 30) {
          lowContrastPixels++;
        }
      }
    }
    
    return pixelCount > 0 ? lowContrastPixels / pixelCount : 0.0;
  }

  /// Analyze color saturation for pollution indicators
  double _analyzeColorDistortion(img.Image image) {
    int pixelCount = 0;
    int distortedPixelCount = 0;
    
    for (int y = 0; y < image.height; y += 4) {
      for (int x = 0; x < image.width; x += 4) {
        final pixel = image.getPixel(x, y);
        final r = img.getRed(pixel);
        final g = img.getGreen(pixel);
        final b = img.getBlue(pixel);
        
        pixelCount++;
        
        // Check for grayish/brownish tones that indicate pollution
        final saturation = _calculateSaturation(r, g, b);
        final brightness = (r + g + b) / 3;
        
        if (saturation < 20 && brightness > 80) {
          distortedPixelCount++;
        }
      }
    }
    
    return pixelCount > 0 ? distortedPixelCount / pixelCount : 0.0;
  }

  /// Analyze particle density in the image
  double _analyzeParticleDensity(img.Image image) {
    // Simple edge detection to find particle-like structures
    int edgeCount = 0;
    int totalPixels = 0;
    
    for (int y = 1; y < image.height - 1; y += 2) {
      for (int x = 1; x < image.width - 1; x += 2) {
        final center = image.getPixel(x, y);
        final neighbors = [
          image.getPixel(x-1, y),
          image.getPixel(x+1, y),
          image.getPixel(x, y-1),
          image.getPixel(x, y+1),
        ];
        
        final centerBrightness = (img.getRed(center) + img.getGreen(center) + img.getBlue(center)) / 3;
        
        totalPixels++;
        
        // Count edges (significant brightness differences)
        for (final neighbor in neighbors) {
          final neighborBrightness = (img.getRed(neighbor) + img.getGreen(neighbor) + img.getBlue(neighbor)) / 3;
          if ((centerBrightness - neighborBrightness).abs() > 25) {
            edgeCount++;
            break;
          }
        }
      }
    }
    
    return totalPixels > 0 ? edgeCount / totalPixels : 0.0;
  }

  /// Calculate color saturation
  double _calculateSaturation(int r, int g, int b) {
    final max = [r, g, b].reduce((a, b) => a > b ? a : b);
    final min = [r, g, b].reduce((a, b) => a < b ? a : b);
    
    if (max == 0) return 0.0;
    
    return ((max - min) / max) * 100;
  }

  /// Convert CameraImage to input format
  List<List<List<List<double>>>> _convertCameraImage(CameraImage image) {
    // This is a simplified conversion - in practice, you'd need to handle
    // the specific format and dimensions of CameraImage
    final input = List.generate(
      1,
      (i) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) {
            // Placeholder conversion - real implementation needed
            final pixel = (x + y) % 255;
            return [pixel / 255.0, pixel / 255.0, pixel / 255.0];
          },
        ),
      ),
    );
    
    return input;
  }

  /// Calculate air quality estimate from ML predictions and visual analysis
  AirQualityEstimate _calculateAirQualityEstimate(
    Map<String, double> predictions,
    Map<String, double> visualAnalysis,
  ) {
    // Weight different indicators
    double hazeScore = (predictions['haze'] ?? 0) * 0.3 + (visualAnalysis['sky_haze'] ?? 0) * 0.2;
    double smogScore = (predictions['smog'] ?? 0) * 0.25 + (visualAnalysis['color_distortion'] ?? 0) * 0.15;
    double dustScore = (predictions['dust'] ?? 0) * 0.2 + (visualAnalysis['particle_density'] ?? 0) * 0.2;
    double visibilityScore = (visualAnalysis['contrast_reduction'] ?? 0) * 0.15;
    
    // Calculate composite pollution score
    final pollutionScore = (hazeScore + smogScore + dustScore + visibilityScore) / 4.0;
    
    // Map to AQI scale (0-500)
    final estimatedAQI = (pollutionScore * 400).clamp(0, 500);
    final estimatedPM25 = _estimatePM25FromAQI(estimatedAQI);
    
    return AirQualityEstimate(
      aqi: estimatedAQI.round(),
      pm25: estimatedPM25.round(),
      pollutionScore: pollutionScore,
    );
  }

  /// Calculate overall confidence score
  double _calculateConfidence(
    Map<String, double> predictions,
    Map<String, double> visualAnalysis,
  ) {
    // Get max prediction confidence
    final maxPrediction = predictions.values.isNotEmpty 
        ? predictions.values.reduce((a, b) => a > b ? a : b)
        : 0.0;
    
    // Get max visual analysis confidence
    final maxVisual = visualAnalysis.values.isNotEmpty
        ? visualAnalysis.values.reduce((a, b) => a > b ? a : b)
        : 0.0;
    
    // Combine and normalize confidence
    return ((maxPrediction + maxVisual) / 2).clamp(0.0, 1.0);
  }

  /// Convert ML prediction to AQI estimate
  double _predictionToAQI(double prediction) {
    return (prediction * 400).clamp(0, 500);
  }

  /// Estimate PM2.5 from AQI
  double _estimatePM25FromAQI(double aqi) {
    // Simplified PM2.5 estimation from AQI
    // This would need to be calibrated based on real data
    return (aqi / 20).clamp(0, 500);
  }

  /// Get air quality level description
  String _getQualityLevel(double aqi) {
    if (aqi >= 300) return 'Hazardous';
    if (aqi >= 200) return 'Very Unhealthy';
    if (aqi >= 150) return 'Unhealthy';
    if (aqi >= 100) return 'Unhealthy for Sensitive Groups';
    if (aqi >= 50) return 'Moderate';
    return 'Good';
  }

  /// Save analysis result to local storage
  Future<String> saveAnalysisResult(PhotoAnalysisResult result) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'analysis_${result.id}.json';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsString(result.toJson());
    return file.path;
  }

  /// Get analysis history
  Future<List<PhotoAnalysisResult>> getAnalysisHistory() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync().where((file) => 
        file.path.startsWith('${directory.path}/analysis_') && 
        file.path.endsWith('.json'));
    
    final results = <PhotoAnalysisResult>[];
    
    for (final file in files) {
      try {
        final content = await File(file.path).readAsString();
        final result = PhotoAnalysisResult.fromJsonString(content);
        results.add(result);
      } catch (e) {
        print('Error loading analysis result: $e');
      }
    }
    
    // Sort by timestamp (newest first)
    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return results;
  }

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}

/// Result of photo analysis
class PhotoAnalysisResult {
  final String id;
  final String imagePath;
  final double estimatedPM25;
  final int estimatedAQI;
  final double confidence;
  final int analysisTime; // milliseconds
  final Map<String, double> visualIndicators;
  final Map<String, double> predictions;
  final String qualityLevel;
  final DateTime timestamp;

  PhotoAnalysisResult({
    required this.id,
    required this.imagePath,
    required this.estimatedPM25,
    required this.estimatedAQI,
    required this.confidence,
    required this.analysisTime,
    required this.visualIndicators,
    required this.predictions,
    required this.qualityLevel,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'image_path': imagePath,
    'estimated_pm25': estimatedPM25,
    'estimated_aqi': estimatedAQI,
    'confidence': confidence,
    'analysis_time': analysisTime,
    'visual_indicators': visualIndicators,
    'predictions': predictions,
    'quality_level': qualityLevel,
    'timestamp': timestamp.toIso8601String(),
  };

  factory PhotoAnalysisResult.fromJsonString(String jsonString) {
    final data = Map<String, dynamic>.fromEntries(
      jsonString.split(', ').map((pair) {
        final parts = pair.split(': ');
        return MapEntry(parts[0].replaceAll('{', '').replaceAll('"', ''), 
                      parts[1].replaceAll('}', '').replaceAll('"', ''));
      })
    );
    
    return PhotoAnalysisResult(
      id: data['id'] ?? '',
      imagePath: data['image_path'] ?? '',
      estimatedPM25: double.tryParse(data['estimated_pm25'] ?? '0') ?? 0,
      estimatedAQI: int.tryParse(data['estimated_aqi'] ?? '0') ?? 0,
      confidence: double.tryParse(data['confidence'] ?? '0') ?? 0,
      analysisTime: int.tryParse(data['analysis_time'] ?? '0') ?? 0,
      visualIndicators: {},
      predictions: {},
      qualityLevel: data['quality_level'] ?? '',
      timestamp: DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Air quality estimate from photo analysis
class AirQualityEstimate {
  final int aqi;
  final double pm25;
  final double pollutionScore;

  AirQualityEstimate({
    required this.aqi,
    required this.pm25,
    required this.pollutionScore,
  });
}

/// Exception thrown during photo analysis
class PhotoAnalysisException implements Exception {
  final String message;
  
  PhotoAnalysisException(this.message);
  
  @override
  String toString() => 'PhotoAnalysisException: $message';
}