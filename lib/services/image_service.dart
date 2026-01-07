import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Image Service for IPFS Upload
/// Handles uploading images to IPFS (decentralized storage)
class ImageService {
  // Use a public IPFS gateway for testing
  static const String _ipfsGateway = 'https://ipfs.io/ipfs/';
  static const String _uploadEndpoint = 'https://api.pinata.cloud/pinning/pinFileToIPFS';
  
  // Get your free API key from https://www.pinata.cloud/
  static const String _pinataApiKey = 'YOUR_PINATA_API_KEY';
  static const String _pinataSecretKey = 'YOUR_PINATA_SECRET_KEY';

  /// Upload image to IPFS
  /// Returns IPFS hash (CID)
  Future<String?> uploadToIPFS(File imageFile) async {
    try {
      // Read file as bytes
      final bytes = await imageFile.readAsBytes();
      
      // For now, mock upload (returns a test IPFS hash)
      await Future.delayed(const Duration(seconds: 2)); // Simulate upload
      
      // Mock IPFS hash (CID)
      return 'QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG';
      
      // REAL IMPLEMENTATION (uncomment when you have Pinata API keys):
      
      final request = http.MultipartRequest('POST', Uri.parse(_uploadEndpoint));
      request.headers['pinata_api_key'] = _pinataApiKey;
      request.headers['pinata_secret_api_key'] = _pinataSecretKey;
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'product_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
      
      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final result = json.decode(String.fromCharCodes(responseData));
      
      if (response.statusCode == 200) {
        return result['IpfsHash'];
      }
      return null;
    
    } catch (e) {
      print('Error uploading to IPFS: $e');
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
    // TODO: Implement unpinning
    return true;
  }
}