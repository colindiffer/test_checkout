import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class DebugHelper {
  static bool debugEnabled = kDebugMode;

  // Enable GA4 DebugView using several methods
  static Future<void> enableGA4DebugView() async {
    if (!debugEnabled) return;

    try {
      // Method 1: Set a debug user property
      await FirebaseAnalytics.instance.setUserProperty(
        name: 'debug_mode',
        value: 'true',
      );

      // Method 2: Use adb command to enable debug mode (show in logs)
      print('');
      print('======================================================');
      print('TO ENABLE GA4 DEBUGVIEW, RUN THE FOLLOWING ADB COMMAND:');
      print('adb shell setprop debug.firebase.analytics.app YOUR_PACKAGE_NAME');
      print('======================================================');
      print('');

      // Method 3: Send a special debug event
      await FirebaseAnalytics.instance.logEvent(
        name: 'debug_enabled',
        parameters: {
          'timestamp': DateTime.now().toString(),
          'device_info': 'Debug device',
        },
      );

      print("[DEBUG] GA4 DebugView setup attempted - check GA4 console");
    } catch (e) {
      print("Error enabling GA4 debug mode: $e");
    }
  }

  // Log the current event to console in debug mode
  static void logAnalyticsEvent(String eventName,
      [Map<String, dynamic>? parameters]) {
    if (!debugEnabled) return;

    final params = parameters ?? <String, dynamic>{};
    print('🔍 ANALYTICS EVENT: $eventName');
    params.forEach((key, value) {
      print('   └─ $key: $value');
    });
  }
}
