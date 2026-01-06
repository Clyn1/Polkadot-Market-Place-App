import 'package:flutter/material.dart';
import '../../models/product.dart';
import 'product_card.dart';
import 'add_product_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Loading state
  bool isLoading = true;
  
  // Error state
  String? errorMessage;
  
  // Product list
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // Simulates loading products (like fetching from blockchain or API)
  Future<void> _loadProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Simulate network/blockchain delay
      await Future.delayed(const Duration(seconds: 2));

      // Simulate potential error (uncomment to test error state)
      // throw Exception('Failed to connect to Polkadot node');

      // Mock data - In real app, this would come from blockchain/API
      final mockProducts = [
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
        Product(
          id: '3',
          name: 'Coffee Beans',
          price: 350,
          owner: '5GrwvaEF5z...',
        ),
      ];

      setState(() {
        products = mockProducts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load products: ${e.toString()}';
      });
    }
  }

  void _navigateToAddProduct() async {
    final newProduct = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductScreen(),
      ),
    );

    // If a product was returned, add it to the list
    if (newProduct != null) {
      setState(() {
        products.add(newProduct);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Polkadot Marketplace'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
            tooltip: 'Refresh products',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search coming soon!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: isLoading ? null : FloatingActionButton.extended(
        onPressed: _navigateToAddProduct,
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  // Main body logic with conditional rendering
  Widget _buildBody() {
    // Show error state
    if (errorMessage != null) {
      return _buildErrorState();
    }

    // Show loading spinner
    if (isLoading) {
      return _buildLoadingState();
    }

    // Show empty state
    if (products.isEmpty) {
      return _buildEmptyState();
    }

    // Show products list
    return _buildProductsList();
  }

  // Loading state UI
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading products from blockchain...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  // Error state UI
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Empty state UI
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No products available',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to list a product!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToAddProduct,
            icon: const Icon(Icons.add),
            label: const Text('Add First Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Products list UI
  Widget _buildProductsList() {
    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: Colors.purple,
      child: ListView.builder(
        itemCount: products.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return ProductCard(product: products[index]);
        },
      ),
    );
  }
} 
