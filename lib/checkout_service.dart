import 'dart:convert';
import 'package:http/http.dart' as http;
import 'utils/app_logger.dart';
import 'utils/constants.dart';
import 'models/product.dart';

class CheckoutService {
  final AppLogger _logger = AppLogger();

  // Create an empty checkout session
  Future<String> createEmptyCheckoutSession() async {
    try {
      // Create empty cart data
      final cartData = {'items': [], 'total': 0.0};

      // Generate order ID
      final orderId = 'order-${DateTime.now().millisecondsSinceEpoch}';

      // Encode cart data for URL
      final jsonData = jsonEncode(cartData);
      final queryParams = Uri.encodeComponent(jsonData);

      // Create the checkout URL
      final url =
          '${AppConstants.CHECKOUT_URL}?cart=$queryParams&orderId=$orderId';

      _logger.info('Created empty checkout URL: $url');
      return url;
    } catch (e) {
      _logger.error('Error creating empty checkout session: $e');
      throw Exception('Error creating empty checkout session: $e');
    }
  }

  Future<String> createCheckoutSession(List<Product> cart) async {
    // If products list is empty, create an empty checkout session
    if (cart.isEmpty || cart.every((p) => p.quantity <= 0)) {
      return createEmptyCheckoutSession();
    }

    try {
      // Filter out products with zero quantity
      final cartProducts = cart.where((p) => p.quantity > 0).toList();

      // Calculate the total
      double total = 0;
      for (var product in cartProducts) {
        total += product.price * product.quantity;
      }

      // Format cart data like in home_page.dart
      final cartData = {
        'items': cartProducts
            .map((p) =>
                {'name': p.name, 'price': p.price, 'quantity': p.quantity})
            .toList(),
        'total': total
      };

      // Generate order ID
      final orderId = 'order-${DateTime.now().millisecondsSinceEpoch}';

      // Encode cart data for URL
      final jsonData = jsonEncode(cartData);
      final queryParams = Uri.encodeComponent(jsonData);

      // Create the checkout URL
      final url =
          '${AppConstants.CHECKOUT_URL}?cart=$queryParams&orderId=$orderId';

      _logger.info('Created checkout URL: $url');
      return url;
    } catch (e) {
      _logger.error('Error creating checkout session: $e');
      throw Exception('Error creating checkout session: $e');
    }
  }
}
