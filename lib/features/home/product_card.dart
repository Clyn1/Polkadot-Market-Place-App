import 'package:flutter/material.dart';
import '../../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: ListTile(
        title: Text(product.name),
        subtitle: Text('Owner: ${product.owner}'),
        trailing: Text('${product.price} DOT'),
        onTap: () {
          // Navigate to details screen
        },
      ),
    );
  }
}
