import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import 'core/di/injection.dart';
import 'core/themes/app_theme.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/services/location_service.dart';
import 'core/services/bluetooth_service.dart';
import 'core/services/api_service.dart';

import 'features/paqg/bloc/paqg_bloc.dart';
import 'features/prediction/bloc/prediction_bloc.dart';
import 'features/capture/bloc/capture_bloc.dart';
import 'features/map/bloc/map_bloc.dart';
import 'features/health/bloc/health_bloc.dart';
import 'features/community/bloc/community_bloc.dart';

import 'models/air_quality_data.dart';
import 'models/user_profile.dart';
import 'models/prediction_data.dart';
import 'models/photo_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize configuration
  await AppConfig.initialize();
  
  // Initialize services
  await configureDependencies();
  await getIt<NotificationService>().initialize();
  await getIt<LocationService>().requestPermissions();
  await getIt<BluetoothService>().initialize();
  
  runApp(AirShieldApp());
}

class AirShieldApp extends StatelessWidget {
  final AppRouter _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<PAQGBloc>()..add(InitializePAQG()),
        ),
        BlocProvider(
          create: (context) => getIt<PredictionBloc>()..add(LoadPredictions()),
        ),
        BlocProvider(
          create: (context) => getIt<CaptureBloc>(),
        ),
        BlocProvider(
          create: (context) => getIt<MapBloc>()..add(InitializeMap()),
        ),
        BlocProvider(
          create: (context) => getIt<HealthBloc>()..add(LoadHealthData()),
        ),
        BlocProvider(
          create: (context) => getIt<CommunityBloc>()..add(LoadCommunityData()),
        ),
      ],
      child: MaterialApp.router(
        title: 'AIRSHIELD',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: _appRouter.config(),
        localizationsDelegates: const [
          // Add localization delegates when implementing i18n
        ],
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('hi', 'IN'),
        ],
      ),
    );
  }
}