part of 'capture_bloc.dart';

abstract class CaptureEvent extends Equatable {
  const CaptureEvent();

  @override
  List<Object> get props => [];
}

class InitializeCamera extends CaptureEvent {
  final bool requestPermissions;
  
  const InitializeCamera({
    this.requestPermissions = true,
  });
  
  @override
  List<Object> get props => [requestPermissions];
}

class TakePhoto extends CaptureEvent {
  final bool enableFlash;
  final bool autoFocus;
  final int quality;
  
  const TakePhoto({
    this.enableFlash = false,
    this.autoFocus = true,
    this.quality = 95,
  });
  
  @override
  List<Object> get props => [enableFlash, autoFocus, quality];
}

class PickFromGallery extends CaptureEvent {
  final bool allowMultiple;
  final int maxImages;
  final String? mimeType;
  
  const PickFromGallery({
    this.allowMultiple = false,
    this.maxImages = 5,
    this.mimeType,
  });
  
  @override
  List<Object> get props => [allowMultiple, maxImages, mimeType ?? ''];
}

class AnalyzePhoto extends CaptureEvent {
  final String imagePath;
  final bool useAI;
  
  const AnalyzePhoto({
    required this.imagePath,
    this.useAI = true,
  });
  
  @override
  List<Object> get props => [imagePath, useAI];
}

class SubmitPhoto extends CaptureEvent {
  final PhotoData photo;
  
  const SubmitPhoto(this.photo);
  
  @override
  List<Object> get props => [photo];
}

class UpdatePhoto extends CaptureEvent {
  final PhotoData photo;
  
  const UpdatePhoto(this.photo);
  
  @override
  List<Object> get props => [photo];
}

class DeletePhoto extends CaptureEvent {
  final String photoId;
  
  const DeletePhoto(this.photoId);
  
  @override
  List<Object> get props => [photoId];
}

class LoadUserPhotos extends CaptureEvent {
  final String userId;
  final int limit;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? status;
  
  const LoadUserPhotos({
    required this.userId,
    this.limit = 20,
    this.startDate,
    this.endDate,
    this.status,
  });
  
  @override
  List<Object> get props => [
    userId,
    limit,
    startDate ?? DateTime(0),
    endDate ?? DateTime(0),
    status ?? '',
  ];
}

class LoadCommunityPhotos extends CaptureEvent {
  final double? latitude;
  final double? longitude;
  final double radius;
  final int limit;
  final String? status;
  
  const LoadCommunityPhotos({
    this.latitude,
    this.longitude,
    this.radius = 10.0,
    this.limit = 50,
    this.status,
  });
  
  @override
  List<Object> get props => [
    latitude ?? 0,
    longitude ?? 0,
    radius,
    limit,
    status ?? '',
  ];
}

class SearchPhotos extends CaptureEvent {
  final String query;
  final double? latitude;
  final double? longitude;
  final String? dateRange;
  final String? status;
  
  const SearchPhotos({
    required this.query,
    this.latitude,
    this.longitude,
    this.dateRange,
    this.status,
  });
  
  @override
  List<Object> get props => [
    query,
    latitude ?? 0,
    longitude ?? 0,
    dateRange ?? '',
    status ?? '',
  ];
}

class SetPhotoFilter extends CaptureEvent {
  final String filter;
  
  const SetPhotoFilter(this.filter);
  
  @override
  List<Object> get props => [filter];
}

class UpdatePhotoSettings extends CaptureEvent {
  final Map<String, dynamic> settings;
  
  const UpdatePhotoSettings(this.settings);
  
  @override
  List<Object> get props => [settings];
}

class StartPhotoUpload extends CaptureEvent {
  final String imagePath;
  final PhotoData photo;
  
  const StartPhotoUpload({
    required this.imagePath,
    required this.photo,
  });
  
  @override
  List<Object> get props => [imagePath, photo];
}

class PhotoUploadProgress extends CaptureEvent {
  final String photoId;
  final double progress;
  
  const PhotoUploadProgress({
    required this.photoId,
    required this.progress,
  });
  
  @override
  List<Object> get props => [photoId, progress];
}

class PhotoUploadComplete extends CaptureEvent {
  final String photoId;
  final String url;
  
  const PhotoUploadComplete({
    required this.photoId,
    required this.url,
  });
  
  @override
  List<Object> get props => [photoId, url];
}

class PhotoUploadFailed extends CaptureEvent {
  final String photoId;
  final String error;
  
  const PhotoUploadFailed({
    required this.photoId,
    required this.error,
  });
  
  @override
  List<Object> get props => [photoId, error];
}