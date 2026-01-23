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

  factory Product.fromBlockchain(Map<String, dynamic> data) {
    return Product(
      id: data['id'] as int,
      name: data['name'] as String,
      description: data['description'] as String,
      price: BigInt.parse(data['price'].toString()),
      ipfsHash: data['ipfs_hash'] as String,
      seller: data['seller'] as String,
      owner: data['owner'] as String,
      isAvailable: data['is_available'] as bool,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        data['created_at'] as int,
      ),
      soldAt: data['sold_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['sold_at'] as int)
          : null,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: json['price'] is BigInt 
          ? json['price'] as BigInt
          : BigInt.from((json['price'] as num).toInt()),
      ipfsHash: json['ipfs_hash'] as String? ?? json['image_url'] as String? ?? '',
      seller: json['owner'] as String? ?? json['seller'] as String? ?? '',
      owner: json['owner'] as String,
      isAvailable: json['is_available'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      soldAt: json['sold_at'] != null
          ? DateTime.parse(json['sold_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'name': name,
      'description': description,
      'price': priceInDot,
      'ipfs_hash': ipfsHash,
      'image_url': ipfsHash,
      'seller': seller,
      'owner': owner,
      'is_available': isAvailable,
      'created_at': createdAt.toIso8601String(),
      'sold_at': soldAt?.toIso8601String(),
    };
  }

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

  String? get imageUrl => ipfsHash.isNotEmpty ? ipfsHash : null;
  
  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $priceInDot DOT)';
  }
}