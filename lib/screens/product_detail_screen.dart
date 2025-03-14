import 'package:flutter/material.dart';
import 'package:test_checkout/models/product.dart';
import 'package:test_checkout/services/analytics_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({Key? key, required this.product})
      : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _logPageView();
  }

  // Log page view with product details
  void _logPageView() {
    _analyticsService.logPageView(
      screenName: 'product_detail',
      parameters: {
        'product_id': widget.product.id,
        'product_name': widget.product.name,
        'product_price': widget.product.price,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product detail UI components
            // ...
          ],
        ),
      ),
    );
  }
}
