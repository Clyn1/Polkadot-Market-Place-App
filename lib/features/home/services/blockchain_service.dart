import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:polkadart/polkadart.dart';
import '../../../models/product.dart';
import '../../../core/constants/contract_constants.dart';

class BlockchainService {
  Provider? _provider;
  bool _isConnected = false;
  bool _isConnecting = false;

  bool get isConnected => _isConnected;

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
      print('🔗 Connecting to Substrate node at ${ContractConstants.wsUrl}...');
      
      _provider = Provider.fromUri(Uri.parse(ContractConstants.wsUrl));
      await _provider!.connect();
      
      _isConnected = true;
      print('✅ Successfully connected to blockchain');
      
    } catch (e) {
      // Handle "Already connected" error gracefully
      if (e.toString().contains('Already connected')) {
        print('⚠️ Already connected to blockchain');
        _isConnected = true;
      } else {
        _isConnected = false;
        print('❌ Failed to connect to blockchain: $e');
        _provider = null;
      }
    } finally {
      _isConnecting = false;
    }
  }

  Future<List<Product>> getAllProducts() async {
    await ensureConnected();

    try {
      print('📋 Fetching products from blockchain...');
      
      await Future.delayed(const Duration(seconds: 2));
      
      // Use REAL IPFS hashes from your Pinata uploads
      final List<Product> mockProducts = [
        Product(
          id: 1,
          name: 'Organic Mangoes',
          description: 'Fresh organic mangoes from Kisumu farms',
          price: BigInt.from(100000000000), // 0.1 DOT
          ipfsHash: 'QmUNyjtUTFMq1PjQadUz3VsJfTcXeqUmfx5ySKSgoXEGt7', // Your uploaded image!
          seller: ContractConstants.aliceAddress,
          owner: ContractConstants.aliceAddress,
          isAvailable: true,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          soldAt: null,
        ),
        Product(
          id: 2,
          name: 'Casio Watch',
          description: 'Best metal Casio Watch',
          price: BigInt.from(1000000000000), // 1.0 DOT
          ipfsHash: 'QmTestHash234567890abcdef', // Use your real IPFS hash
          seller: ContractConstants.aliceAddress,
          owner: ContractConstants.aliceAddress,
          isAvailable: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          soldAt: null,
        ),
        Product(
          id: 3,
          name: 'Coffee Beans',
          description: 'Premium arabica coffee from Nyeri',
          price: BigInt.from(50000000000), // 0.05 DOT
          ipfsHash: 'QmCoffeeHash987654321xyz', // Use your real IPFS hash
          seller: ContractConstants.bobAddress,
          owner: ContractConstants.bobAddress,
          isAvailable: true,
          createdAt: DateTime.now(),
          soldAt: null,
        ),
      ];
      
      print('✅ Found ${mockProducts.length} products');
      return mockProducts;
      
    } catch (e) {
      print('❌ Failed to fetch products: $e');
      return [];
    }
  }

  Future<Product?> getProduct(int productId) async {
    await ensureConnected();
    
    try {
      print('🔍 Querying product ID: $productId');
      
      if (productId == 1) {
        return Product(
          id: 1,
          name: 'Organic Mangoes',
          description: 'Fresh organic mangoes from Kisumu farms',
          price: BigInt.from(100000000000),
          ipfsHash: 'QmUNyjtUTFMq1PjQadUz3VsJfTcXeqUmfx5ySKSgoXEGt7', // Your uploaded image
          seller: ContractConstants.aliceAddress,
          owner: ContractConstants.aliceAddress,
          isAvailable: true,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          soldAt: null,
        );
      }
      
      return null;
    } catch (e) {
      print('❌ Failed to get product $productId: $e');
      return null;
    }
  }

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
      print('   Price: $price');
      print('   IPFS Hash: $ipfsHash');
      
      await Future.delayed(const Duration(seconds: 3));
      print('✅ Product "$name" listed successfully (mock)');
      
      return 'tx_${DateTime.now().millisecondsSinceEpoch}';
      
    } catch (e) {
      print('❌ Failed to list product: $e');
      rethrow;
    }
  }

  Future<String> buyProduct({
    required int productId,
    required BigInt paymentAmount,
    String? signerSeed,
  }) async {
    await ensureConnected();
    
    try {
      print('🛒 Purchasing product from blockchain...');
      print('   Product ID: $productId');
      print('   Payment: $paymentAmount');
      
      await Future.delayed(const Duration(seconds: 3));
      print('✅ Product $productId purchased successfully (mock)');
      
      return 'tx_${DateTime.now().millisecondsSinceEpoch}';
      
    } catch (e) {
      print('❌ Failed to purchase product: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_provider != null) {
      try {
        await _provider!.disconnect();
        _isConnected = false;
        print('🔌 Disconnected from blockchain');
      } catch (e) {
        print('⚠️ Error during disconnect: $e');
      } finally {
        _provider = null;
      }
    }
  }

  Future<void> ensureConnected() async {
    if (!_isConnected) {
      await connect();
    }
  }
}
