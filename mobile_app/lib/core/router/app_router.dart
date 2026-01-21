import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injection.dart';
import '../features/paqg/bloc/paqg_bloc.dart';
import '../features/prediction/bloc/prediction_bloc.dart';
import '../features/capture/bloc/capture_bloc.dart';
import '../features/map/bloc/map_bloc.dart';
import '../features/health/bloc/health_bloc.dart';
import '../features/community/bloc/community_bloc.dart';

import '../screens/home/home_screen.dart';
import '../screens/paqg/paqg_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/capture/capture_screen.dart';
import '../screens/capture/camera_preview_screen.dart';
import '../screens/capture/photo_analysis_screen.dart';
import '../screens/prediction/prediction_screen.dart';
import '../screens/prediction/micro_zone_screen.dart';
import '../screens/prediction/safe_routes_screen.dart';
import '../screens/health/health_screen.dart';
import '../screens/health/exposure_history_screen.dart';
import '../screens/health/health_insights_screen.dart';
import '../screens/community/community_screen.dart';
import '../screens/community/leaderboard_screen.dart';
import '../screens/community/challenges_screen.dart';
import '../screens/community/photo_gallery_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/alerts/alerts_screen.dart';
import '../screens/notifications/notification_settings_screen.dart';

class AppRouter {
  final GoRouter router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      // Auth Routes
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main Navigation Routes (with Bottom Navigation)
      ShellRoute(
        builder: (context, state, child) {
          return MultiBlocProvider(
            providers: [
              BlocProvider.value(
                value: getIt<PAQGBloc>()..add(InitializePAQG()),
              ),
              BlocProvider.value(
                value: getIt<PredictionBloc>()..add(LoadPredictions()),
              ),
              BlocProvider.value(
                value: getIt<CaptureBloc>(),
              ),
              BlocProvider.value(
                value: getIt<MapBloc>()..add(InitializeMap()),
              ),
              BlocProvider.value(
                value: getIt<HealthBloc>()..add(LoadHealthData()),
              ),
              BlocProvider.value(
                value: getIt<CommunityBloc>()..add(LoadCommunityData()),
              ),
            ],
            child: child,
          );
        },
        routes: [
          // Home Tab
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(
                path: 'paqg',
                name: 'paqg',
                builder: (context, state) => const PAQGScreen(),
              ),
              GoRoute(
                path: 'alerts',
                name: 'alerts',
                builder: (context, state) => const AlertsScreen(),
              ),
            ],
          ),

          // Map Tab
          GoRoute(
            path: '/map',
            name: 'map',
            builder: (context, state) => const MapScreen(),
            routes: [
              GoRoute(
                path: 'microzone',
                name: 'microzone',
                builder: (context, state) {
                  final lat = double.parse(state.uri.queryParameters['lat'] ?? '0');
                  final lng = double.parse(state.uri.queryParameters['lng'] ?? '0');
                  return MicroZoneScreen(latitude: lat, longitude: lng);
                },
              ),
              GoRoute(
                path: 'safe-routes',
                name: 'safe-routes',
                builder: (context, state) {
                  final from = state.uri.queryParameters['from'] ?? '';
                  final to = state.uri.queryParameters['to'] ?? '';
                  return SafeRoutesScreen(from: from, to: to);
                },
              ),
            ],
          ),

          // Capture Tab
          GoRoute(
            path: '/capture',
            name: 'capture',
            builder: (context, state) => const CaptureScreen(),
            routes: [
              GoRoute(
                path: 'camera',
                name: 'camera',
                builder: (context, state) => const CameraPreviewScreen(),
              ),
              GoRoute(
                path: 'analysis',
                name: 'photo-analysis',
                builder: (context, state) {
                  final imagePath = state.uri.queryParameters['image'] ?? '';
                  final lat = double.parse(state.uri.queryParameters['lat'] ?? '0');
                  final lng = double.parse(state.uri.queryParameters['lng'] ?? '0');
                  return PhotoAnalysisScreen(
                    imagePath: imagePath,
                    latitude: lat,
                    longitude: lng,
                  );
                },
              ),
            ],
          ),

          // Prediction Tab
          GoRoute(
            path: '/prediction',
            name: 'prediction',
            builder: (context, state) => const PredictionScreen(),
          ),

          // Community Tab
          GoRoute(
            path: '/community',
            name: 'community',
            builder: (context, state) => const CommunityScreen(),
            routes: [
              GoRoute(
                path: 'leaderboard',
                name: 'leaderboard',
                builder: (context, state) => const LeaderboardScreen(),
              ),
              GoRoute(
                path: 'challenges',
                name: 'challenges',
                builder: (context, state) => const ChallengesScreen(),
              ),
              GoRoute(
                path: 'gallery',
                name: 'photo-gallery',
                builder: (context, state) => const PhotoGalleryScreen(),
              ),
            ],
          ),

          // Profile Routes (within main shell)
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'health',
                name: 'health',
                builder: (context, state) => const HealthScreen(),
                routes: [
                  GoRoute(
                    path: 'history',
                    name: 'exposure-history',
                    builder: (context, state) => const ExposureHistoryScreen(),
                  ),
                  GoRoute(
                    path: 'insights',
                    name: 'health-insights',
                    builder: (context, state) => const HealthInsightsScreen(),
                  ),
                ],
              ),
              GoRoute(
                path: 'settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'notifications',
                    name: 'notification-settings',
                    builder: (context, state) => const NotificationSettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Standalone Routes (outside main shell)
      GoRoute(
        path: '/',
        redirect: (context, state) => '/home',
      ),
      
      // Error route
      GoRoute(
        path: '/error',
        name: 'error',
        builder: (context, state) => Scaffold(
          body: Center(
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
                  'Something went wrong',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please try again later',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Go Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you\'re looking for doesn\'t exist.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}