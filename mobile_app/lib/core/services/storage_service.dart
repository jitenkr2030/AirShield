import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../config/app_config.dart';
import '../models/air_quality_data.dart';
import '../models/user_profile.dart';
import '../models/prediction_data.dart';
import '../models/photo_data.dart';

class StorageService {
  static const String _databaseName = 'airshield.db';
  static const int _databaseVersion = 1;
  
  Database? _database;
  SharedPreferences? _prefs;

  // Storage Service
  StorageService() {
    _initializeStorage();
  }

  Future<void> _initializeStorage() async {
    _prefs = await SharedPreferences.getInstance();
    await _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    
    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onDatabaseCreate,
      onUpgrade: _onDatabaseUpgrade,
    );
    
    print('Database initialized: $path');
  }

  Future<void> _onDatabaseCreate(Database db, int version) async {
    // Create all tables
    await _createTables(db);
    
    // Insert default data
    await _insertDefaultData(db);
  }

  Future<void> _onDatabaseCreate(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrade
    if (oldVersion < newVersion) {
      await _upgradeTables(db, oldVersion, newVersion);
    }
  }

  Future<void> _createTables(Database db) async {
    // Air quality measurements table
    await db.execute('''
      CREATE TABLE measurements (
        id TEXT PRIMARY KEY,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        pm25 REAL NOT NULL,
        pm10 REAL NOT NULL,
        aqi REAL NOT NULL,
        co2 REAL DEFAULT 0.0,
        no2 REAL DEFAULT 0.0,
        so2 REAL DEFAULT 0.0,
        o3 REAL DEFAULT 0.0,
        humidity REAL DEFAULT 0.0,
        temperature REAL DEFAULT 0.0,
        wind_speed REAL DEFAULT 0.0,
        wind_direction REAL DEFAULT 0.0,
        source TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        metadata TEXT
      )
    ''');

    // Predictions table
    await db.execute('''
      CREATE TABLE predictions (
        id TEXT PRIMARY KEY,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        prediction_time INTEGER NOT NULL,
        predicted_pm25 REAL NOT NULL,
        predicted_aqi REAL NOT NULL,
        confidence REAL NOT NULL,
        model_version TEXT NOT NULL,
        additional_pollutants TEXT,
        factors TEXT,
        generated_at INTEGER NOT NULL
      )
    ''');

    // Photos table
    await db.execute('''
      CREATE TABLE photos (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        image_url TEXT NOT NULL,
        thumbnail_url TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        location_name TEXT NOT NULL,
        captured_at INTEGER NOT NULL,
        uploaded_at INTEGER NOT NULL,
        estimated_pm25 REAL NOT NULL,
        estimated_aqi REAL NOT NULL,
        confidence REAL NOT NULL,
        visibility TEXT DEFAULT 'good',
        weather_quality REAL DEFAULT 1.0,
        camera_metadata TEXT,
        status TEXT DEFAULT 'pending',
        community_rating REAL DEFAULT 0.0,
        view_count INTEGER DEFAULT 0,
        like_count INTEGER DEFAULT 0,
        comment_count INTEGER DEFAULT 0,
        metadata TEXT,
        verification_status TEXT DEFAULT 'unverified'
      )
    ''');

    // User profiles table
    await db.execute('''
      CREATE TABLE user_profiles (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        height REAL NOT NULL,
        weight REAL NOT NULL,
        health_conditions TEXT,
        medications TEXT,
        allergies TEXT,
        activity_level TEXT DEFAULT 'moderate',
        location TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        notifications_enabled INTEGER DEFAULT 1,
        location_tracking_enabled INTEGER DEFAULT 1,
        data_sharing_enabled INTEGER DEFAULT 0,
        privacy_settings TEXT DEFAULT 'medium',
        theme TEXT DEFAULT 'system',
        language TEXT DEFAULT 'en',
        preferences TEXT,
        created_at INTEGER NOT NULL,
        last_updated INTEGER NOT NULL,
        last_login_at INTEGER
      )
    ''');

    // Health scores table
    await db.execute('''
      CREATE TABLE health_scores (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        score REAL NOT NULL,
        timestamp INTEGER NOT NULL,
        factors TEXT,
        location TEXT,
        exposure_level TEXT,
        FOREIGN KEY (user_id) REFERENCES user_profiles (id)
      )
    ''');

    // Alerts table
    await db.execute('''
      CREATE TABLE alerts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        severity TEXT NOT NULL,
        location_latitude REAL,
        location_longitude REAL,
        triggered_at INTEGER NOT NULL,
        acknowledged INTEGER DEFAULT 0,
        expires_at INTEGER,
        FOREIGN KEY (user_id) REFERENCES user_profiles (id)
      )
    ''');

    // Gamification data table
    await db.execute('''
      CREATE TABLE gamification (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        total_points INTEGER DEFAULT 0,
        current_streak INTEGER DEFAULT 0,
        longest_streak INTEGER DEFAULT 0,
        total_photos INTEGER DEFAULT 0,
        verified_photos INTEGER DEFAULT 0,
        current_rank TEXT DEFAULT 'Rookie',
        rank_position INTEGER DEFAULT 0,
        badges TEXT,
        achievements TEXT,
        active_challenges TEXT,
        completed_challenges TEXT,
        leaderboard_scores TEXT,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user_profiles (id)
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_measurements_timestamp ON measurements(timestamp)');
    await db.execute('CREATE INDEX idx_measurements_location ON measurements(latitude, longitude)');
    await db.execute('CREATE INDEX idx_predictions_time ON predictions(prediction_time)');
    await db.execute('CREATE INDEX idx_photos_location ON photos(latitude, longitude)');
    await db.execute('CREATE INDEX idx_photos_captured ON photos(captured_at)');
    await db.execute('CREATE INDEX idx_health_scores_user ON health_scores(user_id, timestamp)');
    await db.execute('CREATE INDEX idx_alerts_user ON alerts(user_id, triggered_at)');
    await db.execute('CREATE INDEX idx_gamification_user ON gamification(user_id)');
  }

  Future<void> _insertDefaultData(Database db) async {
    // Insert default badges
    await db.insert('gamification', {
      'id': 'default_badges',
      'user_id': 'default',
      'badges': jsonEncode([
        {
          'badge_id': 'first_photo',
          'name': 'First Photo',
          'description': 'Captured your first pollution photo',
          'icon_url': 'assets/icons/first_photo.png',
          'category': 'photography',
          'earned_at': DateTime.now().millisecondsSinceEpoch,
        },
      ]),
    });
  }

  Future<void> _upgradeTables(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      switch (version) {
        case 2:
          // Upgrade to version 2
          break;
        case 3:
          // Upgrade to version 3
          break;
      }
    }
  }

  // Measurements CRUD
  Future<void> saveMeasurement(AirQualityData measurement) async {
    final db = _database;
    if (db == null) return;

    await db.insert('measurements', {
      'id': measurement.id,
      'latitude': measurement.latitude,
      'longitude': measurement.longitude,
      'pm25': measurement.pm25,
      'pm10': measurement.pm10,
      'aqi': measurement.aqi,
      'co2': measurement.co2,
      'no2': measurement.no2,
      'so2': measurement.so2,
      'o3': measurement.o3,
      'humidity': measurement.humidity,
      'temperature': measurement.temperature,
      'wind_speed': measurement.windSpeed,
      'wind_direction': measurement.windDirection,
      'source': measurement.source,
      'timestamp': measurement.timestamp.millisecondsSinceEpoch,
      'metadata': measurement.metadata != null ? jsonEncode(measurement.metadata) : null,
    });
  }

  Future<List<AirQualityData>> getMeasurements({
    DateTime? startDate,
    DateTime? endDate,
    double? latitude,
    double? longitude,
    double? radius,
    int? limit,
  }) async {
    final db = _database;
    if (db == null) return [];

    var query = 'SELECT * FROM measurements WHERE 1=1';
    final args = <dynamic>[];

    if (startDate != null) {
      query += ' AND timestamp >= ?';
      args.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      query += ' AND timestamp <= ?';
      args.add(endDate.millisecondsSinceEpoch);
    }

    if (latitude != null && longitude != null && radius != null) {
      query += ' AND (latitude - ?) * (latitude - ?) + (longitude - ?) * (longitude - ?) <= ?';
      args.addAll([
        latitude,
        latitude,
        longitude,
        longitude,
        radius * radius,
      ]);
    }

    query += ' ORDER BY timestamp DESC';

    if (limit != null) {
      query += ' LIMIT ?';
      args.add(limit);
    }

    final rows = await db.rawQuery(query, args);

    return rows.map((row) => AirQualityData(
      id: row['id'] as String,
      latitude: row['latitude'] as double,
      longitude: row['longitude'] as double,
      pm25: row['pm25'] as double,
      pm10: row['pm10'] as double,
      aqi: row['aqi'] as double,
      co2: row['co2'] as double? ?? 0.0,
      no2: row['no2'] as double? ?? 0.0,
      so2: row['so2'] as double? ?? 0.0,
      o3: row['o3'] as double? ?? 0.0,
      humidity: row['humidity'] as double? ?? 0.0,
      temperature: row['temperature'] as double? ?? 0.0,
      windSpeed: row['wind_speed'] as double? ?? 0.0,
      windDirection: row['wind_direction'] as double? ?? 0.0,
      source: row['source'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
      metadata: row['metadata'] != null ? jsonDecode(row['metadata'] as String) : null,
    )).toList();
  }

  Future<void> deleteOldMeasurements(Duration olderThan) async {
    final db = _database;
    if (db == null) return;

    final cutoff = DateTime.now().subtract(olderThan).millisecondsSinceEpoch;
    await db.delete(
      'measurements',
      where: 'timestamp < ?',
      whereArgs: [cutoff],
    );
  }

  // Predictions CRUD
  Future<void> savePrediction(PredictionData prediction) async {
    final db = _database;
    if (db == null) return;

    await db.insert('predictions', {
      'id': prediction.id,
      'latitude': prediction.latitude,
      'longitude': prediction.longitude,
      'prediction_time': prediction.predictionTime.millisecondsSinceEpoch,
      'predicted_pm25': prediction.predictedPM25,
      'predicted_aqi': prediction.predictedAQI,
      'confidence': prediction.confidence,
      'model_version': prediction.modelVersion,
      'additional_pollutants': jsonEncode(prediction.additionalPollutants),
      'factors': jsonEncode(prediction.factors),
      'generated_at': prediction.generatedAt.millisecondsSinceEpoch,
    });
  }

  Future<List<PredictionData>> getPredictions({
    required double latitude,
    required double longitude,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final db = _database;
    if (db == null) return [];

    var query = 'SELECT * FROM predictions WHERE latitude = ? AND longitude = ?';
    final args = [latitude, longitude];

    if (startDate != null) {
      query += ' AND prediction_time >= ?';
      args.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      query += ' AND prediction_time <= ?';
      args.add(endDate.millisecondsSinceEpoch);
    }

    query += ' ORDER BY prediction_time DESC';

    if (limit != null) {
      query += ' LIMIT ?';
      args.add(limit);
    }

    final rows = await db.rawQuery(query, args);

    return rows.map((row) => PredictionData(
      id: row['id'] as String,
      latitude: row['latitude'] as double,
      longitude: row['longitude'] as double,
      predictionTime: DateTime.fromMillisecondsSinceEpoch(row['prediction_time'] as int),
      predictedPM25: row['predicted_pm25'] as double,
      predictedAQI: row['predicted_aqi'] as double,
      confidence: row['confidence'] as double,
      modelVersion: row['model_version'] as String,
      additionalPollutants: jsonDecode(row['additional_pollutants'] as String) ?? {},
      factors: (jsonDecode(row['factors'] as String) as List)
          .map((factor) => PredictionFactor.fromJson(factor))
          .toList(),
      generatedAt: DateTime.fromMillisecondsSinceEpoch(row['generated_at'] as int),
    )).toList();
  }

  // Photos CRUD
  Future<void> savePhoto(PhotoData photo) async {
    final db = _database;
    if (db == null) return;

    await db.insert('photos', {
      'id': photo.id,
      'user_id': photo.userId,
      'title': photo.title,
      'description': photo.description,
      'image_url': photo.imageUrl,
      'thumbnail_url': photo.thumbnailUrl,
      'latitude': photo.latitude,
      'longitude': photo.longitude,
      'location_name': photo.locationName,
      'captured_at': photo.capturedAt.millisecondsSinceEpoch,
      'uploaded_at': photo.uploadedAt.millisecondsSinceEpoch,
      'estimated_pm25': photo.analysis.estimatedPM25,
      'estimated_aqi': photo.analysis.estimatedAQI,
      'confidence': photo.analysis.confidence,
      'visibility': photo.visibility,
      'weather_quality': photo.weatherQuality,
      'camera_metadata': photo.cameraMetadata,
      'status': photo.status,
      'community_rating': photo.communityRating,
      'view_count': photo.viewCount,
      'like_count': photo.likeCount,
      'comment_count': photo.commentCount,
      'metadata': jsonEncode(photo.metadata),
      'verification_status': photo.verificationStatus,
    });
  }

  Future<List<PhotoData>> getPhotos({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    double? latitude,
    double? longitude,
    double? radius,
    String? status,
    int? limit,
  }) async {
    final db = _database;
    if (db == null) return [];

    var query = 'SELECT * FROM photos WHERE 1=1';
    final args = <dynamic>[];

    if (userId != null) {
      query += ' AND user_id = ?';
      args.add(userId);
    }

    if (startDate != null) {
      query += ' AND captured_at >= ?';
      args.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      query += ' AND captured_at <= ?';
      args.add(endDate.millisecondsSinceEpoch);
    }

    if (latitude != null && longitude != null && radius != null) {
      query += ' AND (latitude - ?) * (latitude - ?) + (longitude - ?) * (longitude - ?) <= ?';
      args.addAll([
        latitude,
        latitude,
        longitude,
        longitude,
        radius * radius,
      ]);
    }

    if (status != null) {
      query += ' AND status = ?';
      args.add(status);
    }

    query += ' ORDER BY captured_at DESC';

    if (limit != null) {
      query += ' LIMIT ?';
      args.add(limit);
    }

    final rows = await db.rawQuery(query, args);

    return rows.map((row) => PhotoData(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      title: row['title'] as String,
      description: row['description'] as String,
      imageUrl: row['image_url'] as String,
      thumbnailUrl: row['thumbnail_url'] as double? ?? 0.0,
      latitude: row['latitude'] as double,
      longitude: row['longitude'] as double,
      locationName: row['location_name'] as String,
      capturedAt: DateTime.fromMillisecondsSinceEpoch(row['captured_at'] as int),
      uploadedAt: DateTime.fromMillisecondsSinceEpoch(row['uploaded_at'] as int),
      analysis: PhotoAnalysis(
        analysisId: row['id'] as String,
        estimatedPM25: row['estimated_pm25'] as double,
        estimatedAQI: row['estimated_aqi'] as double,
        confidence: row['confidence'] as double,
        visibilityScore: 0.5,
        hazeIntensity: 0.5,
        colorScattering: 0.5,
        sunAngle: 0.0,
        analyzedAt: DateTime.fromMillisecondsSinceEpoch(row['captured_at'] as int),
      ),
      visibility: row['visibility'] as String? ?? 'good',
      weatherQuality: row['weather_quality'] as double? ?? 1.0,
      cameraMetadata: row['camera_metadata'] as String? ?? '',
      status: row['status'] as String? ?? 'pending',
      communityRating: row['community_rating'] as double? ?? 0.0,
      viewCount: row['view_count'] as int? ?? 0,
      likeCount: row['like_count'] as int? ?? 0,
      commentCount: row['comment_count'] as int? ?? 0,
      metadata: jsonDecode(row['metadata'] as String) ?? {},
      verificationStatus: row['verification_status'] as String? ?? 'unverified',
    )).toList();
  }

  // User Profile CRUD
  Future<void> saveUserProfile(UserProfile profile) async {
    final db = _database;
    if (db == null) return;

    await db.insert('user_profiles', {
      'id': profile.id,
      'email': profile.email,
      'first_name': profile.firstName,
      'last_name': profile.lastName,
      'age': profile.age,
      'gender': profile.gender,
      'height': profile.height,
      'weight': profile.weight,
      'health_conditions': jsonEncode(profile.healthConditions),
      'medications': jsonEncode(profile.medications),
      'allergies': jsonEncode(profile.allergies),
      'activity_level': profile.activityLevel,
      'location': profile.location,
      'latitude': profile.latitude,
      'longitude': profile.longitude,
      'notifications_enabled': profile.notificationsEnabled ? 1 : 0,
      'location_tracking_enabled': profile.locationTrackingEnabled ? 1 : 0,
      'data_sharing_enabled': profile.dataSharingEnabled ? 1 : 0,
      'privacy_settings': profile.privacySettings,
      'theme': profile.theme,
      'language': profile.language,
      'preferences': jsonEncode(profile.preferences),
      'created_at': profile.createdAt.millisecondsSinceEpoch,
      'last_updated': profile.lastUpdated.millisecondsSinceEpoch,
      'last_login_at': profile.lastLoginAt?.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    final db = _database;
    if (db == null) return null;

    final row = await db.query(
      'user_profiles',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (row.isEmpty) return null;

    final data = row.first;
    return UserProfile(
      id: data['id'] as String,
      email: data['email'] as String,
      firstName: data['first_name'] as String,
      lastName: data['last_name'] as String,
      age: data['age'] as int,
      gender: data['gender'] as String,
      height: data['height'] as double,
      weight: data['weight'] as double,
      healthConditions: jsonDecode(data['health_conditions'] as String) ?? [],
      medications: jsonDecode(data['medications'] as String) ?? [],
      allergies: jsonDecode(data['allergies'] as String) ?? [],
      activityLevel: data['activity_level'] as String,
      location: data['location'] as String,
      latitude: data['latitude'] as double,
      longitude: data['longitude'] as double,
      notificationsEnabled: (data['notifications_enabled'] as int) == 1,
      locationTrackingEnabled: (data['location_tracking_enabled'] as int) == 1,
      dataSharingEnabled: (data['data_sharing_enabled'] as int) == 1,
      privacySettings: data['privacy_settings'] as String,
      theme: data['theme'] as String,
      language: data['language'] as String,
      preferences: jsonDecode(data['preferences'] as String) ?? {},
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['created_at'] as int),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(data['last_updated'] as int),
      lastLoginAt: data['last_login_at'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(data['last_login_at'] as int)
        : null,
    );
  }

  // Shared Preferences helpers
  Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  Future<void> setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  Future<void> setInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  Future<void> setDouble(String key, double value) async {
    await _prefs?.setDouble(key, value);
  }

  Future<void> setStringList(String key, List<String> value) async {
    await _prefs?.setStringList(key, value);
  }

  String? getString(String key, [String? defaultValue]) {
    return _prefs?.getString(key) ?? defaultValue;
  }

  bool getBool(String key, [bool defaultValue = false]) {
    return _prefs?.getBool(key) ?? defaultValue;
  }

  int getInt(String key, [int defaultValue = 0]) {
    return _prefs?.getInt(key) ?? defaultValue;
  }

  double getDouble(String key, [double defaultValue = 0.0]) {
    return _prefs?.getDouble(key) ?? defaultValue;
  }

  List<String> getStringList(String key, [List<String>? defaultValue]) {
    return _prefs?.getStringList(key) ?? defaultValue ?? [];
  }

  Future<bool> containsKey(String key) async {
    return _prefs?.containsKey(key) ?? false;
  }

  Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
  }

  Future<bool> clear() async {
    return await _prefs?.clear() ?? false;
  }

  // File Storage
  Future<String> getCacheDirectory() async {
    final directory = await getTemporaryDirectory();
    return directory.path;
  }

  Future<String> getDocumentsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<String> saveFileToCache(String fileName, Uint8List data) async {
    final directory = await getCacheDirectory();
    final file = File('$directory/$fileName');
    await file.writeAsBytes(data);
    return file.path;
  }

  Future<Uint8List> getFileFromCache(String fileName) async {
    final directory = await getCacheDirectory();
    final file = File('$directory/$fileName');
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return Uint8List(0);
  }

  Future<void> deleteCacheFile(String fileName) async {
    final directory = await getCacheDirectory();
    final file = File('$directory/$fileName');
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Cache Management
  Future<void> clearCache() async {
    final directory = await getCacheDirectory();
    final dir = Directory(directory);
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
    }
  }

  Future<int> getCacheSize() async {
    int totalSize = 0;
    final directory = await getCacheDirectory();
    final dir = Directory(directory);
    
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
    }
    
    return totalSize;
  }

  // Data Synchronization
  Future<List<AirQualityData>> getUnsyncedMeasurements() async {
    final db = _database;
    if (db == null) return [];

    final rows = await db.query(
      'measurements',
      where: 'metadata IS NULL OR json_extract(metadata, \'$.synced\') IS NULL',
    );

    return rows.map((row) => AirQualityData(
      id: row['id'] as String,
      latitude: row['latitude'] as double,
      longitude: row['longitude'] as double,
      pm25: row['pm25'] as double,
      pm10: row['pm10'] as double,
      aqi: row['aqi'] as double,
      co2: row['co2'] as double? ?? 0.0,
      no2: row['no2'] as double? ?? 0.0,
      so2: row['so2'] as double? ?? 0.0,
      o3: row['o3'] as double? ?? 0.0,
      humidity: row['humidity'] as double? ?? 0.0,
      temperature: row['temperature'] as double? ?? 0.0,
      windSpeed: row['wind_speed'] as double? ?? 0.0,
      windDirection: row['wind_direction'] as double? ?? 0.0,
      source: row['source'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
      metadata: row['metadata'] != null ? jsonDecode(row['metadata'] as String) : null,
    )).toList();
  }

  Future<void> markMeasurementsSynced(List<String> measurementIds) async {
    final db = _database;
    if (db == null) return;

    for (final id in measurementIds) {
      final row = await db.query(
        'measurements',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (row.isNotEmpty) {
        final currentMetadata = row.first['metadata'] != null 
          ? jsonDecode(row.first['metadata'] as String)
          : <String, dynamic>{};
        
        currentMetadata['synced'] = true;
        currentMetadata['synced_at'] = DateTime.now().millisecondsSinceEpoch;

        await db.update(
          'measurements',
          {'metadata': jsonEncode(currentMetadata)},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }
  }

  // Database maintenance
  Future<void> compactDatabase() async {
    final db = _database;
    if (db == null) return;

    await db.execute('VACUUM');
  }

  Future<void> analyzeDatabase() async {
    final db = _database;
    if (db == null) return;

    await db.execute('ANALYZE');
  }

  Future<void> dispose() async {
    await _database?.close();
    _database = null;
  }
}