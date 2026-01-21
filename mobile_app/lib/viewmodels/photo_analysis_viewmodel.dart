import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/services/photo_analysis_service.dart';
import '../core/services/smart_notification_service.dart';
import '../core/services/notification_service.dart';

/// ViewModel for managing photo analysis functionality
class PhotoAnalysisViewModel extends ChangeNotifier {
  final PhotoAnalysisService _analysisService = PhotoAnalysisService();
  final SmartNotificationService _smartService = SmartNotificationService();
  final NotificationService _notificationService = NotificationService();
  
  // Analysis state
  PhotoAnalysisState _state = PhotoAnalysisState.initial;
  PhotoAnalysisResult? _currentResult;
  String? _error;
  bool _isAnalyzing = false;
  
  // Camera state
  List<CameraDescription>? _cameras;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  CameraLensDirection _selectedCameraDirection = CameraLensDirection.back;
  
  // Gallery state
  List<File>? _galleryImages;
  bool _isLoadingGallery = false;
  
  // History state
  List<PhotoAnalysisResult> _analysisHistory = [];
  bool _isLoadingHistory = false;

  // Getters
  PhotoAnalysisState get state => _state;
  PhotoAnalysisResult? get currentResult => _currentResult;
  String? get error => _error;
  bool get isAnalyzing => _isAnalyzing;
  
  CameraController? get cameraController => _cameraController;
  bool get isCameraInitialized => _isCameraInitialized;
  bool get isFlashOn => _isFlashOn;
  CameraLensDirection get selectedCameraDirection => _selectedCameraDirection;
  
  List<File>? get galleryImages => _galleryImages;
  bool get isLoadingGallery => _isLoadingGallery;
  
  List<PhotoAnalysisResult> get analysisHistory => _analysisHistory;
  bool get isLoadingHistory => _isLoadingHistory;
  
  /// Initialize the photo analysis service
  Future<void> initialize() async {
    _state = PhotoAnalysisState.loading;
    notifyListeners();
    
    try {
      // Initialize photo analysis service
      await _analysisService.initialize();
      
      // Load analysis history
      await loadAnalysisHistory();
      
      _state = PhotoAnalysisState.ready;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize photo analysis: $e';
      _state = PhotoAnalysisState.error;
      notifyListeners();
    }
  }
  
  /// Initialize camera
  Future<bool> initializeCamera() async {
    try {
      // Request camera permission
      final cameraPermission = await Permission.camera.request();
      if (cameraPermission != PermissionStatus.granted) {
        _error = 'Camera permission denied';
        notifyListeners();
        return false;
      }
      
      // Get available cameras
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        _error = 'No cameras available';
        notifyListeners();
        return false;
      }
      
      // Initialize camera controller
      final camera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == _selectedCameraDirection,
        orElse: () => _cameras!.first,
      );
      
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      
      _isCameraInitialized = true;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = 'Failed to initialize camera: $e';
      notifyListeners();
      return false;
    }
  }
  
  /// Take a photo and analyze it
  Future<void> takePhotoAndAnalyze() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _error = 'Camera not initialized';
      notifyListeners();
      return;
    }
    
    try {
      _state = PhotoAnalysisState.analyzing;
      _isAnalyzing = true;
      notifyListeners();
      
      // Capture image
      final image = await _cameraController!.takePicture();
      
      // Analyze the photo
      final result = await _analysisService.analyzePhoto(File(image.path));
      
      _currentResult = result;
      _state = PhotoAnalysisState.result;
      _isAnalyzing = false;
      
      // Save result to history
      await _analysisService.saveAnalysisResult(result);
      await loadAnalysisHistory();
      
      // Send notification if configured
      await _sendAnalysisCompleteNotification(result);
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to analyze photo: $e';
      _state = PhotoAnalysisState.error;
      _isAnalyzing = false;
      notifyListeners();
    }
  }
  
  /// Analyze image from gallery
  Future<void> analyzeGalleryImage(File imageFile) async {
    _state = PhotoAnalysisState.analyzing;
    _isAnalyzing = true;
    notifyListeners();
    
    try {
      final result = await _analysisService.analyzePhoto(imageFile);
      
      _currentResult = result;
      _state = PhotoAnalysisState.result;
      _isAnalyzing = false;
      
      // Save result to history
      await _analysisService.saveAnalysisResult(result);
      await loadAnalysisHistory();
      
      // Send notification if configured
      await _sendAnalysisCompleteNotification(result);
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to analyze image: $e';
      _state = PhotoAnalysisState.error;
      _isAnalyzing = false;
      notifyListeners();
    }
  }
  
  /// Load images from gallery
  Future<void> loadGalleryImages() async {
    _isLoadingGallery = true;
    notifyListeners();
    
    try {
      // Request storage permission
      final storagePermission = await Permission.storage.request();
      if (storagePermission != PermissionStatus.granted) {
        _error = 'Storage permission denied';
        _isLoadingGallery = false;
        notifyListeners();
        return;
      }
      
      // This is a simplified implementation
      // In a real app, you'd use the image_picker package to select images
      _galleryImages = []; // Placeholder
      _isLoadingGallery = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load gallery images: $e';
      _isLoadingGallery = false;
      notifyListeners();
    }
  }
  
  /// Load analysis history
  Future<void> loadAnalysisHistory() async {
    _isLoadingHistory = true;
    notifyListeners();
    
    try {
      _analysisHistory = await _analysisService.getAnalysisHistory();
    } catch (e) {
      _error = 'Failed to load analysis history: $e';
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }
  
  /// Toggle camera flash
  Future<void> toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    try {
      _isFlashOn = !_isFlashOn;
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      notifyListeners();
    } catch (e) {
      _error = 'Failed to toggle flash: $e';
      notifyListeners();
    }
  }
  
  /// Switch camera direction
  Future<void> switchCameraDirection() async {
    _selectedCameraDirection = _selectedCameraDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    
    // Reinitialize camera with new direction
    await _cameraController?.dispose();
    await initializeCamera();
  }
  
  /// Start real-time analysis from camera stream
  Stream<PhotoAnalysisResult>? get realTimeAnalysisStream {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return null;
    }
    
    // This would typically use the camera controller's image stream
    // and process each frame for real-time analysis
    return null; // Placeholder for real implementation
  }
  
  /// Clear current result
  void clearResult() {
    _currentResult = null;
    _state = PhotoAnalysisState.ready;
    notifyListeners();
  }
  
  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// Share analysis result
  Future<void> shareResult(PhotoAnalysisResult result) async {
    // This would integrate with share_plus or similar package
    // For now, we'll just prepare the share data
    final shareText = '''
AIRSHIELD Photo Analysis Result

Location: ${result.imagePath.isNotEmpty ? 'Camera Photo' : 'Real-time Analysis'}
Estimated AQI: ${result.estimatedAQI}
Estimated PM2.5: ${result.estimatedPM25.round()} μg/m³
Confidence: ${(result.confidence * 100).round()}%
Quality Level: ${result.qualityLevel}

Analysis time: ${result.analysisTime}ms

Generated by AIRSHIELD - Your Personal Pollution Defense System
    '''.trim();
    
    // In a real implementation, you'd call the sharing functionality here
    print('Share text: $shareText');
  }
  
  /// Delete analysis result from history
  Future<void> deleteAnalysisResult(String resultId) async {
    try {
      _analysisHistory.removeWhere((result) => result.id == resultId);
      notifyListeners();
      
      // Also delete the saved file
      // This would require tracking file paths for each result
    } catch (e) {
      _error = 'Failed to delete result: $e';
      notifyListeners();
    }
  }
  
  /// Send notification when analysis is complete
  Future<void> _sendAnalysisCompleteNotification(PhotoAnalysisResult result) async {
    try {
      // Check if we should send a notification
      final filter = await _smartService.shouldShowNotification(
        severity: NotificationSeverity.low,
        context: NotificationContext.community,
        title: 'Photo Analysis Complete',
        message: 'Analysis shows ${result.qualityLevel} air quality',
      );
      
      if (filter.shouldShow) {
        await _notificationService.showPhotoAnalysisComplete(
          photoTitle: 'Camera Photo',
          estimatedPM25: result.estimatedPM25,
          confidence: result.confidence,
        );
      }
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }
  
  /// Get confidence level description
  String getConfidenceDescription(double confidence) {
    if (confidence >= 0.8) return 'Very High';
    if (confidence >= 0.6) return 'High';
    if (confidence >= 0.4) return 'Medium';
    if (confidence >= 0.2) return 'Low';
    return 'Very Low';
  }
  
  /// Get air quality color based on AQI
  String getAirQualityColor(int aqi) {
    if (aqi >= 300) return '#8b0000'; // Hazardous - Dark red
    if (aqi >= 200) return '#800080'; // Very Unhealthy - Purple
    if (aqi >= 150) return '#ff0000'; // Unhealthy - Red
    if (aqi >= 100) return '#ffa500'; // Unhealthy for Sensitive Groups - Orange
    if (aqi >= 50) return '#ffff00'; // Moderate - Yellow
    return '#00ff00'; // Good - Green
  }
  
  /// Get visual indicator descriptions
  Map<String, String> getVisualIndicatorDescriptions() {
    return {
      'sky_haze': 'Haze in the sky area',
      'contrast_reduction': 'Visibility reduction due to pollution',
      'color_distortion': 'Color changes indicating pollution',
      'particle_density': 'Atmospheric particle concentration',
    };
  }
  
  /// Clean up resources
  @override
  void dispose() {
    _cameraController?.dispose();
    _analysisService.dispose();
    super.dispose();
  }
}

/// States for photo analysis
enum PhotoAnalysisState {
  initial,
  loading,
  ready,
  analyzing,
  result,
  error,
}

/// User activity for photo analysis context
enum PhotoAnalysisContext {
  outdoorSurvey,    // Surveying outdoor air quality
  indoorAssessment, // Assessing indoor air quality
  travelDocumentation, // Documenting air quality while traveling
  communityReporting, // Contributing to community data
  emergencyMonitoring, // Monitoring air quality during emergencies
  healthTracking,   // Tracking personal health exposure
}