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
      
      // Get the file bytes
      final bytes = await imageFile.readAsBytes();
      final filename = imageFile.path.split('/').last;
      
      // Determine content type from extension
      String contentType = 'image/jpeg';
      if (filename.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      } else if (filename.toLowerCase().endsWith('.jpg') || 
                 filename.toLowerCase().endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      } else if (filename.toLowerCase().endsWith('.gif')) {
        contentType = 'image/gif';
      } else if (filename.toLowerCase().endsWith('.webp')) {
        contentType = 'image/webp';
      }
      
      debugPrint('📄 File: $filename, Size: ${bytes.length} bytes, Type: $contentType');
      
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(backendUrl));
      
      // Add file with proper content type
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: http.MediaType.parse(contentType),
        ),
      );
      
      // Send request
      debugPrint('🚀 Sending request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      debugPrint('📥 Response: ${response.statusCode}');
      debugPrint('📥 Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true && result['data'] != null) {
          final ipfsHash = result['data']['ipfs_hash'] as String;
          debugPrint('✅ Upload successful: $ipfsHash');
          return ipfsHash;
        }
      }
      
      debugPrint('❌ Failed: ${response.body}');
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ Error: $e');
      debugPrint('Stack trace: $stackTrace');
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
;