import 'dart:convert';
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
    // Prevent multiple simultaneous connection attempts
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
      
      // Create new provider instance
      _provider = Provider.fromUri(Uri.parse(ContractConstants.wsUrl));
      
      // Set a timeout for connection
      final connectionFuture = _provider!.connect();
      final timeoutFuture = Future.delayed(const Duration(seconds: 10));
      
      final result = await Future.any([connectionFuture, timeoutFuture]);
      
      if (result == timeoutFuture) {
        throw TimeoutException('Connection timeout after 10 seconds');
      }
      
      _isConnected = true;
      print('✅ Successfully connected to blockchain');
      
    } on TimeoutException catch (e) {
      _isConnected = false;
      print('⏰ Connection timeout: ${ContractConstants.wsUrl}');
      print('   Make sure your Substrate node is running');
      rethrow;
      
    } catch (e) {
      _isConnected = false;
      
      // Handle "Already connected" gracefully
      if (e.toString().contains('Already connected')) {
        print('⚠️ Connection already established');
        _isConnected = true; // Assume we're connected
      } else if (e.toString().contains('Connection refused')) {
        print('❌ Connection refused: ${ContractConstants.wsUrl}');
        print('   Please start your Substrate node:');
        print('   ./target/release/node-template --dev --ws-external');
      } else if (e.toString().contains('WebSocket')) {
        print('❌ WebSocket error: $e');
        print('   Check if node is running and WS port is open');
      } else {
        print('❌ Failed to connect to blockchain: $e');
      }
      
      // Don't rethrow for connection errors, just mark as disconnected
      _provider = null;
      
    } finally {
      _isConnecting = false;
    }
  }

  Future<List<Product>> getAllProducts() async {
    await ensureConnected();

    try {
      print('📋 Fetching products from blockchain...');
      
      await Future.delayed(const Duration(seconds: 2));
      
      final List<Product> mockProducts = [
        Product(
          id: 1,
          name: 'Organic Mangoes',
          description: 'Fresh organic mangoes from Kisumu farms',
          price: BigInt.from(100000000000),
          ipfsHash: 'QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG',
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
          price: BigInt.from(1000000000000),
          ipfsHash: 'QmTestHash234567890abcdef',
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
          price: BigInt.from(50000000000),
          ipfsHash: 'QmCoffeeHash987654321xyz',
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
          ipfsHash: 'QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG',
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
    
    await Future.delayed(const Duration(seconds: 3));
    print('✅ Product "$name" listed successfully (mock)');
    return 'tx_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<String> buyProduct({
    required int productId,
    required BigInt paymentAmount,
    String? signerSeed,
  }) async {
    await ensureConnected();
    
    await Future.delayed(const Duration(seconds: 3));
    print('✅ Product $productId purchased successfully (mock)');
    return 'tx_${DateTime.now().millisecondsSinceEpoch}';
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

  /// Ensures connection is established before operations
  Future<void> ensureConnected() async {
    if (!_isConnected) {
      await connect();
    }
  }

  /// Old method kept for compatibility
  void _ensureConnected() {
    if (!_isConnected) {
      throw Exception('Not connected to blockchain. Call connect() first.');
    }
  }
}
