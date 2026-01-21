import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../viewmodels/photo_analysis_viewmodel.dart';

/// Photo Analysis Screen
/// Allows users to capture photos and get instant air quality estimates
class PhotoAnalysisScreen extends StatefulWidget {
  const PhotoAnalysisScreen({Key? key}) : super(key: key);

  @override
  State<PhotoAnalysisScreen> createState() => _PhotoAnalysisScreenState();
}

class _PhotoAnalysisScreenState extends State<PhotoAnalysisScreen>
    with TickerProviderStateMixin {
  late PhotoAnalysisViewModel _viewModel;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _viewModel = PhotoAnalysisViewModel();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize the viewmodel
    _viewModel.initialize();
    
    // Initialize camera in background
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _viewModel.initializeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Analysis'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.camera_alt), text: 'Camera'),
            Tab(icon: Icon(Icons.photo_library), text: 'Gallery'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: ChangeNotifierProvider.value(
        value: _viewModel,
        child: Consumer<PhotoAnalysisViewModel>(
          builder: (context, viewModel, child) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildCameraTab(viewModel),
                _buildGalleryTab(viewModel),
                _buildHistoryTab(viewModel),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCameraTab(PhotoAnalysisViewModel viewModel) {
    if (viewModel.state == PhotoAnalysisState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.state == PhotoAnalysisState.error) {
      return _buildErrorState(viewModel);
    }

    if (viewModel.state == PhotoAnalysisState.result && viewModel.currentResult != null) {
      return _buildResultView(viewModel, viewModel.currentResult!);
    }

    return _buildCameraView(viewModel);
  }

  Widget _buildCameraView(PhotoAnalysisViewModel viewModel) {
    if (!viewModel.isCameraInitialized || viewModel.cameraController == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera not available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => viewModel.initializeCamera(),
              child: const Text('Initialize Camera'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Camera preview
        Positioned.fill(
          child: AspectRatio(
            aspectRatio: viewModel.cameraController!.value.aspectRatio,
            child: CameraPreview(viewModel.cameraController!),
          ),
        ),
        
        // Analysis overlay
        if (viewModel.isAnalyzing)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Analyzing Photo...',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        // Camera controls
        Positioned(
          bottom: 50,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Flash toggle
              FloatingActionButton.small(
                onPressed: () => viewModel.toggleFlash(),
                heroTag: 'flash',
                backgroundColor: viewModel.isFlashOn ? Colors.orange : Colors.grey,
                child: Icon(
                  viewModel.isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                ),
              ),
              
              // Capture button
              GestureDetector(
                onTap: viewModel.isAnalyzing ? null : () => viewModel.takePhotoAndAnalyze(),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: viewModel.isAnalyzing ? Colors.grey : Colors.transparent,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: viewModel.isAnalyzing ? Colors.grey : Colors.white,
                    ),
                    child: viewModel.isAnalyzing
                        ? const Icon(Icons.hourglass_empty, color: Colors.white)
                        : null,
                  ),
                ),
              ),
              
              // Camera switch
              FloatingActionButton.small(
                onPressed: () => viewModel.switchCameraDirection(),
                heroTag: 'switch',
                backgroundColor: Colors.grey,
                child: const Icon(Icons.flip_camera_ios, color: Colors.white),
              ),
            ],
          ),
        ),
        
        // Top controls
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'Take a photo to analyze air quality',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultView(PhotoAnalysisViewModel viewModel, PhotoAnalysisResult result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo preview
          if (result.imagePath.isNotEmpty)
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(File(result.imagePath)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Analysis results
          _buildResultCard(
            title: 'Air Quality Analysis',
            children: [
              _buildResultRow('Estimated AQI', result.estimatedAQI.toString()),
              _buildResultRow('PM2.5', '${result.estimatedPM25.round()} μg/m³'),
              _buildResultRow('Quality Level', result.qualityLevel),
              _buildResultRow('Confidence', '${(result.confidence * 100).round()}%'),
              _buildResultRow('Analysis Time', '${result.analysisTime}ms'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Visual indicators
          if (result.visualIndicators.isNotEmpty)
            _buildResultCard(
              title: 'Visual Indicators',
              children: result.visualIndicators.entries.map((entry) {
                return _buildIndicatorRow(
                  entry.key,
                  entry.value,
                  viewModel.getVisualIndicatorDescriptions()[entry.key] ?? entry.key,
                );
              }).toList(),
            ),
          
          const SizedBox(height: 16),
          
          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => viewModel.shareResult(result),
                  icon: const Icon(Icons.share),
                  label: const Text('Share Result'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => viewModel.clearResult(),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('New Photo'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard({required String title, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
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
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorRow(String key, double value, String description) {
    final percentage = (value * 100).round();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(description),
              Text('$percentage%'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getIndicatorColor(value),
            ),
          ),
        ],
      ),
    );
  }

  Color _getIndicatorColor(double value) {
    if (value >= 0.8) return Colors.red;
    if (value >= 0.6) return Colors.orange;
    if (value >= 0.4) return Colors.yellow;
    if (value >= 0.2) return Colors.lightGreen;
    return Colors.green;
  }

  Widget _buildGalleryTab(PhotoAnalysisViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.photo_library,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Gallery analysis coming soon',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => viewModel.loadGalleryImages(),
            icon: const Icon(Icons.photo_library),
            label: const Text('Load Gallery'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(PhotoAnalysisViewModel viewModel) {
    if (viewModel.isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.analysisHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No analysis history yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.analysisHistory.length,
      itemBuilder: (context, index) {
        final result = viewModel.analysisHistory[index];
        return _buildHistoryItem(result, viewModel);
      },
    );
  }

  Widget _buildHistoryItem(PhotoAnalysisResult result, PhotoAnalysisViewModel viewModel) {
    final dateStr = '${result.timestamp.day}/${result.timestamp.month} ${result.timestamp.hour}:${result.timestamp.minute.toString().padLeft(2, '0')}';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Color(int.parse(viewModel.getAirQualityColor(result.estimatedAQI).replaceAll('#', '0xff'))),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              result.estimatedAQI.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text('AQI: ${result.estimatedAQI} (${result.qualityLevel})'),
        subtitle: Text('$dateStr • ${(result.confidence * 100).round()}% confidence'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'share') {
              viewModel.shareResult(result);
            } else if (value == 'delete') {
              viewModel.deleteAnalysisResult(result.id);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('Share'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showResultDetails(result),
      ),
    );
  }

  void _showResultDetails(PhotoAnalysisResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analysis Result'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('AQI', result.estimatedAQI.toString()),
              _buildDetailRow('PM2.5', '${result.estimatedPM25.round()} μg/m³'),
              _buildDetailRow('Quality Level', result.qualityLevel),
              _buildDetailRow('Confidence', '${(result.confidence * 100).round()}%'),
              _buildDetailRow('Analysis Time', '${result.analysisTime}ms'),
              _buildDetailRow('Date', '${result.timestamp.day}/${result.timestamp.month}/${result.timestamp.year}'),
              _buildDetailRow('Time', '${result.timestamp.hour}:${result.timestamp.minute.toString().padLeft(2, '0')}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildErrorState(PhotoAnalysisViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Analysis Error',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              viewModel.error ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                viewModel.clearError();
                viewModel.clearResult();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _tabController.dispose();
    super.dispose();
  }
}