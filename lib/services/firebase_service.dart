import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../utils/debug_helper.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isInitialized = false;

  Future<void> initializeFirebase() async {
    // Check if we've already initialized Firebase in this instance
    if (_isInitialized) {
      print('Firebase already initialized by this FirebaseService instance');
      return;
    }

    try {
      // Check if Firebase is already initialized at the app level
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('Firebase initialized by FirebaseService');
      } else {
        print('Firebase was already initialized elsewhere');
      }

      _isInitialized = true;

      // Setup debug mode for analytics if in debug build
      if (kDebugMode) {
        await _configureAnalyticsDebugMode();
      }

      // FCM token initialization
      final fcmToken = await FirebaseMessaging.instance.getToken();
      print('FCM Token: $fcmToken');

      // Request notification permissions
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('User granted permission: ${settings.authorizationStatus}');
    } catch (e) {
      print('Error during Firebase initialization: $e');
    }
  }

  // Configure Analytics for Debug View
  Future<void> _configureAnalyticsDebugMode() async {
    try {
      final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

      // Enable collection
      await analytics.setAnalyticsCollectionEnabled(true);

      // Enable GA4 DebugView using our helper
      await DebugHelper.enableGA4DebugView();

      // Set a unique user ID for debug sessions
      if (kDebugMode) {
        String debugUserId =
            'debug_user_${DateTime.now().millisecondsSinceEpoch}';
        await analytics.setUserId(id: debugUserId);
        print('[DEBUG] Set debug user ID: $debugUserId');
      }

      print('[DEBUG] Analytics debug mode configured');
    } catch (e) {
      print('Error configuring analytics debug mode: $e');
    }
  }

  Future<void> initialize() async {
    try {
      await initializeFirebase();
      print('${DateTime.now()} [INFO] Firebase initialized successfully');
    } catch (e) {
      print('Error initializing Firebase: $e');
    }
  }

  // Example method for authentication
  Future<bool> authenticate() async {
    // Authentication logic
    return true;
  }

  // Example method for database operations
  Future<void> saveData(String path, Map<String, dynamic> data) async {
    // Logic to save data to Firebase
    if (kDebugMode) {
      print('Saving data to $path: $data');
    }
  }

  // Example method to fetch data
  Future<Map<String, dynamic>?> getData(String path) async {
    // Logic to fetch data from Firebase
    return {'example': 'data'};
  }
}
