import 'package:flutter/material.dart';
import '../../models/product.dart';
import 'product_card.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final List<Product> products = [
    Product(
      id: '1',
      name: 'Maize',
      price: 120,
      owner: '5F3sa2TJcP...',
    ),
    Product(
      id: '2',
      name: 'Beans',
      price: 200,
      owner: '5DAAnrj7V...',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Polkadot Marketplace'),
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          return ProductCard(product: products[index]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create product (next step)
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
