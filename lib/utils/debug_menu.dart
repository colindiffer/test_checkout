import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'dart:io' show Platform;
import '../services/firebase_troubleshooter.dart';
import '../utils/debug_helper.dart';
import '../services/firebase_service.dart';
import 'ios_debug_guide.dart';
import 'ios_debug_configurator.dart';
import 'ios_spm_guide.dart'; // Add this import

class DebugEvent {
  final String name;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;

  DebugEvent({
    required this.name,
    required this.parameters,
    required this.timestamp,
  });
}

class DebugMenu {
  static List<DebugEvent> _debugEvents = [];

  static void addEvent(String name, Map<String, dynamic> parameters) {
    _debugEvents.add(DebugEvent(
      name: name,
      parameters: parameters,
      timestamp: DateTime.now(),
    ));
    // Keep only the last 20 events
    if (_debugEvents.length > 20) {
      _debugEvents.removeAt(0);
    }
  }

  static void showDebugMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DebugMenuSheet(),
    );
  }

  static List<DebugEvent> getEvents() {
    return List.from(_debugEvents);
  }

  static void clearEvents() {
    _debugEvents.clear();
  }
}

class DebugMenuSheet extends StatefulWidget {
  @override
  _DebugMenuSheetState createState() => _DebugMenuSheetState();
}

class _DebugMenuSheetState extends State<DebugMenuSheet> {
  List<String> _firebaseIssues = [];
  bool _isLoading = false;
  List<DebugEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _events = DebugMenu.getEvents();
    _checkFirebaseSetup();
  }

  Future<void> _checkFirebaseSetup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final issues = await FirebaseTroubleshooter.checkFirebaseSetup();
      setState(() {
        _firebaseIssues = issues;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _firebaseIssues = ['Error checking Firebase: $e'];
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Send page view event
      final firebaseService = FirebaseService();
      final pageViewParams = {
        'page_name': 'debug_menu',
        'refresh_time': DateTime.now().toString(),
        'platform': Platform.operatingSystem,
      };

      // Log page view event
      await firebaseService.logEvent('page_view', parameters: pageViewParams);

      // Add to local debug events list
      DebugMenu.addEvent('page_view', pageViewParams);

      // Check Firebase setup
      final issues = await FirebaseTroubleshooter.checkFirebaseSetup();

      // Get latest analytics events
      final events = DebugMenu.getEvents();

      // Update UI with the latest data
      setState(() {
        _firebaseIssues = issues;
        _events = events;
        _isLoading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debug data refreshed and page view event sent'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing debug data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendTestEvent() async {
    try {
      final firebaseService = FirebaseService();

      // Create a test event with timestamp
      final testEvent =
          'debug_test_event_${DateTime.now().millisecondsSinceEpoch}';
      final params = {
        'test_time': DateTime.now().toString(),
        'platform': Platform.operatingSystem,
        'debug_mode': 'true',
      };

      // Log the event
      await firebaseService.logTestEvent(testEvent, parameters: params);

      // Add to local debug events list
      DebugMenu.addEvent(testEvent, params);

      // Refresh the events list
      setState(() {
        _events = DebugMenu.getEvents();
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test event sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending test event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Debug Menu',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          SizedBox(height: 8),

          // Debug actions row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.refresh),
                label: Text('Refresh'),
                onPressed: _isLoading ? null : _refreshData,
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.bug_report),
                label: Text('Send Test Event'),
                onPressed: _isLoading ? null : _sendTestEvent,
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.delete),
                label: Text('Clear Events'),
                onPressed: _isLoading
                    ? null
                    : () {
                        DebugMenu.clearEvents();
                        setState(() {
                          _events = [];
                        });
                      },
              ),
            ],
          ),

          SizedBox(height: 16),

          // Loading indicator or Firebase issues
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _firebaseIssues.isEmpty
                  ? Card(
                      color: Colors.green[100],
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Firebase is configured correctly'),
                          ],
                        ),
                      ),
                    )
                  : Card(
                      color: Colors.red[100],
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.error, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Firebase Issues Found',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            ...List.generate(
                              _firebaseIssues.length,
                              (index) => Padding(
                                padding: EdgeInsets.only(left: 16, top: 4),
                                child: Text('• ${_firebaseIssues[index]}'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

          SizedBox(height: 16),
          Text(
            'Analytics Events (Debug Mode)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),

          // Analytics events list
          Expanded(
            child: _events.isEmpty
                ? Center(
                    child: Text(
                      'No analytics events captured yet.\nTry sending a test event.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[
                          _events.length - 1 - index]; // Show newest first
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          title: Text(event.name),
                          subtitle: Text(
                            '${event.timestamp.hour}:${event.timestamp.minute}:${event.timestamp.second}',
                            style: TextStyle(fontSize: 12),
                          ),
                          children: [
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: event.parameters.entries.map((e) {
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      '${e.key}: ${e.value}',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
