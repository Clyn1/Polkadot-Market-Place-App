import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Image Service for IPFS Upload
/// Handles uploading images to IPFS (decentralized storage)
class ImageService {
  // IPFS gateway for viewing images
  static const String _ipfsGateway = 'https://gateway.pinata.cloud/ipfs/';
  static const String _uploadEndpoint = 'https://api.pinata.cloud/pinning/pinFileToIPFS';
  
  // Load from environment or use these as fallback
  final String _pinataApiKey;
  final String _pinataSecretKey;

  ImageService({
    String? apiKey,
    String? secretKey,
  }) : _pinataApiKey = apiKey ?? const String.fromEnvironment('PINATA_API_KEY', defaultValue: ''),
       _pinataSecretKey = secretKey ?? const String.fromEnvironment('PINATA_SECRET_KEY', defaultValue: '');

  /// Upload image to IPFS via Pinata
  /// Returns IPFS hash (CID)
  Future<String?> uploadToIPFS(File imageFile) async {
    try {
      // Validate API keys
      if (_pinataApiKey.isEmpty || _pinataSecretKey.isEmpty) {
        debugPrint('⚠️  Pinata API keys not set! Using mock upload.');
        // Mock upload for testing
        await Future.delayed(const Duration(seconds: 2));
        return 'QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG';
      }

      debugPrint('📤 Uploading image to IPFS...');
      
      // Read file as bytes
      final bytes = await imageFile.readAsBytes();
      final filename = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(_uploadEndpoint));
      request.headers['pinata_api_key'] = _pinataApiKey;
      request.headers['pinata_secret_api_key'] = _pinataSecretKey;
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );
      
      // Send request
      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      
      debugPrint('📥 Pinata response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final result = json.decode(responseString);
        final ipfsHash = result['IpfsHash'] as String;
        
        debugPrint('✅ Upload successful! IPFS Hash: $ipfsHash');
        return ipfsHash;
      } else {
        debugPrint('❌ Upload failed: ${response.statusCode}');
        debugPrint('Response: $responseString');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error uploading to IPFS: $e');
      return null;
    }
  }

  /// Get full IPFS URL from hash
  String getIPFSUrl(String hash) {
    return '$_ipfsGateway$hash';
  }

  /// Upload image and return full URL
  Future<String?> uploadImageAndGetUrl(File imageFile) async {
    final hash = await uploadToIPFS(imageFile);
    if (hash != null) {
      return getIPFSUrl(hash);
    }
    return null;
  }

  /// Delete/unpin from IPFS (for cleanup)
  Future<bool> unpinFromIPFS(String hash) async {
    try {
      if (_pinataApiKey.isEmpty || _pinataSecretKey.isEmpty) {
        return false;
      }

      final response = await http.delete(
        Uri.parse('https://api.pinata.cloud/pinning/unpin/$hash'),
        headers: {
          'pinata_api_key': _pinataApiKey,
          'pinata_secret_api_key': _pinataSecretKey,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error unpinning from IPFS: $e');
      return false;
    }
  }
}
