import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import '../utils/debug_helper.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final bool _isDebug = true; // Set to true to mark events as debug events

  AnalyticsService() {
    _setupDebugMode();
  }

  Future<void> _setupDebugMode() async {
    if (_isDebug && kDebugMode) {
      // Enable GA4 DebugView
      await DebugHelper.enableGA4DebugView();

      // Set screen name for debugging
      await _analytics.setCurrentScreen(screenName: 'debug_initial_screen');

      // Log a startup event
      await _analytics.logEvent(
        name: 'app_startup',
        parameters: {
          'debug_mode': 'enabled',
          'timestamp': DateTime.now().toString(),
        },
      );

      print('[DEBUG] Analytics Service initialized with debug properties');
    }
  }

  // Get Firebase Analytics instance
  FirebaseAnalytics get analytics => _analytics;

  // Get Firebase Analytics Observer for Navigator
  FirebaseAnalyticsObserver getAnalyticsObserver() {
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }

  // Log page view event with screen name
  Future<void> logPageView(
      {required String screenName, Map<String, dynamic>? parameters}) async {
    // Add debug parameter - use String values for booleans
    Map<String, dynamic> params = parameters ?? {};
    if (_isDebug) {
      params['debug_mode'] = 'true';
      params['firebase_debug'] = 'true';
      params['debug_event'] = 'true';
    }

    // Convert Map<String, dynamic>? to Map<String, Object>?
    final Map<String, Object>? objectParams = params.map(
      (key, value) => MapEntry(key, value as Object),
    );

    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenName,
      parameters: objectParams,
    );
    print('📊 Logged page view: $screenName [DEBUG MODE]');
  }

  // Log custom event
  Future<void> logEvent(
      {required String name, Map<String, dynamic>? parameters}) async {
    // Add debug parameter - use String values for booleans
    Map<String, dynamic> params = parameters ?? {};
    if (_isDebug) {
      params['debug_mode'] = 'true';
      params['firebase_debug'] = 'true';
      params['debug_event'] = 'true';
    }

    // Convert Map<String, dynamic>? to Map<String, Object>?
    final Map<String, Object>? objectParams = params.map(
      (key, value) => MapEntry(key, value as Object),
    );

    await _analytics.logEvent(
      name: name,
      parameters: objectParams,
    );
    print('📊 Logged event: $name [DEBUG MODE]');
  }

  // Add item to cart event
  Future<void> logAddToCart({
    required String itemId,
    required String itemName,
    required String itemCategory,
    required double price,
    required int quantity,
    String? currency = 'USD',
  }) async {
    // Log the event locally first
    DebugHelper.logAnalyticsEvent('add_to_cart', {
      'itemId': itemId,
      'itemName': itemName,
      'price': price,
      'quantity': quantity
    });

    // Create parameters with debug flags - use String values for booleans
    Map<String, Object> debugParams = {};
    if (_isDebug) {
      debugParams = {
        'debug_mode': 'true',
        'firebase_debug': 'true',
        'debug_event': 'true'
      };
    }

    await _analytics.logAddToCart(
      items: [
        AnalyticsEventItem(
          itemId: itemId,
          itemName: itemName,
          itemCategory: itemCategory,
          price: price,
          quantity: quantity,
        ),
      ],
      currency: currency,
      value: price * quantity,
      parameters: debugParams,
    );

    print('📊 Logged add_to_cart: $itemName [DEBUG MODE]');

    // Also log a custom debug event to ensure it appears in debug view
    if (_isDebug) {
      await _analytics.logEvent(
        name: 'debug_add_to_cart',
        parameters: {
          'item_id': itemId,
          'item_name': itemName,
          'debug_mode': 'true',
        },
      );
    }
  }

  // Begin checkout event
  Future<void> logBeginCheckout({
    required List<AnalyticsEventItem> items,
    required double value,
    String? currency = 'USD',
    String? coupon,
  }) async {
    // Log the event locally first
    DebugHelper.logAnalyticsEvent('begin_checkout', {
      'items_count': items.length,
      'value': value,
      'currency': currency ?? 'USD'
    });

    // Create parameters with debug flags - use String values for booleans
    Map<String, Object> debugParams = {};
    if (_isDebug) {
      debugParams = {
        'debug_mode': 'true',
        'firebase_debug': 'true',
        'debug_event': 'true'
      };
    }

    await _analytics.logBeginCheckout(
      items: items,
      value: value,
      currency: currency,
      coupon: coupon,
      parameters: debugParams,
    );

    print('📊 Logged begin_checkout: \$$value [DEBUG MODE]');

    // Also log a custom debug event to ensure it appears in debug view
    if (_isDebug) {
      await _analytics.logEvent(
        name: 'debug_begin_checkout',
        parameters: {
          'value': value,
          'debug_mode': 'true',
        },
      );
    }
  }

  // Purchase completed event
  Future<void> logPurchase({
    required List<AnalyticsEventItem> items,
    required double value,
    required String transactionId,
    String? currency = 'USD',
    double? tax,
    double? shipping,
    String? coupon,
  }) async {
    // Create parameters with debug flags - use String values for booleans
    Map<String, Object> debugParams = {};
    if (_isDebug) {
      debugParams = {'debug_mode': 'true', 'is_test_event': 'true'};
    }

    await _analytics.logPurchase(
      items: items,
      currency: currency,
      value: value,
      transactionId: transactionId,
      tax: tax,
      shipping: shipping,
      coupon: coupon,
      parameters: debugParams,
    );

    print('📊 Logged purchase: \$$value, ID: $transactionId [DEBUG MODE]');
  }
}
