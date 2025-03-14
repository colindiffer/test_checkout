import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:uuid/uuid.dart';
import '../checkout_service.dart';
import '../utils/app_logger.dart';
import '../providers/analytics_provider.dart';
import '../models/product.dart'; // Import from models folder instead

class ConfirmationPage extends StatefulWidget {
  final String url;
  final List<Product> products;

  const ConfirmationPage({
    Key? key,
    required this.url,
    required this.products,
  }) : super(key: key);

  @override
  State<ConfirmationPage> createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {
  late final WebViewController controller;
  final AppLogger _logger = AppLogger();
  bool isLoading = true;
  final String _transactionId = const Uuid().v4();
  bool _purchaseTracked = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();

    // We'll track purchase only after order confirmation, not here
  }

  void _initializeWebView() {
    try {
      // Use more reliable URL parsing
      Uri? uri;
      try {
        uri = Uri.parse(widget.url);
      } catch (e) {
        _logger.error('Invalid URL format: ${widget.url}');
      }

      // Extract order ID from URL if available
      String? orderId;
      if (uri != null) {
        orderId = uri.queryParameters['orderId'];
        if (orderId != null) {
          _logger.info('Found order ID in URL: $orderId');
          // Use this order ID instead of the generated one
        }
      }

      // Initialize WebView with proper settings
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..addJavaScriptChannel(
          'AppChannel',
          onMessageReceived: (JavaScriptMessage message) {
            // This channel receives messages from the HTML page
            if (message.message == 'orderComplete') {
              _logger.info('Order completed message received');
              // Now track the purchase after order confirmation
              if (!_purchaseTracked) {
                _trackPurchase(orderIdFromUrl: orderId);
                _purchaseTracked = true;

                // Show confirmation to the user
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order completed successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Navigate back to home after short delay
                  Future.delayed(Duration(seconds: 2), () {
                    if (mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  });
                }
              }
            }
          },
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              _logger.info('Page started loading: $url');
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  isLoading = false;
                });
              }
              _logger.info('Page finished loading: $url');

              // Check if we're on the confirmation page by looking for keywords in the URL
              if (url.contains('confirmation.html')) {
                // Wait a short time to ensure page is fully loaded
                Future.delayed(Duration(seconds: 1), () {
                  if (!_purchaseTracked) {
                    _trackPurchase(orderIdFromUrl: orderId);
                    _purchaseTracked = true;
                  }
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              _logger.error('WebView error: ${error.description}');

              // Show error message on severe errors
              if (mounted && isLoading) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Error loading checkout page: ${error.description}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        )
        ..loadRequest(
            uri ?? Uri.parse('about:blank')); // This line loads the URL

      _logger.info('WebView controller initialized with URL: ${widget.url}');
    } catch (e) {
      _logger.error('Error initializing WebView: $e');

      // Show error in UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize checkout page: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _trackPurchase({String? orderIdFromUrl}) {
    final analyticsProvider =
        Provider.of<AnalyticsProvider>(context, listen: false);

    // Calculate total
    final double total = widget.products
        .fold(0, (sum, product) => sum + (product.price * product.quantity));

    // Convert products to analytics items
    final items = widget.products
        .map((product) => AnalyticsEventItem(
              itemId: product.id,
              itemName: product.name,
              itemCategory: product.category,
              price: product.price,
              quantity: product.quantity,
            ))
        .toList();

    // Use order ID from URL if available, otherwise use generated ID
    final transactionId = orderIdFromUrl ?? _transactionId;

    // Log purchase event
    analyticsProvider.trackPurchase(
      items: items,
      totalValue: total,
      transactionId: transactionId,
      tax: total * 0.08, // Example tax calculation
      shipping: 4.99, // Example shipping cost
    );

    _logger.info('Purchase event tracked with transaction ID: $transactionId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              controller.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(
              controller: controller), // This displays the web content
          if (isLoading)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading checkout page...'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
