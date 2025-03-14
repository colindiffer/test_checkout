import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import '../services/analytics_service.dart';

class AnalyticsProvider with ChangeNotifier {
  final AnalyticsService _analyticsService = AnalyticsService();

  // Track page view
  Future<void> trackPageView(String screenName,
      {Map<String, dynamic>? parameters}) async {
    // Add debug parameters - using String values for booleans
    Map<String, dynamic> debugParams = parameters ?? {};
    debugParams['debug_mode'] = 'true';
    debugParams['is_test_event'] = 'true';

    await _analyticsService.logPageView(
      screenName: screenName,
      parameters: debugParams,
    );
  }

  // Track custom event
  Future<void> trackEvent(String eventName,
      {Map<String, dynamic>? parameters}) async {
    // Add debug parameters - using String values for booleans
    Map<String, dynamic> debugParams = parameters ?? {};
    debugParams['debug_mode'] = 'true';
    debugParams['is_test_event'] = 'true';

    await _analyticsService.logEvent(
      name: eventName,
      parameters: debugParams,
    );
  }

  // Add to cart event
  Future<void> trackAddToCart({
    required String itemId,
    required String itemName,
    required String itemCategory,
    required double price,
    required int quantity,
  }) async {
    await _analyticsService.logAddToCart(
      itemId: itemId,
      itemName: itemName,
      itemCategory: itemCategory,
      price: price,
      quantity: quantity,
    );
  }

  // Begin checkout event
  Future<void> trackBeginCheckout({
    required List<AnalyticsEventItem> items,
    required double totalValue,
    String? coupon,
  }) async {
    await _analyticsService.logBeginCheckout(
      items: items,
      value: totalValue,
      coupon: coupon,
    );
  }

  // Purchase completed event
  Future<void> trackPurchase({
    required List<AnalyticsEventItem> items,
    required double totalValue,
    required String transactionId,
    double? tax,
    double? shipping,
    String? coupon,
  }) async {
    await _analyticsService.logPurchase(
      items: items,
      value: totalValue,
      transactionId: transactionId,
      tax: tax,
      shipping: shipping,
      coupon: coupon,
    );
  }
}
