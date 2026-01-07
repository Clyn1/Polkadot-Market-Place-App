import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product.dart';
import 'dart:io';

/// API Service to communicate with Rust backend
class ApiService {
  // Change this to your backend URL
  // For local development: http://127.0.0.1:8080
  // For production: your deployed backend URL
  static const String baseUrl = 'http://127.0.0.1:8080/api';

  /// Get all products from backend
  Future<List<Product>> getAllProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        // Backend returns: { "success": true, "data": [...] }
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final List<dynamic> productsJson = jsonData['data'];
          return productsJson.map((json) => Product.fromJson(json)).toList();
        }
        
        return [];
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching products: $e');
      rethrow;
    }
  }

  /// Get a single product by ID
  Future<Product?> getProductById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return Product.fromJson(jsonData['data']);
        }
      }
      
      return null;
    } catch (e) {
      print('Error fetching product: $e');
      return null;
    }
  }

  /// Create a new product
  Future<Product?> createProduct({
    required String name,
    required double price,
    required String owner,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'price': price,
          'owner': owner,
          'description': description,
          'image_url': imageUrl,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['success'] == true && jsonData['data'] != null) {
          print('Product created successfully: ${jsonData['message']}');
          return Product.fromJson(jsonData['data']);
        }
      } else {
        print('Failed to create product: ${response.statusCode}');
        print('Response: ${response.body}');
      }
      
      return null;
    } catch (e) {
      print('Error creating product: $e');
      return null;
    }
  }

  /// Update a product
  Future<Product?> updateProduct({
    required String id,
    String? name,
    double? price,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (price != null) body['price'] = price;
      if (description != null) body['description'] = description;
      if (imageUrl != null) body['image_url'] = imageUrl;

      final response = await http.put(
        Uri.parse('$baseUrl/products/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return Product.fromJson(jsonData['data']);
        }
      }
      
      return null;
    } catch (e) {
      print('Error updating product: $e');
      return null;
    }
  }

  /// Delete a product
  Future<bool> deleteProduct(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  /// Search products
  Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/search?q=$query'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final List<dynamic> productsJson = jsonData['data'];
          return productsJson.map((json) => Product.fromJson(json)).toList();
        }
      }
      
      return [];
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  /// Check backend health
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8080/health'),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Backend health check failed: $e');
      return false;
    }
  }
}