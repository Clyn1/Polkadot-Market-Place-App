// lib/models/product.dart
class Product {
  final int id;
  final String name;
  final String description;
  final BigInt price;
  final String ipfsHash;
  final String seller;
  final String owner;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime? soldAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.ipfsHash,
    required this.seller,
    required this.owner,
    required this.isAvailable,
    required this.createdAt,
    this.soldAt,
  });

  // ✅ FROM JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: BigInt.parse(json['price'].toString()),
      ipfsHash: json['ipfs_hash'] as String? ?? json['ipfsHash'] as String? ?? '',
      seller: json['seller'] as String,
      owner: json['owner'] as String,
      isAvailable: json['is_available'] as bool? ?? json['isAvailable'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String? ?? json['createdAt'] as String),
      soldAt: json['sold_at'] != null 
          ? DateTime.parse(json['sold_at'] as String)
          : null,
    );
  }

  // ✅ TO JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price.toString(),
      'ipfs_hash': ipfsHash,
      'ipfsHash': ipfsHash,
      'seller': seller,
      'owner': owner,
      'is_available': isAvailable,
      'isAvailable': isAvailable,
      'created_at': createdAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'sold_at': soldAt?.toIso8601String(),
    };
  }

  // ✅ FORMATTED PRICE IN DOT
  String get priceInDot {
    final dotDecimals = BigInt.from(1000000000000);
    final wholeDot = price ~/ dotDecimals;
    final fraction = price % dotDecimals;
    
    if (fraction == BigInt.zero) {
      return wholeDot.toString();
    }
    
    final fractionalPart = (fraction * BigInt.from(100) ~/ dotDecimals);
    return '$wholeDot.${fractionalPart.toString().padLeft(2, '0')}';
  }

  // ✅ DISPLAY PRICE FOR UI
  String get displayPrice {
    return '$priceInDot DOT';
  }

  // ✅ SHORTENED OWNER ADDRESS
  String get shortOwner {
    if (owner.length <= 10) return owner;
    return '${owner.substring(0, 6)}...${owner.substring(owner.length - 4)}';
  }

  // ✅ SHORTENED SELLER ADDRESS
  String get shortSeller {
    if (seller.length <= 10) return seller;
    return '${seller.substring(0, 6)}...${seller.substring(seller.length - 4)}';
  }

  // ✅ IMAGE URL FROM IPFS
  String? get imageUrl => ipfsHash.isNotEmpty && ipfsHash != 'QmDefaultHash'
      ? 'https://gateway.pinata.cloud/ipfs/$ipfsHash' 
      : null;

  // ✅ SAFE IMAGE URL with better fallback
  String get safeImageUrl {
    if (ipfsHash.isEmpty || ipfsHash == 'QmDefaultHash') {
      return 'https://via.placeholder.com/400x300/9C27B0/FFFFFF?text=${Uri.encodeComponent(name)}';
    }
    
    // Try Pinata gateway first
    return 'https://gateway.pinata.cloud/ipfs/$ipfsHash';
  }
  
  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $priceInDot DOT)';
  }
}
