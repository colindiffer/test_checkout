import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../services/firebase_service.dart';
import '../utils/debug_menu.dart';

class RefreshButton extends StatelessWidget {
  final VoidCallback? onRefresh;
  final bool isLoading;

  const RefreshButton({
    Key? key,
    this.onRefresh,
    this.isLoading = false,
  }) : super(key: key);

  Future<void> _handleRefresh(BuildContext context) async {
    try {
      // Send page view event
      final firebaseService = FirebaseService();
      final pageViewParams = {
        'page_name': 'homepage',
        'refresh_time': DateTime.now().toString(),
        'platform': Platform.operatingSystem,
      };

      // Log page view event
      await firebaseService.logEvent('page_view', parameters: pageViewParams);

      // Add to local debug events list (for debugging purposes)
      DebugMenu.addEvent('page_view', pageViewParams);

      // Call the parent's refresh function if provided
      if (onRefresh != null) {
        onRefresh!();
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Page refreshed'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(Icons.refresh),
      label: Text('Refresh'),
      onPressed: isLoading ? null : () => _handleRefresh(context),
    );
  }
}
