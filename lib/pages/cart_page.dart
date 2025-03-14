import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart.dart';

class CartPage extends StatelessWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context);
    final items = cart.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text('Your cart is empty'),
            )
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (ctx, i) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: FittedBox(
                          child: Text('\$${items[i]?.price}'),
                        ),
                      ),
                    ),
                    title: Text(items[i]?.title ?? ''),
                    subtitle: Text(
                        'Total: \$${(items[i]?.price ?? 0 * (items[i]?.quantity ?? 0)).toStringAsFixed(2)}'),
                    trailing: Text('${items[i]?.quantity} x'),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: \$${cart.totalAmount.toStringAsFixed(2)}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: cart.items.isEmpty
                    ? null
                    : () {
                        Navigator.of(context).pushNamed('/checkout');
                      },
                child: const Text('Checkout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
