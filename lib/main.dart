import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'; // Add this import for kDebugMode
import 'firebase_options.dart'; // You may need to create this file
import 'providers/analytics_provider.dart';
import 'checkout_service.dart';
import 'pages/confirmation_page.dart';
import 'services/firebase_service.dart';
import 'utils/app_logger.dart';
import 'models/product.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use FirebaseService for initialization instead of direct initialization
  final firebaseService = FirebaseService();
  await firebaseService.initialize();

  // Enable analytics collection
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  await analytics.setAnalyticsCollectionEnabled(true);

  // Enable debug mode for GA4
  if (kDebugMode) {
    try {
      // This is the proper way to enable DebugView in GA4
      // https://firebase.google.com/docs/analytics/debugview

      // Method 1: Analytics Debug Events
      FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

      // Send a test event that includes a debug parameter
      await FirebaseAnalytics.instance.logEvent(
        name: 'test_event',
        parameters: {
          'debug_mode': 'true',
          'test_parameter': 'test_value',
          'timestamp': DateTime.now().toString(),
        },
      );

      print("[DEBUG] Firebase Analytics debug mode attempt 1 completed");

      // Method 2: Set debug user properties
      await FirebaseAnalytics.instance
          .setUserId(id: 'debug_user_${DateTime.now().millisecondsSinceEpoch}');
      await FirebaseAnalytics.instance
          .setUserProperty(name: 'debug_mode', value: 'true');
      await FirebaseAnalytics.instance
          .setCurrentScreen(screenName: 'debug_screen');

      print("[DEBUG] Firebase Analytics debug mode attempt 2 completed");
    } catch (e) {
      print("Error setting up debug analytics: $e");
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        // Add other providers as needed
      ],
      child: MaterialApp(
        title: 'Checkout Test App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        navigatorObservers: [
          FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
        ],
        home: const MyHomePage(title: 'Checkout Demo Home Page'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final CheckoutService _checkoutService;
  List<Product> _catalog = []; // Available products
  List<Product> _cart = []; // Products in cart
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkoutService = CheckoutService();

    // Initialize product catalog
    _catalog = [
      Product(
        id: "p1",
        name: 'Premium Widget',
        price: 29.99,
        category: 'Widgets',
      ),
      Product(
        id: "p2",
        name: 'Deluxe Gadget',
        price: 49.99,
        category: 'Gadgets',
      ),
      Product(
        id: "p3",
        name: 'Special Item',
        price: 19.99,
        category: 'Items',
      ),
    ];

    // Cart starts empty
    _cart = [];
  }

  Future<void> _startCheckout() async {
    // Track begin_checkout event
    final analyticsProvider =
        Provider.of<AnalyticsProvider>(context, listen: false);
    final items = _cart
        .map((item) => AnalyticsEventItem(
              itemId: item.id,
              itemName: item.name,
              itemCategory: item.category,
              price: item.price,
              quantity: item.quantity,
            ))
        .toList();

    analyticsProvider.trackBeginCheckout(
      items: items,
      totalValue: _totalPrice,
    );

    setState(() {
      _isLoading = true;
    });

    try {
      final url = await _checkoutService.createCheckoutSession(_cart);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmationPage(
            url: url,
            products: _cart,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during checkout: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add product from catalog to cart
  void _addToCart(Product product) {
    // Track add_to_cart event
    final analyticsProvider =
        Provider.of<AnalyticsProvider>(context, listen: false);
    analyticsProvider.trackAddToCart(
      itemId: product.id,
      itemName: product.name,
      itemCategory: product.category,
      price: product.price,
      quantity: 1,
    );

    setState(() {
      // Check if product already exists in cart
      final existingIndex = _cart.indexWhere((item) => item.id == product.id);
      if (existingIndex != -1) {
        // Increment quantity if already in cart
        _cart[existingIndex].quantity += 1;
      } else {
        // Add new product to cart with quantity 1
        final cartProduct = Product(
          id: product.id,
          name: product.name,
          price: product.price,
          category: product.category,
          quantity: 1,
        );
        _cart.add(cartProduct);
      }
    });
  }

  void _updateProductQuantity(String productId, int change) {
    setState(() {
      final productIndex =
          _cart.indexWhere((product) => product.id == productId);
      if (productIndex != -1) {
        final newQuantity = _cart[productIndex].quantity + change;
        if (newQuantity > 0) {
          _cart[productIndex].quantity = newQuantity;
        } else {
          // Remove product if quantity becomes zero
          _cart.removeAt(productIndex);
        }
      }
    });
  }

  double get _totalPrice {
    return _cart.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          // Product catalog section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Available Products',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: _catalog.length,
              itemBuilder: (ctx, i) => Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(_catalog[i].name),
                  subtitle: Text('\$${_catalog[i].price.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: Icon(Icons.add_shopping_cart),
                    onPressed: () => _addToCart(_catalog[i]),
                  ),
                ),
              ),
            ),
          ),

          // Divider between catalog and cart
          Divider(thickness: 1),

          // Shopping cart section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Shopping Cart',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${_cart.length} items',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: _cart.isEmpty
                ? Center(child: Text('Your cart is empty'))
                : ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (ctx, i) => Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${i + 1}'),
                        ),
                        title: Text(_cart[i].name),
                        subtitle: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: () =>
                                  _updateProductQuantity(_cart[i].id, -1),
                            ),
                            Text('${_cart[i].quantity}'),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () =>
                                  _updateProductQuantity(_cart[i].id, 1),
                            ),
                          ],
                        ),
                        trailing: Text(
                          '\$${(_cart[i].price * _cart[i].quantity).toStringAsFixed(2)}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
          ),

          // Checkout section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total:',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '\$${_totalPrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _cart.isEmpty || _isLoading ? null : _startCheckout,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Proceed to Checkout',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
