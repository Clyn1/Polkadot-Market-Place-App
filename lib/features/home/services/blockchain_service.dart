// lib/features/home/services/blockchain_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:polkadart/polkadart.dart';
import '../../../models/product.dart';

class BlockchainService {
  Provider? _provider;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) {
      print('✅ Already connected to blockchain');
      return;
    }

    try {
      const wsUrl = 'wss://rpc.polkadot.io';
      print('🔗 Connecting to Substrate node at $wsUrl...');
      
      _provider = Provider.fromUri(Uri.parse(wsUrl));
      await _provider!.connect();
      
      _isConnected = true;
      print('✅ Successfully connected to blockchain');
    } catch (e) {
      _isConnected = false;
      print('❌ Failed to connect to blockchain: $e');
      rethrow;
    }
  }

  Future<List<Product>> getAllProducts() async {
    _ensureConnected();

    try {
      print('📋 Fetching products from blockchain...');
      
      await Future.delayed(const Duration(seconds: 2));
      
      // Create Product objects with correct constructor parameters
      final List<Product> mockProducts = [
        Product(
          id: 1,  // int, not String
          name: 'Blockchain Guide',
          description: 'Learn blockchain fundamentals',
          price: BigInt.from(29990000000000),  // BigInt for 29.99 DOT (12 decimals)
          ipfsHash: 'https://picsum.photos/200',  // Use ipfsHash instead of imageUrl
          seller: '5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY',
          owner: '5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY',
          isAvailable: true,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          soldAt: null,
        ),
        Product(
          id: 2,
          name: 'Crypto Wallet',
          description: 'Secure hardware wallet',
          price: BigInt.from(129990000000000),  // 129.99 DOT
          ipfsHash: 'https://picsum.photos/201',
          seller: '5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty',
          owner: '5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty',
          isAvailable: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
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
    _ensureConnected();
    
    try {
      print('🔍 Querying product ID: $productId');
      
      // Return mock product if ID is 1
      if (productId == 1) {
        return Product(
          id: 1,
          name: 'Blockchain Guide',
          description: 'Learn blockchain fundamentals',
          price: BigInt.from(29990000000000),
          ipfsHash: 'https://picsum.photos/200',
          seller: '5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY',
          owner: '5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY',
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
    _ensureConnected();
    
    // Simulate successful listing
    await Future.delayed(const Duration(seconds: 3));
    print('✅ Product "$name" listed successfully (mock)');
    return 'tx_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<String> buyProduct({
    required int productId,
    required BigInt paymentAmount,
    String? signerSeed,
  }) async {
    _ensureConnected();
    
    // Simulate successful purchase
    await Future.delayed(const Duration(seconds: 3));
    print('✅ Product $productId purchased successfully (mock)');
    return 'tx_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> disconnect() async {
    if (_provider != null && _isConnected) {
      try {
        await _provider!.disconnect();
        _isConnected = false;
        print('🔌 Disconnected from blockchain');
      } catch (e) {
        print('⚠️ Error during disconnect: $e');
      }
    }
  }

  void _ensureConnected() {
    if (!_isConnected) {
      throw Exception('Not connected to blockchain. Call connect() first.');
    }
  }
}               