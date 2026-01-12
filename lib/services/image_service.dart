import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Image Service - Uploads through YOUR backend (not directly to Pinata)
class ImageService {
  static const String backendUrl = 'http://127.0.0.1:8080/api/upload';

  Future<String?> uploadToIPFS(File imageFile) async {
    try {
      debugPrint('📤 Uploading to backend...');
      
      final bytes = await imageFile.readAsBytes();
      final filename = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final request = http.MultipartRequest('POST', Uri.parse(backendUrl));
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );
      
      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      
      debugPrint('📥 Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final result = json.decode(responseString);
        if (result['success'] == true && result['data'] != null) {
          return result['data']['ipfs_hash'] as String;
        }
      }
      
      debugPrint('❌ Failed: $responseString');
      return null;
    } catch (e) {
      debugPrint('❌ Error: $e');
      return null;
    }
  }

  String getIPFSUrl(String hash) {
    return 'https://gateway.pinata.cloud/ipfs/$hash';
  }

  Future<String?> uploadImageAndGetUrl(File imageFile) async {
    final hash = await uploadToIPFS(imageFile);
    if (hash != null) {
      return getIPFSUrl(hash);
    }
    return null;
  }
}
