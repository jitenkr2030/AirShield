part of 'capture_bloc.dart';

abstract class CaptureState extends Equatable {
  const CaptureState();

  @override
  List<Object> get props => [];
}

class CaptureInitial extends CaptureState {}

class CaptureLoading extends CaptureState {}

class CaptureReady extends CaptureState {
  final List<CameraDescription> cameras;
  final CameraDescription? currentCamera;
  final String? photoFilter;
  final Map<String, dynamic> settings;
  final bool isProcessing;
  final String? error;
  final ImageAnalysisResult? lastAnalysis;
  
  const CaptureReady({
    required this.cameras,
    this.currentCamera,
    this.photoFilter,
    this.settings = const {
      'auto_analyze': true,
      'upload_immediately': false,
      'privacy_level': 'medium',
      'quality': 'high',
    },
    this.isProcessing = false,
    this.error,
    this.lastAnalysis,
  });
  
  @override
  List<Object> get props => [
    cameras,
    currentCamera ?? '',
    photoFilter ?? '',
    settings,
    isProcessing,
    error ?? '',
    lastAnalysis ?? '',
  ];
  
  CaptureReady copyWith({
    List<CameraDescription>? cameras,
    CameraDescription? currentCamera,
    String? photoFilter,
    Map<String, dynamic>? settings,
    bool? isProcessing,
    String? error,
    ImageAnalysisResult? lastAnalysis,
  }) {
    return CaptureReady(
      cameras: cameras ?? this.cameras,
      currentCamera: currentCamera ?? this.currentCamera,
      photoFilter: photoFilter ?? this.photoFilter,
      settings: settings ?? this.settings,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      lastAnalysis: lastAnalysis ?? this.lastAnalysis,
    );
  }
}

class CapturePhotoTaken extends CaptureState {
  final String imagePath;
  final PhotoAnalysis analysis;
  final bool isProcessing;
  
  const CapturePhotoTaken({
    required this.imagePath,
    required this.analysis,
    this.isProcessing = false,
  });
  
  @override
  List<Object> get props => [imagePath, analysis, isProcessing];
}

class CaptureAnalyzing extends CaptureState {
  final String imagePath;
  
  const CaptureAnalyzing({required this.imagePath});
  
  @override
  List<Object> get props => [imagePath];
}

class CaptureAnalysisComplete extends CaptureState {
  final String imagePath;
  final PhotoAnalysis analysis;
  
  const CaptureAnalysisComplete({
    required this.imagePath,
    required this.analysis,
  });
  
  @override
  List<Object> get props => [imagePath, analysis];
}

class CaptureSubmitting extends CaptureState {
  final PhotoData photo;
  
  const CaptureSubmitting({required this.photo});
  
  @override
  List<Object> get props => [photo];
}

class CapturePhotoSubmitted extends CaptureState {
  final PhotoData photo;
  final int points;
  final DateTime submittedAt;
  
  const CapturePhotoSubmitted({
    required this.photo,
    required this.points,
    required this.submittedAt,
  });
  
  @override
  List<Object> get props => [photo, points, submittedAt];
}

class CaptureUserPhotosLoaded extends CaptureState {
  final List<PhotoData> photos;
  final bool hasMore;
  
  const CaptureUserPhotosLoaded({
    required this.photos,
    this.hasMore = false,
  });
  
  @override
  List<Object> get props => [photos, hasMore];
}

class CaptureCommunityPhotosLoaded extends CaptureState {
  final List<PhotoData> photos;
  final bool hasMore;
  final String? error;
  
  const CaptureCommunityPhotosLoaded({
    required this.photos,
    this.hasMore = false,
    this.error,
  });
  
  @override
  List<Object> get props => [photos, hasMore, error ?? ''];
}

class CaptureUploadProgress extends CaptureState {
  final String photoId;
  final double progress;
  final String status;
  
  const CaptureUploadProgress({
    required this.photoId,
    required this.progress,
    this.status = 'uploading',
  });
  
  @override
  List<Object> get props => [photoId, progress, status];
}

class CaptureError extends CaptureState {
  final String message;
  final String? details;
  
  const CaptureError(this.message, {this.details});
  
  @override
  List<Object> get props => [message, details ?? ''];
}

class CameraPermissionDenied extends CaptureState {
  final List<String> permissions;
  final String message;
  
  const CameraPermissionDenied({
    required this.permissions,
    required this.message,
  });
  
  @override
  List<Object> get props => [permissions, message];
}

class CameraNotAvailable extends CaptureState {
  final String reason;
  
  const CameraNotAvailable(this.reason);
  
  @override
  List<Object> get props => [reason];
}

class PhotoAnalysisFailed extends CaptureState {
  final String imagePath;
  final String error;
  final String reason;
  
  const PhotoAnalysisFailed({
    required this.imagePath,
    required this.error,
    this.reason = 'analysis_failed',
  });
  
  @override
  List<Object> get props => [imagePath, error, reason];
}

class PhotoSubmissionFailed extends CaptureState {
  final PhotoData photo;
  final String error;
  
  const PhotoSubmissionFailed({
    required this.photo,
    required this.error,
  });
  
  @override
  List<Object> get props => [photo, error];
}

class CaptureNoData extends CaptureState {
  final String reason;
  
  const CaptureNoData(this.reason);
  
  @override
  List<Object> get props => [reason];
}