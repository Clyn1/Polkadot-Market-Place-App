import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';     // ← Added for backend call
import '../../services/image_service.dart';    // For IPFS upload

// At the top of _AddProductScreenState
final _imageService = ImageService();

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

  // Services
  final _imageService = ImageService();
  final _apiService = ApiService(); // ← New: for communicating with Rust backend

  File? _selectedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with your test wallet address
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
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
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

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // Step 1: Upload image to IPFS (if selected)
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _imageService.uploadImageAndGetUrl(_selectedImage!);
        if (imageUrl == null) {
          throw Exception('Failed to upload image to IPFS');
        }
      }

      // Step 2: Create product on the Rust backend
      final newProduct = await _apiService.createProduct(
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        owner: _ownerController.text.trim(),
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text.trim(),
        imageUrl: imageUrl,
      );

      setState(() {
        _isUploading = false;
      });

      if (newProduct != null) {
        // Return the product created by the backend to HomeScreen
        Navigator.pop(context, newProduct);

        _showSnackBar('${newProduct.name} listed successfully!');
      } else {
        throw Exception('Server did not return a valid product');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
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
              // Info Card
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
                          'Image will be stored on IPFS (decentralized storage)',
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

              // Image Upload Section
              // Image Upload Section
GestureDetector(
  onTap: _isUploading ? null : _showImageSourceDialog,
  child: Container(
    height: 250,  // ✅ Fixed height
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
                'Image will be stored on IPFS',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          )
        : Stack(
            children: [
              // ✅ Image fits properly now
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.contain,  // ✅ Shows full image without cropping
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
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
  ),
),

              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  hintText: 'Enter product name',
                  prefixIcon: const Icon(Icons.shopping_bag),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) => value?.trim().isEmpty ?? true ? 'Please enter a product name' : null,
              ),

              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price (DOT)',
                  hintText: 'Enter price in DOT',
                  prefixIcon: const Icon(Icons.currency_bitcoin),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a price';
                  final num = double.tryParse(value);
                  if (num == null || num <= 0) return 'Please enter a valid positive number';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Enter product description',
                  prefixIcon: const Icon(Icons.description),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),

              const SizedBox(height: 16),

              // Owner Address
              TextFormField(
                controller: _ownerController,
                decoration: InputDecoration(
                  labelText: 'Owner Wallet Address',
                  hintText: 'Polkadot address',
                  prefixIcon: const Icon(Icons.account_balance_wallet),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter a wallet address';
                  if (value.length < 20) return 'Invalid Polkadot address';
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isUploading ? null : _submitProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isUploading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          ),
                          SizedBox(width: 12),
                          Text('Uploading...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      )
                    : const Text('Create Product Listing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 16),

              // Info Text
              Text(
                'Note: Image will be uploaded to IPFS (decentralized storage). '
                'In blockchain version, this will require wallet signature and gas fees.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}