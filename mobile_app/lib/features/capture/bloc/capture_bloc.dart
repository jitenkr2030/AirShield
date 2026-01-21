import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/photo_data.dart';
import '../../core/services/api_service.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/ml_service.dart';
import '../../core/services/storage_service.dart';

part 'capture_event.dart';
part 'capture_state.dart';

class CaptureBloc extends Bloc<CaptureEvent, CaptureState> {
  final ApiService _apiService;
  final CameraService _cameraService;
  final MLService _mlService;
  final StorageService _storageService;

  CaptureBloc(
    this._apiService,
    this._cameraService,
    this._mlService,
    this._storageService,
  ) : super(CaptureInitial()) {
    on<InitializeCamera>(_onInitializeCamera);
    on<TakePhoto>(_onTakePhoto);
    on<PickFromGallery>(_onPickFromGallery);
    on<AnalyzePhoto>(_onAnalyzePhoto);
    on<SubmitPhoto>(_onSubmitPhoto);
    on<UpdatePhoto>(_onUpdatePhoto);
    on<DeletePhoto>(_onDeletePhoto);
    on<LoadUserPhotos>(_onLoadUserPhotos);
    on<LoadCommunityPhotos>(_onLoadCommunityPhotos);
    on<SearchPhotos>(_onSearchPhotos);
    on<SetPhotoFilter>(_onSetPhotoFilter);
    on<UpdatePhotoSettings>(_onUpdatePhotoSettings);
  }

  Future<void> _onInitializeCamera(
    InitializeCamera event,
    Emitter<CaptureState> emit,
  ) async {
    emit(CaptureLoading());
    
    try {
      await _cameraService.initialize();
      
      emit(CaptureReady(
        cameras: _cameraService.availableCameras,
        currentCamera: _cameraService.getCurrentCamera(),
      ));
      
    } catch (e) {
      emit(CaptureError('Failed to initialize camera: $e'));
    }
  }

  Future<void> _onTakePhoto(
    TakePhoto event,
    Emitter<CaptureState> emit,
  ) async {
    if (state is! CaptureReady) return;
    
    try {
      final currentState = state as CaptureReady;
      emit(currentState.copyWith(isProcessing: true));
      
      final imagePath = await _cameraService.takePicture();
      
      // Analyze the photo immediately
      final analysis = await _mlService.analyzePollutionPhoto(imagePath);
      
      emit(CapturePhotoTaken(
        imagePath: imagePath,
        analysis: analysis,
        isProcessing: false,
      ));
      
    } catch (e) {
      if (state is CaptureReady) {
        final currentState = state as CaptureReady;
        emit(currentState.copyWith(
          error: 'Failed to take photo: $e',
          isProcessing: false,
        ));
      }
    }
  }

  Future<void> _onPickFromGallery(
    PickFromGallery event,
    Emitter<CaptureState> emit,
  ) async {
    if (state is! CaptureReady) return;
    
    try {
      final currentState = state as CaptureReady;
      emit(currentState.copyWith(isProcessing: true));
      
      String imagePath;
      if (event.allowMultiple) {
        imagePath = await _cameraService.pickMultipleImagesFromGallery(
          maxImages: event.maxImages,
        );
      } else {
        imagePath = await _cameraService.pickImageFromGallery();
      }
      
      // Analyze the photo
      final analysis = await _mlService.analyzePollutionPhoto(imagePath);
      
      emit(CapturePhotoTaken(
        imagePath: imagePath,
        analysis: analysis,
        isProcessing: false,
      ));
      
    } catch (e) {
      if (state is CaptureReady) {
        final currentState = state as CaptureReady;
        emit(currentState.copyWith(
          error: 'Failed to pick image: $e',
          isProcessing: false,
        ));
      }
    }
  }

  Future<void> _onAnalyzePhoto(
    AnalyzePhoto event,
    Emitter<CaptureState> emit,
  ) async {
    try {
      emit(CaptureAnalyzing(imagePath: event.imagePath));
      
      final analysis = await _mlService.analyzePollutionPhoto(event.imagePath);
      
      emit(CaptureAnalysisComplete(
        imagePath: event.imagePath,
        analysis: analysis,
      ));
      
    } catch (e) {
      emit(CaptureError('Failed to analyze photo: $e'));
    }
  }

  Future<void> _onSubmitPhoto(
    SubmitPhoto event,
    Emitter<CaptureState> emit,
  ) async {
    try {
      emit(CaptureSubmitting(photo: event.photo));
      
      final submittedPhoto = await _apiService.submitPhoto(event.photo);
      
      // Save locally for offline access
      await _storageService.savePhoto(submittedPhoto);
      
      emit(CapturePhotoSubmitted(
        photo: submittedPhoto,
        points: _calculateSubmissionPoints(event.photo),
      ));
      
      // Clear the photo taken state
      emit(CaptureReady(
        cameras: _cameraService.availableCameras,
        currentCamera: _cameraService.getCurrentCamera(),
      ));
      
    } catch (e) {
      emit(CaptureError('Failed to submit photo: $e'));
    }
  }

  Future<void> _onUpdatePhoto(
    UpdatePhoto event,
    Emitter<CaptureState> emit,
  ) async {
    // This would update an existing photo
    // Implementation depends on API requirements
  }

  Future<void> _onDeletePhoto(
    DeletePhoto event,
    Emitter<CaptureState> emit,
  ) async {
    // This would delete a photo from local storage and potentially server
    // Implementation depends on API requirements
  }

  Future<void> _onLoadUserPhotos(
    LoadUserPhotos event,
    Emitter<CaptureState> emit,
  ) async {
    try {
      final photos = await _storageService.getPhotos(
        userId: event.userId,
        limit: event.limit,
        startDate: event.startDate,
        endDate: event.endDate,
        status: event.status,
      );
      
      emit(CaptureUserPhotosLoaded(photos: photos));
      
    } catch (e) {
      emit(CaptureError('Failed to load user photos: $e'));
    }
  }

  Future<void> _onLoadCommunityPhotos(
    LoadCommunityPhotos event,
    Emitter<CaptureState> emit,
  ) async {
    try {
      final photos = await _apiService.getCommunityPhotos(
        latitude: event.latitude,
        longitude: event.longitude,
        radius: event.radius,
        limit: event.limit,
        status: event.status,
      );
      
      emit(CaptureCommunityPhotosLoaded(photos: photos));
      
    } catch (e) {
      emit(CaptureError('Failed to load community photos: $e'));
    }
  }

  Future<void> _onSearchPhotos(
    SearchPhotos event,
    Emitter<CaptureState> emit,
  ) async {
    // This would search photos by location, date, or other criteria
    // Implementation depends on API search functionality
  }

  void _onSetPhotoFilter(
    SetPhotoFilter event,
    Emitter<CaptureState> emit,
  ) {
    if (state is CaptureReady) {
      final currentState = state as CaptureReady;
      emit(currentState.copyWith(photoFilter: event.filter));
    }
  }

  void _onUpdatePhotoSettings(
    UpdatePhotoSettings event,
    Emitter<CaptureState> emit,
  ) {
    if (state is CaptureReady) {
      final currentState = state as CaptureReady;
      emit(currentState.copyWith(
        settings: {...currentState.settings, ...event.settings},
      ));
    }
  }

  // Helper method to calculate points for photo submission
  int _calculateSubmissionPoints(PhotoData photo) {
    int points = 10; // Base points
    
    // Bonus for high confidence analysis
    if (photo.analysis.confidence > 0.8) points += 5;
    
    // Bonus for good quality photo
    // This would be based on actual image quality metrics
    
    return points;
  }
}