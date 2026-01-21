import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/bluetooth_service.dart';
import '../services/notification_service.dart';
import '../services/camera_service.dart';
import '../services/ml_service.dart';
import '../services/storage_service.dart';

import '../../features/paqg/bloc/paqg_bloc.dart';
import '../../features/prediction/bloc/prediction_bloc.dart';
import '../../features/capture/bloc/capture_bloc.dart';
import '../../features/map/bloc/map_bloc.dart';
import '../../features/health/bloc/health_bloc.dart';
import '../../features/community/bloc/community_bloc.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Core Services
  getIt.registerLazySingleton<SharedPreferences>(
    () => throw 'SharedPreferences not initialized. Call configureDependencies() after ensuring WidgetsFlutterBinding is initialized.',
  );
  
  getIt.registerLazySingleton<ApiService>(
    () => ApiService(),
  );
  
  getIt.registerLazySingleton<LocationService>(
    () => LocationService(),
  );
  
  getIt.registerLazySingleton<BluetoothService>(
    () => BluetoothService(),
  );
  
  getIt.registerLazySingleton<NotificationService>(
    () => NotificationService(),
  );
  
  getIt.registerLazySingleton<CameraService>(
    () => CameraService(),
  );
  
  getIt.registerLazySingleton<MLService>(
    () => MLService(),
  );
  
  getIt.registerLazySingleton<StorageService>(
    () => StorageService(),
  );
  
  // BLoC Providers
  getIt.registerFactory<PAQGBloc>(
    () => PAQGBloc(
      getIt<ApiService>(),
      getIt<LocationService>(),
      getIt<BluetoothService>(),
      getIt<StorageService>(),
    ),
  );
  
  getIt.registerFactory<PredictionBloc>(
    () => PredictionBloc(
      getIt<ApiService>(),
      getIt<LocationService>(),
      getIt<MLService>(),
    ),
  );
  
  getIt.registerFactory<CaptureBloc>(
    () => CaptureBloc(
      getIt<ApiService>(),
      getIt<CameraService>(),
      getIt<MLService>(),
      getIt<StorageService>(),
    ),
  );
  
  getIt.registerFactory<MapBloc>(
    () => MapBloc(
      getIt<ApiService>(),
      getIt<LocationService>(),
      getIt<MLService>(),
    ),
  );
  
  getIt.registerFactory<HealthBloc>(
    () => HealthBloc(
      getIt<ApiService>(),
      getIt<LocationService>(),
      getIt<MLService>(),
      getIt<StorageService>(),
    ),
  );
  
  getIt.registerFactory<CommunityBloc>(
    () => CommunityBloc(
      getIt<ApiService>(),
      getIt<StorageService>(),
    ),
  );
}