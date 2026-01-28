// lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import '../../models/product.dart';
import 'services/blockchain_service.dart';
import 'product_card.dart';
import 'add_product_screen.dart';
import 'search_screen.dart';  

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _blockchainService = BlockchainService();

  bool isLoading = true;
  bool isRefreshing = false;
  String? error;
  List<Product> products = [];
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeAndLoad();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    // Start at full opacity
    _animationController.value = 1.0;
  }

  Future<void> _initializeAndLoad() async {
    try {
      await _blockchainService.connect();
      await _loadProducts();
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Failed to connect to blockchain: $e';
          isLoading = false;
          isRefreshing = false;
        });
      }
    }
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      print('🔄 Loading products from blockchain...');
      
      final fetchedProducts = await _blockchainService.getAllProducts();
      
      if (mounted) {
        setState(() {
          products = fetchedProducts;
          isLoading = false;
        });
      }
      
      print('✅ Loaded ${fetchedProducts.length} products');
      
    } catch (e) {
      print('❌ Error loading products: $e');
      if (mounted) {
        setState(() {
          error = 'Failed to load products: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      isRefreshing = true;
    });
    await _loadProducts();
    setState(() {
      isRefreshing = false;
    });
  }

  void _navigateToAddProduct() async {
    final newProduct = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductScreen(),
      ),
    );

    if (newProduct != null && mounted) {
      setState(() {
        products.insert(0, newProduct);
      });
      
      _showSnackBar(
        '${newProduct.name} added successfully!',
        icon: Icons.check_circle,
        backgroundColor: Colors.green,
      );
    }
  }

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchScreen(allProducts: products),
      ),
    );
  }

  void _showWalletInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Colors.purple.shade700),
            const SizedBox(width: 8),
            const Text('Wallet Info'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Address:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              '5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY',
              style: TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
            const SizedBox(height: 16),
            const Text('Balance:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.currency_bitcoin, color: Colors.orange, size: 20),
                const SizedBox(width: 4),
                Text(
                  '1000.0 DOT',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(
    String message, {
    IconData? icon,
    Color? backgroundColor,
  }) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor ?? Colors.purple,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _blockchainService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Polkadot Marketplace'),
      backgroundColor: Colors.purple,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.account_balance_wallet),
          onPressed: _showWalletInfo,
          tooltip: 'Wallet',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: isLoading ? null : _loadProducts,
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _navigateToSearch,
          tooltip: 'Search',
        ),
      ],
    );
  }

  Widget _buildBody() {
    print('🔍 _buildBody: error=$error, loading=$isLoading, products=${products.length}');
    
    if (error != null) {
      return _buildErrorState();
    }

    if (isLoading) {
      return _buildLoadingState();
    }

    if (products.isEmpty) {
      return _buildEmptyState();
    }

    return _buildProductsList();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Loading Products from Blockchain...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Connecting to Polkadot network...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Blockchain Connection Failed',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error ?? 'Unable to connect to Polkadot network',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _initializeAndLoad,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color: Colors.purple.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Products on Blockchain',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Be the first to list a product\non the Polkadot blockchain!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),  
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToAddProduct,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('List Your First Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: Colors.purple,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${products.length} Product${products.length != 1 ? 's' : ''} on Blockchain',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                Row(
                  children: [
                    if (isRefreshing)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.link,
                      size: 16,
                      color: _blockchainService.isConnected ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return ProductCard(product: products[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildFAB() {
    if (isLoading) return null;

    return FloatingActionButton.extended(
      onPressed: _navigateToAddProduct,
      backgroundColor: Colors.purple,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('List Product'),
      elevation: 4,
    );
  }
}
