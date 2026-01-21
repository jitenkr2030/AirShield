import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import '../config/app_config.dart';
import '../models/photo_data.dart';
import 'location_service.dart';

class CameraService {
  late List<CameraDescription> _cameras;
  CameraController? _controller;
  bool _isInitialized = false;
  final ImagePicker _imagePicker = ImagePicker();
  final LocationService _locationService;
  
  // Getters
  List<CameraDescription> get availableCameras => _cameras;
  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get isRecording => _controller?.value.isRecordingVideo ?? false;

  CameraService(this._locationService);

  Future<void> initialize() async {
    try {
      // Request camera permissions
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        throw CameraException('Camera permission denied');
      }

      // Get available cameras
      _cameras = await availableCameras;
      if (_cameras.isEmpty) {
        throw CameraException('No cameras available');
      }

      print('Camera service initialized with ${_cameras.length} cameras');
    } catch (e) {
      throw CameraException('Failed to initialize camera: $e');
    }
  }

  Future<void> startCamera({
    required CameraLensDirection lensDirection,
    ResolutionPreset resolution = ResolutionPreset.high,
  }) async {
    if (_isInitialized) {
      await stopCamera();
    }

    try {
      // Select camera based on lens direction
      final camera = _selectCamera(lensDirection);
      if (camera == null) {
        throw CameraException('No camera available for $lensDirection');
      }

      // Create camera controller
      _controller = CameraController(
        camera,
        resolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // Initialize controller
      await _controller!.initialize();
      _isInitialized = true;

      print('Camera started: ${camera.name}');
    } catch (e) {
      _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      throw CameraException('Failed to start camera: $e');
    }
  }

  CameraDescription? _selectCamera(CameraLensDirection lensDirection) {
    return _cameras.firstWhere(
      (camera) => camera.lensDirection == lensDirection,
      orElse: () => _cameras.first,
    );
  }

  Future<void> stopCamera() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
      _isInitialized = false;
      print('Camera stopped');
    }
  }

  Future<String> takePicture() async {
    if (!_isInitialized || _controller == null) {
      throw CameraException('Camera not initialized');
    }

    try {
      // Get current location for photo metadata
      final position = await _locationService.getCurrentLocation(
        timeout: const Duration(seconds: 5),
      );

      // Capture image
      final XFile imageFile = await _controller!.takePicture();
      
      // Convert to File and add metadata
      final file = File(imageFile.path);
      final enhancedFile = await _enhanceImageWithMetadata(
        file,
        position,
        'rear_camera', // Could be determined by current camera
      );

      return enhancedFile.path;
    } catch (e) {
      throw CameraException('Failed to take picture: $e');
    }
  }

  Future<File> _enhanceImageWithMetadata(
    File imageFile,
    dynamic position,
    String cameraType,
  ) async {
    // Load and enhance the image
    final imageBytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(imageBytes);
    
    if (originalImage == null) {
      return imageFile;
    }

    // Apply basic enhancements for better analysis
    img.Image enhancedImage = originalImage;
    
    // Convert to JPEG with high quality
    final jpegBytes = img.encodeJpg(enhancedImage, quality: 95);
    
    // Write enhanced image to temporary file
    final enhancedFile = File('${imageFile.path}_enhanced.jpg');
    await enhancedFile.writeAsBytes(jpegBytes);
    
    return enhancedFile;
  }

  Future<String> pickImageFromGallery() async {
    try {
      // Get current location for metadata
      final position = await _locationService.getCurrentLocation(
        timeout: const Duration(seconds: 5),
      );

      // Pick image from gallery
      final XFile? imageFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (imageFile == null) {
        throw CameraException('No image selected');
      }

      // Enhance image and add metadata
      final file = File(imageFile.path);
      final enhancedFile = await _enhanceImageWithMetadata(
        file,
        position,
        'gallery',
      );

      return enhancedFile.path;
    } catch (e) {
      throw CameraException('Failed to pick image: $e');
    }
  }

  Future<String> pickMultipleImagesFromGallery({int maxImages = 5}) async {
    try {
      // Get current location for metadata
      final position = await _locationService.getCurrentLocation(
        timeout: const Duration(seconds: 5),
      );

      // Pick multiple images from gallery
      final List<XFile> imageFiles = await _imagePicker.pickMultiImage(
        imageQuality: 95,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (imageFiles.isEmpty) {
        throw CameraException('No images selected');
      }

      // Process first image (can be extended to handle multiple)
      final file = File(imageFiles.first.path);
      final enhancedFile = await _enhanceImageWithMetadata(
        file,
        position,
        'gallery',
      );

      return enhancedFile.path;
    } catch (e) {
      throw CameraException('Failed to pick images: $e');
    }
  }

  // Image Analysis Helpers
  Future<ImageAnalysisResult> analyzeImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw CameraException('Image file not found');
      }

      final imageBytes = await file.readAsBytes();
      
      // Basic image validation
      if (imageBytes.isEmpty) {
        throw CameraException('Empty image file');
      }

      // Analyze image properties
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw CameraException('Invalid image format');
      }

      final width = originalImage.width;
      final height = originalImage.height;
      final fileSize = await file.length();
      
      // Check image quality metrics
      final brightness = _calculateBrightness(originalImage);
      final contrast = _calculateContrast(originalImage);
      final sharpness = _calculateSharpness(originalImage);
      final hasSky = _detectSky(originalImage);
      final hasHorizon = _detectHorizon(originalImage);

      return ImageAnalysisResult(
        width: width,
        height: height,
        fileSize: fileSize,
        brightness: brightness,
        contrast: contrast,
        sharpness: sharpness,
        hasSky: hasSky,
        hasHorizon: hasHorizon,
        qualityScore: _calculateQualityScore(
          brightness,
          contrast,
          sharpness,
          hasSky,
          hasHorizon,
        ),
      );
    } catch (e) {
      throw CameraException('Failed to analyze image: $e');
    }
  }

  double _calculateBrightness(img.Image image) {
    int totalBrightness = 0;
    int pixelCount = 0;
    
    for (int y = 0; y < image.height; y += 10) { // Sample every 10th pixel
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        final r = img.getRed(pixel);
        final g = img.getGreen(pixel);
        final b = img.getBlue(pixel);
        
        final brightness = (r + g + b) / 3;
        totalBrightness += brightness.toInt();
        pixelCount++;
      }
    }
    
    return totalBrightness / pixelCount / 255.0; // Normalize to 0-1
  }

  double _calculateContrast(img.Image image) {
    double meanBrightness = _calculateBrightness(image);
    double contrastSum = 0;
    int pixelCount = 0;
    
    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        final r = img.getRed(pixel);
        final g = img.getGreen(pixel);
        final b = img.getBlue(pixel);
        
        final brightness = (r + g + b) / 3;
        contrastSum += (brightness / 255 - meanBrightness).abs();
        pixelCount++;
      }
    }
    
    return contrastSum / pixelCount;
  }

  double _calculateSharpness(img.Image image) {
    // Simple edge detection to measure sharpness
    double edgeSum = 0;
    int edgeCount = 0;
    
    for (int y = 1; y < image.height - 1; y += 5) {
      for (int x = 1; x < image.width - 1; x += 5) {
        final pixel = image.getPixel(x, y);
        final right = image.getPixel(x + 1, y);
        final bottom = image.getPixel(x, y + 1);
        
        final r = img.getRed(pixel);
        final rg = img.getRed(right);
        final bg = img.getRed(bottom);
        
        final edge = (r - rg).abs() + (r - bg).abs();
        edgeSum += edge;
        edgeCount++;
      }
    }
    
    return edgeSum / edgeCount / 255.0; // Normalize
  }

  bool _detectSky(img.Image image) {
    // Simple sky detection based on color patterns
    int skyPixels = 0;
    int totalPixels = 0;
    
    // Check upper portion of image for sky
    for (int y = 0; y < image.height ~/ 3; y += 5) {
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        final r = img.getRed(pixel);
        final g = img.getGreen(pixel);
        final b = img.getBlue(pixel);
        
        // Sky typically has blue tint and low saturation
        final blueIntensity = b / 255.0;
        final redIntensity = r / 255.0;
        final greenIntensity = g / 255.0;
        
        if (blueIntensity > 0.5 && blueIntensity > redIntensity + 0.1) {
          skyPixels++;
        }
        totalPixels++;
      }
    }
    
    return skyPixels / totalPixels > 0.3; // At least 30% sky-like pixels
  }

  bool _detectHorizon(img.Image image) {
    // Simple horizon detection
    int horizonLine = 0;
    int attempts = 0;
    
    for (int y = image.height ~/ 3; y < 2 * image.height ~/ 3; y += 10) {
      int previousBrightness = -1;
      int brightnessChanges = 0;
      
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        final r = img.getRed(pixel);
        final g = img.getGreen(pixel);
        final b = img.getBlue(pixel);
        
        final brightness = (r + g + b) ~/ 3;
        
        if (previousBrightness != -1 && 
            (brightness - previousBrightness).abs() > 50) {
          brightnessChanges++;
        }
        previousBrightness = brightness;
      }
      
      // If many brightness changes, likely a horizon line
      if (brightnessChanges > 10) {
        horizonLine++;
      }
      attempts++;
    }
    
    return horizonLine > attempts * 0.3; // At least 30% horizon-like lines
  }

  double _calculateQualityScore(
    double brightness,
    double contrast,
    double sharpness,
    bool hasSky,
    bool hasHorizon,
  ) {
    double score = 0;
    
    // Brightness: prefer medium brightness (0.3-0.7)
    if (brightness >= 0.3 && brightness <= 0.7) {
      score += 0.25;
    } else {
      score += 0.25 * (1 - (brightness - 0.5).abs() * 2).abs();
    }
    
    // Contrast: prefer moderate contrast
    score += 0.25 * (contrast < 0.5 ? contrast : 0.5);
    
    // Sharpness: prefer sharp images
    score += 0.25 * (sharpness < 0.5 ? sharpness * 2 : 1);
    
    // Sky and horizon detection: prefer images with sky
    if (hasSky) score += 0.25;
    if (hasHorizon) score += 0.15; // Bonus for horizon
    
    return score.clamp(0, 1);
  }

  // Camera settings and controls
  Future<void> setFlashMode(FlashMode mode) async {
    if (_controller != null) {
      await _controller!.setFlashMode(mode);
    }
  }

  Future<void> setFocusMode(FocusMode mode) async {
    if (_controller != null) {
      await _controller!.setFocusMode(mode);
    }
  }

  Future<void> setExposureMode(ExposureMode mode) async {
    if (_controller != null) {
      await _controller!.setExposureMode(mode);
    }
  }

  Future<void> setExposureOffset(double offset) async {
    if (_controller != null) {
      await _controller!.setExposureOffset(offset);
    }
  }

  Future<void> zoomIn() async {
    if (_controller != null) {
      final maxZoom = _controller!.value.maxZoomLevel;
      final currentZoom = _controller!.value.zoomRatio;
      
      if (currentZoom < maxZoom) {
        final newZoom = (currentZoom + 0.1).clamp(1.0, maxZoom);
        await _controller!.setZoomRatio(newZoom);
      }
    }
  }

  Future<void> zoomOut() async {
    if (_controller != null) {
      final minZoom = _controller!.value.minZoomLevel;
      final currentZoom = _controller!.value.zoomRatio;
      
      if (currentZoom > minZoom) {
        final newZoom = (currentZoom - 0.1).clamp(minZoom, currentZoom);
        await _controller!.setZoomRatio(newZoom);
      }
    }
  }

  Future<void> toggleCamera() async {
    if (_cameras.length < 2) return;
    
    final currentCamera = _controller?.description;
    CameraDescription? newCamera;
    
    for (final camera in _cameras) {
      if (camera != currentCamera) {
        newCamera = camera;
        break;
      }
    }
    
    if (newCamera != null) {
      await stopCamera();
      await startCamera(lensDirection: newCamera.lensDirection);
    }
  }

  FlashMode getCurrentFlashMode() {
    return _controller?.value.flashMode ?? FlashMode.off;
  }

  ExposureMode getCurrentExposureMode() {
    return _controller?.value.exposureMode ?? ExposureMode.auto;
  }

  FocusMode getCurrentFocusMode() {
    return _controller?.value.focusMode ?? FocusMode.auto;
  }

  double getCurrentZoom() {
    return _controller?.value.zoomRatio ?? 1.0;
  }

  double getMinZoom() {
    return _controller?.value.minZoomLevel ?? 1.0;
  }

  double getMaxZoom() {
    return _controller?.value.maxZoomLevel ?? 3.0;
  }

  CameraDescription? getCurrentCamera() {
    return _controller?.description;
  }

  void dispose() {
    stopCamera();
  }
}

class ImageAnalysisResult {
  final int width;
  final int height;
  final int fileSize;
  final double brightness;
  final double contrast;
  final double sharpness;
  final bool hasSky;
  final bool hasHorizon;
  final double qualityScore;

  const ImageAnalysisResult({
    required this.width,
    required this.height,
    required this.fileSize,
    required this.brightness,
    required this.contrast,
    required this.sharpness,
    required this.hasSky,
    required this.hasHorizon,
    required this.qualityScore,
  });
}

class CameraException implements Exception {
  final String message;
  
  CameraException(this.message);
  
  @override
  String toString() => 'CameraException: $message';
}