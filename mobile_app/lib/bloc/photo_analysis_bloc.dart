import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../core/services/photo_analysis_service.dart';
import '../core/services/smart_notification_service.dart';
import '../core/services/notification_service.dart';
import '../viewmodels/photo_analysis_viewmodel.dart';

/// Events for photo analysis
abstract class PhotoAnalysisEvent extends Equatable {
  const PhotoAnalysisEvent();

  @override
  List<Object> get props => [];
}

class InitializePhotoAnalysis extends PhotoAnalysisEvent {
  const InitializePhotoAnalysis();
}

class CaptureAndAnalyzePhoto extends PhotoAnalysisEvent {
  final PhotoAnalysisContext context;

  const CaptureAndAnalyzePhoto({
    this.context = PhotoAnalysisContext.outdoorSurvey,
  });

  @override
  List<Object> get props => [context];
}

class AnalyzeGalleryImage extends PhotoAnalysisEvent {
  final String imagePath;
  final PhotoAnalysisContext context;

  const AnalyzeGalleryImage({
    required this.imagePath,
    this.context = PhotoAnalysisContext.outdoorSurvey,
  });

  @override
  List<Object> get props => [imagePath, context];
}

class RealTimeAnalysisUpdate extends PhotoAnalysisEvent {
  final PhotoAnalysisResult result;

  const RealTimeAnalysisUpdate(this.result);

  @override
  List<Object> get props => [result];
}

class ToggleFlash extends PhotoAnalysisEvent {
  const ToggleFlash();
}

class SwitchCameraDirection extends PhotoAnalysisEvent {
  const SwitchCameraDirection();
}

class ShareAnalysisResult extends PhotoAnalysisEvent {
  final PhotoAnalysisResult result;

  const ShareAnalysisResult(this.result);

  @override
  List<Object> get props => [result];
}

class ClearAnalysisResult extends PhotoAnalysisEvent {
  const ClearAnalysisResult();
}

class LoadAnalysisHistory extends PhotoAnalysisEvent {
  const LoadAnalysisHistory();
}

class DeleteAnalysisResult extends PhotoAnalysisEvent {
  final String resultId;

  const DeleteAnalysisResult(this.resultId);

  @override
  List<Object> get props => [resultId];
}

/// States for photo analysis
abstract class PhotoAnalysisBlocState extends Equatable {
  const PhotoAnalysisBlocState();

  @override
  List<Object> get props => [];
}

class PhotoAnalysisInitial extends PhotoAnalysisBlocState {}

class PhotoAnalysisLoading extends PhotoAnalysisBlocState {}

class PhotoAnalysisReady extends PhotoAnalysisBlocState {
  final bool cameraInitialized;
  final bool flashEnabled;
  final CameraLensDirection cameraDirection;

  const PhotoAnalysisReady({
    this.cameraInitialized = false,
    this.flashEnabled = false,
    this.cameraDirection = CameraLensDirection.back,
  });

  @override
  List<Object> get props => [cameraInitialized, flashEnabled, cameraDirection];
}

class PhotoAnalysisInProgress extends PhotoAnalysisBlocState {
  final PhotoAnalysisResult? currentResult;
  final int progress;

  const PhotoAnalysisInProgress({
    this.currentResult,
    this.progress = 0,
  });

  @override
  List<Object> get props => [currentResult ?? '', progress];
}

class PhotoAnalysisCompleted extends PhotoAnalysisBlocState {
  final PhotoAnalysisResult result;
  final PhotoAnalysisContext context;

  const PhotoAnalysisCompleted({
    required this.result,
    this.context = PhotoAnalysisContext.outdoorSurvey,
  });

  @override
  List<Object> get props => [result, context];
}

class PhotoAnalysisError extends PhotoAnalysisBlocState {
  final String error;
  final PhotoAnalysisContext? context;

  const PhotoAnalysisError({
    required this.error,
    this.context,
  });

  @override
  List<Object> get props => [error, context ?? ''];
}

class PhotoAnalysisHistoryLoaded extends PhotoAnalysisBlocState {
  final List<PhotoAnalysisResult> history;

  const PhotoAnalysisHistoryLoaded(this.history);

  @override
  List<Object> get props => [history];
}

/// BLoC for photo analysis functionality
class PhotoAnalysisBloc extends Bloc<PhotoAnalysisEvent, PhotoAnalysisBlocState> {
  final PhotoAnalysisService _analysisService = PhotoAnalysisService();
  final SmartNotificationService _smartService = SmartNotificationService();
  final NotificationService _notificationService = NotificationService();

  PhotoAnalysisBloc() : super(PhotoAnalysisInitial()) {
    on<InitializePhotoAnalysis>(_onInitializePhotoAnalysis);
    on<CaptureAndAnalyzePhoto>(_onCaptureAndAnalyzePhoto);
    on<AnalyzeGalleryImage>(_onAnalyzeGalleryImage);
    on<RealTimeAnalysisUpdate>(_onRealTimeAnalysisUpdate);
    on<ToggleFlash>(_onToggleFlash);
    on<SwitchCameraDirection>(_onSwitchCameraDirection);
    on<ShareAnalysisResult>(_onShareAnalysisResult);
    on<ClearAnalysisResult>(_onClearAnalysisResult);
    on<LoadAnalysisHistory>(_onLoadAnalysisHistory);
    on<DeleteAnalysisResult>(_onDeleteAnalysisResult);
  }

  Future<void> _onInitializePhotoAnalysis(
    InitializePhotoAnalysis event,
    Emitter<PhotoAnalysisBlocState> emit,
  ) async {
    emit(PhotoAnalysisLoading());

    try {
      await _analysisService.initialize();
      
      emit(const PhotoAnalysisReady(
        cameraInitialized: false,
        flashEnabled: false,
        cameraDirection: CameraLensDirection.back,
      ));
    } catch (e) {
      emit(PhotoAnalysisError(error: 'Failed to initialize: $e'));
    }
  }

  Future<void> _onCaptureAndAnalyzePhoto(
    CaptureAndAnalyzePhoto event,
    Emitter<PhotoAnalysisBlocState> emit,
  ) async {
    emit(const PhotoAnalysisInProgress(progress: 10));

    try {
      // Simulate progressive updates for better UX
      emit(const PhotoAnalysisInProgress(progress: 25));
      
      // In a real implementation, you would capture the image from the camera
      // For now, we'll create a placeholder result
      final mockResult = PhotoAnalysisResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: '',
        estimatedPM25: 35.0 + (event.context.index * 5.0),
        estimatedAQI: 100 + (event.context.index * 20),
        confidence: 0.75 + (event.context.index * 0.05),
        analysisTime: 1500,
        visualIndicators: {
          'sky_haze': 0.3 + (event.context.index * 0.1),
          'contrast_reduction': 0.4 + (event.context.index * 0.1),
          'color_distortion': 0.2 + (event.context.index * 0.1),
          'particle_density': 0.5 + (event.context.index * 0.1),
        },
        predictions: {
          'clear_air': 0.2 - (event.context.index * 0.05),
          'haze': 0.3 + (event.context.index * 0.1),
          'smog': 0.1 + (event.context.index * 0.1),
          'dust': 0.2 + (event.context.index * 0.1),
          'pollution': 0.2 + (event.context.index * 0.05),
        },
        qualityLevel: _getQualityLevelForContext(event.context),
        timestamp: DateTime.now(),
      );

      emit(const PhotoAnalysisInProgress(progress: 50));

      // Check if we should send notification
      final filter = await _smartService.shouldShowNotification(
        severity: _getNotificationSeverity(mockResult.estimatedAQI),
        context: NotificationContext.community,
        title: 'Photo Analysis Complete',
        message: 'Analysis shows ${mockResult.qualityLevel} air quality',
      );

      emit(const PhotoAnalysisInProgress(progress: 75));

      if (filter.shouldShow) {
        await _notificationService.showPhotoAnalysisComplete(
          photoTitle: 'Camera Photo',
          estimatedPM25: mockResult.estimatedPM25,
          confidence: mockResult.confidence,
        );
      }

      emit(PhotoAnalysisCompleted(
        result: mockResult,
        context: event.context,
      ));

      // Save to history
      await _analysisService.saveAnalysisResult(mockResult);

    } catch (e) {
      emit(PhotoAnalysisError(
        error: 'Failed to analyze photo: $e',
        context: event.context,
      ));
    }
  }

  Future<void> _onAnalyzeGalleryImage(
    AnalyzeGalleryImage event,
    Emitter<PhotoAnalysisBlocState> emit,
  ) async {
    emit(PhotoAnalysisInProgress(currentResult: null, progress: 10));

    try {
      emit(const PhotoAnalysisInProgress(progress: 30));

      final result = await _analysisService.analyzePhoto(
        File(event.imagePath),
      );

      emit(const PhotoAnalysisInProgress(progress: 70));

      final filter = await _smartService.shouldShowNotification(
        severity: _getNotificationSeverity(result.estimatedAQI),
        context: NotificationContext.community,
        title: 'Photo Analysis Complete',
        message: 'Analysis shows ${result.qualityLevel} air quality',
      );

      if (filter.shouldShow) {
        await _notificationService.showPhotoAnalysisComplete(
          photoTitle: 'Gallery Photo',
          estimatedPM25: result.estimatedPM25,
          confidence: result.confidence,
        );
      }

      emit(PhotoAnalysisCompleted(
        result: result,
        context: event.context,
      ));

      // Save to history
      await _analysisService.saveAnalysisResult(result);

    } catch (e) {
      emit(PhotoAnalysisError(
        error: 'Failed to analyze gallery image: $e',
        context: event.context,
      ));
    }
  }

  void _onRealTimeAnalysisUpdate(
    RealTimeAnalysisUpdate event,
    Emitter<PhotoAnalysisBlocState> emit,
  ) {
    emit(PhotoAnalysisCompleted(
      result: event.result,
      context: PhotoAnalysisContext.outdoorSurvey,
    ));
  }

  Future<void> _onToggleFlash(
    ToggleFlash event,
    Emitter<PhotoAnalysisBlocState> emit,
  ) async {
    // This would typically interact with the camera controller
    // For now, we'll just update the state
    if (state is PhotoAnalysisReady) {
      final currentState = state as PhotoAnalysisReady;
      emit(currentState.copyWith(
        flashEnabled: !currentState.flashEnabled,
      ));
    }
  }

  Future<void> _onSwitchCameraDirection(
    SwitchCameraDirection event,
    Emitter<PhotoAnalysisBlocState> emit,
  ) async {
    if (state is PhotoAnalysisReady) {
      final currentState = state as PhotoAnalysisReady;
      final newDirection = currentState.cameraDirection == CameraLensDirection.back
          ? CameraLensDirection.front
          : CameraLensDirection.back;
      
      emit(currentState.copyWith(
        cameraDirection: newDirection,
        cameraInitialized: false, // Would need reinitialization
      ));
    }
  }

  Future<void> _onShareAnalysisResult(
    ShareAnalysisResult event,
    Emitter<PhotoAnalysisBlocState> emit,
  ) async {
    try {
      final shareText = '''
AIRSHIELD Photo Analysis Result

Context: ${event.result.id}
Estimated AQI: ${event.result.estimatedAQI}
Estimated PM2.5: ${event.result.estimatedPM25.round()} μg/m³
Confidence: ${(event.result.confidence * 100).round()}%
Quality Level: ${event.result.qualityLevel}

Analysis time: ${event.result.analysisTime}ms
Visual Indicators: ${event.result.visualIndicators.entries.map((e) => '${e.key}: ${(e.value * 100).round()}%').join(', ')}

Generated by AIRSHIELD - Your Personal Pollution Defense System
      '''.trim();

      print('Sharing result: $shareText');
      
      // In a real implementation, you'd use the share_plus package
      // await Share.share(shareText);
      
    } catch (e) {
      emit(PhotoAnalysisError(error: 'Failed to share result: $e'));
    }
  }

  void _onClearAnalysisResult(
    ClearAnalysisResult event,
    Emitter<PhotoAnalysisBlocState> emit,
  ) {
    emit(const PhotoAnalysisReady(
      cameraInitialized: true,
      flashEnabled: false,
      cameraDirection: CameraLensDirection.back,
    ));
  }

  Future<void> _onLoadAnalysisHistory(
    LoadAnalysisHistory event,
    Emitter<PhotoAnalysisBlocState> emit,
  ) async {
    try {
      final history = await _analysisService.getAnalysisHistory();
      emit(PhotoAnalysisHistoryLoaded(history));
    } catch (e) {
      emit(PhotoAnalysisError(error: 'Failed to load history: $e'));
    }
  }

  Future<void> _onDeleteAnalysisResult(
    DeleteAnalysisResult event,
    Emitter<PhotoAnalysisBlocState> emit,
  ) async {
    try {
      // Remove from current history state
      if (state is PhotoAnalysisHistoryLoaded) {
        final currentHistory = (state as PhotoAnalysisHistoryLoaded).history;
        final updatedHistory = currentHistory.where((result) => 
            result.id != event.resultId).toList();
        emit(PhotoAnalysisHistoryLoaded(updatedHistory));
      }
      
      // In a real implementation, you'd also delete the file
      // await _deleteAnalysisFile(event.resultId);
      
    } catch (e) {
      emit(PhotoAnalysisError(error: 'Failed to delete result: $e'));
    }
  }

  /// Get quality level based on context
  String _getQualityLevelForContext(PhotoAnalysisContext context) {
    switch (context) {
      case PhotoAnalysisContext.emergencyMonitoring:
        return 'Variable';
      case PhotoAnalysisContext.travelDocumentation:
        return 'Variable';
      default:
        return 'Moderate';
    }
  }

  /// Get notification severity based on AQI
  NotificationSeverity _getNotificationSeverity(int aqi) {
    if (aqi >= 200) return NotificationSeverity.high;
    if (aqi >= 100) return NotificationSeverity.moderate;
    return NotificationSeverity.low;
  }
}

/// Extension for copying PhotoAnalysisReady state
extension PhotoAnalysisReadyCopy on PhotoAnalysisReady {
  PhotoAnalysisReady copyWith({
    bool? cameraInitialized,
    bool? flashEnabled,
    CameraLensDirection? cameraDirection,
  }) {
    return PhotoAnalysisReady(
      cameraInitialized: cameraInitialized ?? this.cameraInitialized,
      flashEnabled: flashEnabled ?? this.flashEnabled,
      cameraDirection: cameraDirection ?? this.cameraDirection,
    );
  }
}

/// Example widget using the PhotoAnalysisBloc
class PhotoAnalysisScreenWithBloc extends StatelessWidget {
  const PhotoAnalysisScreenWithBloc({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PhotoAnalysisBloc()..add(const InitializePhotoAnalysis()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Photo Analysis'),
          actions: [
            BlocBuilder<PhotoAnalysisBloc, PhotoAnalysisBlocState>(
              builder: (context, state) {
                if (state is PhotoAnalysisReady) {
                  return IconButton(
                    icon: Icon(state.flashEnabled ? Icons.flash_on : Icons.flash_off),
                    onPressed: () => context.read<PhotoAnalysisBloc>().add(const ToggleFlash()),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            BlocBuilder<PhotoAnalysisBloc, PhotoAnalysisBlocState>(
              builder: (context, state) {
                if (state is PhotoAnalysisReady) {
                  return IconButton(
                    icon: const Icon(Icons.flip_camera_ios),
                    onPressed: () => context.read<PhotoAnalysisBloc>().add(const SwitchCameraDirection()),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocConsumer<PhotoAnalysisBloc, PhotoAnalysisBlocState>(
          listener: (context, state) {
            if (state is PhotoAnalysisCompleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Analysis complete: ${state.result.qualityLevel} air quality'),
                  duration: const Duration(seconds: 3),
                ),
              );
            } else if (state is PhotoAnalysisError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.error}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          },
          builder: (context, state) {
            return Center(
              child: _buildContent(context, state),
            );
          },
        ),
        floatingActionButton: BlocBuilder<PhotoAnalysisBloc, PhotoAnalysisBlocState>(
          builder: (context, state) {
            if (state is PhotoAnalysisReady || state is PhotoAnalysisInitial) {
              return FloatingActionButton(
                onPressed: () => context.read<PhotoAnalysisBloc>().add(
                  const CaptureAndAnalyzePhoto(),
                ),
                child: const Icon(Icons.camera_alt),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PhotoAnalysisBlocState state) {
    if (state is PhotoAnalysisLoading) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initializing photo analysis...'),
        ],
      );
    }

    if (state is PhotoAnalysisError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<PhotoAnalysisBloc>().add(const InitializePhotoAnalysis()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is PhotoAnalysisInProgress) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Analyzing photo... ${state.progress}%'),
        ],
      );
    }

    if (state is PhotoAnalysisCompleted) {
      return _buildResultCard(context, state.result);
    }

    if (state is PhotoAnalysisReady) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Ready to analyze'),
          const SizedBox(height: 16),
          const Text('Tap the camera button to take a photo'),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildResultCard(BuildContext context, PhotoAnalysisResult result) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Analysis Result',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildResultRow('AQI', result.estimatedAQI.toString()),
            _buildResultRow('PM2.5', '${result.estimatedPM25.round()} μg/m³'),
            _buildResultRow('Quality', result.qualityLevel),
            _buildResultRow('Confidence', '${(result.confidence * 100).round()}%'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.read<PhotoAnalysisBloc>().add(
                      ShareAnalysisResult(result),
                    ),
                    child: const Text('Share'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.read<PhotoAnalysisBloc>().add(
                      const ClearAnalysisResult(),
                    ),
                    child: const Text('New Photo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}