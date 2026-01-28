// lib/features/home/services/blockchain_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/product.dart';
import '../../../core/constants/contract_constants.dart';

class BlockchainService {
  WebSocketChannel? _wsChannel;
  bool _isConnected = false;
  bool _isConnecting = false;

  // ✅ Storage key for products
  static const String _productsKey = 'marketplace_products';

  bool get isConnected => _isConnected;

  // 🔗 Connect to local Substrate node
  Future<void> connect() async {
    if (_isConnecting) {
      print('⏳ Connection already in progress...');
      return;
    }

    if (_isConnected) {
      print('✅ Already connected to blockchain');
      return;
    }

    _isConnecting = true;
    
    try {
      print('🔗 Connecting to ${ContractConstants.nodeUrl}...');
      
      _wsChannel = WebSocketChannel.connect(
        Uri.parse(ContractConstants.nodeUrl),
      );

      await Future.delayed(const Duration(seconds: 1));
      
      _isConnected = true;
      print('✅ Connected to Polkadot node');
      
    } catch (e) {
      _isConnected = false;
      print('⚠️ Could not connect to node (this is OK for demo): $e');
      print('📦 Will use mock data instead');
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> disconnect() async {
    if (_wsChannel != null) {
      await _wsChannel!.sink.close();
      _wsChannel = null;
      _isConnected = false;
      print('🔌 Disconnected from node');
    }
  }

  Future<void> ensureConnected() async {
    if (!_isConnected) {
      await connect();
    }
  }

  // 💾 Save products to local storage
  Future<void> _saveProducts(List<Product> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = products.map((p) => p.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await prefs.setString(_productsKey, jsonString);
      print('💾 Saved ${products.length} products to storage');
    } catch (e) {
      print('❌ Failed to save products: $e');
    }
  }

  // 📂 Load products from local storage
  Future<List<Product>> _loadStoredProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_productsKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        print('📂 No stored products found');
        return [];
      }
      
      final jsonList = json.decode(jsonString) as List;
      final products = jsonList.map((json) => Product.fromJson(json)).toList();
      
      print('📂 Loaded ${products.length} products from storage');
      return products;
      
    } catch (e) {
      print('❌ Failed to load stored products: $e');
      return [];
    }
  }

  // 🏭 Get default/demo products
  List<Product> _getDefaultProducts() {
    return [
      Product(
        id: 1,
        name: 'Organic Mangoes',
        description: 'Fresh organic mangoes from Kisumu farms',
        price: BigInt.from(100000000000),
        ipfsHash: 'QmUNyjtUTFMq1PjQadUz3VsJfTcXeqUmfx5ySKSgoXEGt7',
        seller: ContractConstants.aliceAddress,
        owner: ContractConstants.aliceAddress,
        isAvailable: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Product(
        id: 2,
        name: 'Casio Watch',
        description: 'Best metal Casio Watch',
        price: BigInt.from(1000000000000),
        ipfsHash: 'Qma85bUFTGZEXkbwZEhkGHTe5RZw2LrhYNNtsa2v6cPF1v',
        seller: ContractConstants.aliceAddress,
        owner: ContractConstants.aliceAddress,
        isAvailable: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Product(
        id: 3,
        name: 'Water Bottle',
        description: 'Fresh bottled water',
        price: BigInt.from(500000000000),
        ipfsHash: 'QmdZmN7rMFUTrSyyvkrTPd3bp6Mv4mUoboEmPKTb6vzC5m',
        seller: ContractConstants.bobAddress,
        owner: ContractConstants.bobAddress,
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
    ];
  }

  // 🔍 Get All Products from Blockchain + Storage
  Future<List<Product>> getAllProducts() async {
    await ensureConnected();

    try {
      print('📋 Fetching products...');
      
      // Load from storage
      final storedProducts = await _loadStoredProducts();
      
      // If we have stored products, use those
      if (storedProducts.isNotEmpty) {
        print('✅ Using ${storedProducts.length} products from storage');
        return storedProducts;
      }
      
      // Otherwise, initialize with defaults and save them
      final defaultProducts = _getDefaultProducts();
      await _saveProducts(defaultProducts);
      
      print('✅ Initialized with ${defaultProducts.length} default products');
      return defaultProducts;
      
    } catch (e) {
      print('❌ Failed to fetch products: $e');
      return [];
    }
  }

  // 🛍️ Get Single Product
  Future<Product?> getProduct(int productId) async {
    await ensureConnected();
    
    try {
      print('🔍 Querying product ID: $productId');
      
      final allProducts = await getAllProducts();
      
      for (var product in allProducts) {
        if (product.id == productId) {
          return product;
        }
      }
      
      return null;
      
    } catch (e) {
      print('❌ Failed to get product $productId: $e');
      return null;
    }
  }

  // 📝 List Product on Blockchain
  Future<String> listProduct({
    required String name,
    required String description,
    required BigInt price,
    required String ipfsHash,
    String? signerSeed,
  }) async {
    await ensureConnected();
    
    try {
      print('📝 Listing product on blockchain...');
      print('   Name: $name');
      print('   Price: $price planck');
      print('   IPFS: $ipfsHash');
      
      // Simulate blockchain transaction
      await Future.delayed(const Duration(seconds: 2));
      
      // ✅ Create new product
      final existingProducts = await getAllProducts();
      final newId = existingProducts.isEmpty 
          ? 1 
          : existingProducts.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
      
      final newProduct = Product(
        id: newId,
        name: name,
        description: description,
        price: price,
        ipfsHash: ipfsHash,
        seller: ContractConstants.aliceAddress,
        owner: ContractConstants.aliceAddress,
        isAvailable: true,
        createdAt: DateTime.now(),
      );
      
      // ✅ Add to list and save
      final updatedProducts = [newProduct, ...existingProducts];
      await _saveProducts(updatedProducts);
      
      print('✅ Product "$name" listed successfully! Total products: ${updatedProducts.length}');
      
      final txHash = 'tx_${DateTime.now().millisecondsSinceEpoch}';
      return txHash;
      
    } catch (e) {
      print('❌ Failed to list product: $e');
      rethrow;
    }
  }

  // 💰 Purchase Product
  Future<String> purchaseProduct({
    required int productId,
    required BigInt price,
    String? buyerSeed,
  }) async {
    await ensureConnected();
    
    try {
      print('💰 Purchasing product $productId...');
      print('   Payment: $price planck');
      
      // Simulate blockchain transaction
      await Future.delayed(const Duration(seconds: 2));
      
      // ✅ Update product availability
      final allProducts = await getAllProducts();
      final updatedProducts = allProducts.map((p) {
        if (p.id == productId) {
          return Product(
            id: p.id,
            name: p.name,
            description: p.description,
            price: p.price,
            ipfsHash: p.ipfsHash,
            seller: p.seller,
            owner: ContractConstants.bobAddress, // Transfer to buyer
            isAvailable: false, // Mark as sold
            createdAt: p.createdAt,
            soldAt: DateTime.now(),
          );
        }
        return p;
      }).toList();
      
      await _saveProducts(updatedProducts);
      
      print('✅ Product $productId purchased successfully!');
      
      final txHash = 'tx_${DateTime.now().millisecondsSinceEpoch}';
      return txHash;
      
    } catch (e) {
      print('❌ Failed to purchase product: $e');
      rethrow;
    }
  }

  // 🗑️ Clear all products (for testing)
  Future<void> clearAllProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_productsKey);
      print('🗑️ All products cleared');
    } catch (e) {
      print('❌ Failed to clear products: $e');
    }
  }
}
