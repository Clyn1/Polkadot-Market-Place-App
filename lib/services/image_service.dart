import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../env/env.dart';

class ImageService {
  static const String _ipfsGateway = 'https://gateway.pinata.cloud/ipfs/';
  static const String _uploadEndpoint = 'https://api.pinata.cloud/pinning/pinFileToIPFS';
  
  final String _pinataApiKey = Env.pinataApiKey;
  final String _pinataSecretKey = Env.pinataSecretKey;

  Future<String?> uploadToIPFS(File imageFile) async {
    try {
      if (_pinataApiKey.isEmpty || _pinataSecretKey.isEmpty) {
        debugPrint('❌ Pinata API keys are empty!');
        return null;
      }

      debugPrint('📤 Starting IPFS upload...');
      
      final bytes = await imageFile.readAsBytes();
      final filename = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
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
      
      debugPrint('🚀 Sending request to Pinata...');
      
      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      
      debugPrint('📥 Pinata response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final result = json.decode(responseString);
        final ipfsHash = result['IpfsHash'] as String;
        debugPrint('✅ Upload successful! Hash: $ipfsHash');
        return ipfsHash;
      } else {
        debugPrint('❌ Upload failed: $responseString');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error: $e');
      debugPrint('Stack: $stackTrace');
      return null;
    }
  }

  String getIPFSUrl(String hash) {
    return '$_ipfsGateway$hash';
  }

  Future<String?> uploadImageAndGetUrl(File imageFile) async {
    final hash = await uploadToIPFS(imageFile);
    if (hash != null) {
      return getIPFSUrl(hash);
    }
    return null;
  }

  Future<bool> unpinFromIPFS(String hash) async {
    try {
      final response = await http.delete(
        Uri.parse('https://api.pinata.cloud/pinning/unpin/$hash'),
        headers: {
          'pinata_api_key': _pinataApiKey,
          'pinata_secret_api_key': _pinataSecretKey,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error unpinning: $e');
      return false;
    }
  }
}
