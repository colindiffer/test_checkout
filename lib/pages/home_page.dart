import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to our store!',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/products');
              },
              child: const Text('Browse Products'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                // Create empty cart data
                final cartData = {'items': [], 'total': 0.0};
                // Launch HTML checkout with empty cart data
                launchHtmlCheckout(context, cartData);
              },
              child: const Text('Go to HTML Checkout'),
            ),
          ],
        ),
      ),
    );
  }

  void launchHtmlCheckout(
      BuildContext context, Map<String, dynamic> cartData) async {
    // Generate a unique order ID
    final orderId = 'order-${DateTime.now().millisecondsSinceEpoch}';

    // Save order to Firebase
    await _saveOrderToFirebase(orderId, cartData, 'pending');

    // Encode cart data for URL
    final jsonData = jsonEncode(cartData);
    final queryParams = Uri.encodeComponent(jsonData);

    // Create URL with cart and order ID
    // final url = Uri.parse(
    //     'https://test-checkout-daff3.web.app/checkout/index.html?cart=$queryParams&orderId=$orderId');
    // If you want to use the demo version instead:
    final url = Uri.parse(
        'https://test-checkout-daff3.web.app/checkout/checkout_demo.html?cart=$queryParams&orderId=$orderId');

    // Show loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening checkout page...')));

    // Launch the URL and listen for order status changes
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      _listenForOrderStatusChanges(context, orderId);
    } else {
      // Show error if the URL can't be launched
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch checkout: $url')));
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _saveOrderToFirebase(
      String orderId, Map<String, dynamic> cartData, String status) async {
    try {
      // Save order data to Firestore
      await FirebaseFirestore.instance.collection('orders').doc(orderId).set({
        'userId': 'anonymous', // Replace with actual user ID if available
        'items': cartData['items'],
        'total': cartData['total'],
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving order to Firebase: $e');
    }
  }

  void _listenForOrderStatusChanges(BuildContext context, String orderId) {
    FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final status = snapshot.data()?['status'];

        // Handle completed order
        if (status == 'completed') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Payment successful! Order completed.')));
          // Navigate to order confirmation or receipt page
          // Navigator.pushNamed(context, '/order-confirmation', arguments: orderId);

          // Note: To deploy updates to the checkout page, run these commands:
          // 1. Build the Flutter web app: flutter build web
          // 2. Deploy to Firebase: firebase deploy --only hosting
        }
        // Handle cancelled order
        else if (status == 'cancelled') {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Checkout cancelled.')));
        }
      }
    }, onError: (error) {
      debugPrint('Error listening for order changes: $error');
    });
  }
}
