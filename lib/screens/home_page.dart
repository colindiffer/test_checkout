import 'package:flutter/material.dart';
import '../widgets/refresh_button.dart';
// ...other imports...

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = false;

  // Add your refresh logic here
  void _refreshData() {
    setState(() {
      _isLoading = true;
    });

    // Add your data refresh logic here
    // For example, fetch new data from API

    // Simulate network request
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Homepage Content',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 20),
                  // Refresh button placed directly on the homepage
                  RefreshButton(
                    isLoading: _isLoading,
                    onRefresh: _refreshData,
                  ),
                ],
              ),
            ),
      // ...existing code...
    );
  }
}
