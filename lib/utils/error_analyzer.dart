import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ErrorAnalyzer {
  /// Analyzes stack trace and returns possible solutions
  static String analyzeStackTrace(String stackTrace) {
    if (stackTrace.contains('Failed to retrieve Firebase Instance Id')) {
      return 'Firebase Instance ID retrieval failure detected.\n'
          'Possible solutions:\n'
          '1. Check Firebase configuration in google-services.json/GoogleService-Info.plist\n'
          '2. Verify internet connectivity\n'
          '3. Ensure Firebase initialization is complete before using Firebase services\n'
          '4. Check for Firebase version compatibility issues';
    }

    if (stackTrace.contains('ComponentElement.performRebuild') &&
        stackTrace.contains('StatefulElement.performRebuild')) {
      return 'Widget build cascade detected - possible causes:\n'
          '1. setState() called during build phase\n'
          '2. Infinite widget rebuilding loop\n'
          '3. Memory leaks in StatefulWidget\n'
          '4. Missing keys in ListView or similar widgets';
    }

    return 'Unknown error pattern. Please check the full stack trace.';
  }

  /// Initialize global error capturing
  static void initializeErrorCapture() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('CAPTURED ERROR: ${details.exception}');
      debugPrint('STACK TRACE: ${details.stack}');
      debugPrint('ANALYSIS: ${analyzeStackTrace(details.stack.toString())}');
    };

    // Handle uncaught async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('UNCAUGHT ASYNC ERROR: $error');
      debugPrint('STACK TRACE: $stack');
      debugPrint('ANALYSIS: ${analyzeStackTrace(stack.toString())}');
      return true; // Prevent app crash
    };
  }
}
