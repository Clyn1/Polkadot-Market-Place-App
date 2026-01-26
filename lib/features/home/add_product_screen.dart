import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../models/product.dart';
import 'services/blockchain_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ownerController = TextEditingController();
  final _blockchainService = BlockchainService();

  File? _selectedImage;
  bool _isUploading = false;
  String? _imageSizeInfo;

  @override
  void initState() {
    super.initState();
    _ownerController.text = '5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _ownerController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      
      // ✅ COMPRESSED IMAGE SETTINGS
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,        // ✅ Reduced from 1920
        maxHeight: 800,       // ✅ Reduced from 1080
        imageQuality: 70,     // ✅ Reduced from 85
      );

      if (image != null) {
        final file = File(image.path);
        final bytes = await file.readAsBytes();
        final sizeKB = (bytes.length / 1024).toStringAsFixed(2);
        final sizeMB = (bytes.length / 1024 / 1024).toStringAsFixed(2);
        
        setState(() {
          _selectedImage = file;
          _imageSizeInfo = bytes.length < 1024 * 1024 
              ? '$sizeKB KB' 
              : '$sizeMB MB';
        });
        
        print('📸 Image selected: ${bytes.length} bytes ($sizeKB KB)');
        
        // ✅ Warn if still too large
        if (bytes.length > 5 * 1024 * 1024) {
          _showSnackBar(
            'Warning: Image is ${sizeMB}MB. Upload may be slow.',
            isError: false,
          );
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      _showSnackBar('Error picking image: $e', isError: true);
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImageToPinata(File imageFile) async {
    try {
      print('📤 Starting upload to Pinata...');
      
      final bytes = await imageFile.readAsBytes();
      final sizeKB = (bytes.length / 1024).toStringAsFixed(2);
      print('📦 File size: $sizeKB KB');
      
      final base64Image = base64Encode(bytes);
      print('🔄 Encoded to base64, length: ${base64Image.length}');
      
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8080/api/upload/image'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'image_base64': base64Image,
          'file_name': imageFile.path.split('/').last,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Upload timeout - image may be too large');
        },
      );
      
      print('📨 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Upload successful! IPFS hash: ${data['ipfs_hash']}');
        return data['ipfs_hash'];
      } else {
        print('❌ Upload failed: ${response.statusCode}');
        print('Response body: ${response.body}');
        
        // Show user-friendly error
        String errorMsg = 'Upload failed (${response.statusCode})';
        if (response.statusCode == 413) {
          errorMsg = 'Image too large. Try a smaller photo.';
        } else if (response.statusCode == 403) {
          errorMsg = 'Pinata API permission error';
        }
        
        _showSnackBar(errorMsg, isError: true);
        return null;
      }
    } catch (e) {
      print('❌ Error uploading to Pinata: $e');
      _showSnackBar('Upload error: ${e.toString()}', isError: true);
      return null;
    }
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true;
    });

    try {
      String ipfsHash = 'QmDefaultHash';
      
      if (_selectedImage != null) {
        print('🚀 Uploading image to IPFS...');
        final uploadedHash = await _uploadImageToPinata(_selectedImage!);
        
        if (uploadedHash != null && uploadedHash.isNotEmpty) {
          ipfsHash = uploadedHash;
          print('✅ Got IPFS hash: $ipfsHash');
        } else {
          throw Exception('Failed to upload image to IPFS');
        }
      } else {
        print('⚠️ No image selected, using default hash');
      }

      print('📝 Listing product on blockchain...');
      
      final priceInSmallestUnit = BigInt.from(
        (double.parse(_priceController.text.trim()) * 1000000000000).toInt(),
      );

      final txHash = await _blockchainService.listProduct(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: priceInSmallestUnit,
        ipfsHash: ipfsHash,
      );

      print('✅ Product listed! TX: $txHash');

      final newProduct = Product(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: priceInSmallestUnit,
        ipfsHash: ipfsHash,
        seller: _ownerController.text.trim(),
        owner: _ownerController.text.trim(),
        isAvailable: true,
        createdAt: DateTime.now(),
      );

      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        Navigator.pop(context, newProduct);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${newProduct.name} listed successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _isUploading = false;
      });
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 5 : 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.purple.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.purple.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Images are compressed and stored on IPFS via Pinata',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              GestureDetector(
                onTap: _isUploading ? null : _showImageSourceDialog,
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to add product image',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Max 800x800, compressed automatically',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _selectedImage!,
                                width: double.infinity,
                                height: 250,
                                fit: BoxFit.cover,
                              ),
                            ),
                            // Image size badge
                            if (_imageSizeInfo != null)
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _imageSizeInfo!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            // Close button
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedImage = null;
                                      _imageSizeInfo = null;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  hintText: 'Enter product name',
                  prefixIcon: const Icon(Icons.shopping_bag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) => value?.trim().isEmpty ?? true 
                    ? 'Please enter a product name' 
                    : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price (DOT)',
                  hintText: 'Enter price in DOT',
                  prefixIcon: const Icon(Icons.currency_bitcoin),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  final num = double.tryParse(value);
                  if (num == null || num <= 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Enter product description',
                  prefixIcon: const Icon(Icons.description),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _ownerController,
                decoration: InputDecoration(
                  labelText: 'Owner Wallet Address',
                  hintText: 'Polkadot address',
                  prefixIcon: const Icon(Icons.account_balance_wallet),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a wallet address';
                  }
                  if (value.length < 20) {
                    return 'Invalid Polkadot address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isUploading ? null : _submitProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isUploading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Uploading to IPFS...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'List Product on Blockchain',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: 16),

              Text(
                'Note: Images are automatically compressed to 800x800 at 70% quality. '
                'Image will be uploaded to IPFS via Pinata. '
                'Product will be listed on the Polkadot blockchain.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
