class Product {
  final String id;
  final String name;
  final double price;
  final String owner;
  final String? description;
  final String? imageUrl;
  final DateTime? createdAt;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.owner,
    this.description,
    this.imageUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert Product to JSON (for future API/blockchain integration)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'owner': owner,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // Create Product from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      owner: json['owner'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  // Create a copy with updated fields
  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? owner,
    String? description,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      owner: owner ?? this.owner,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price DOT, owner: $owner)';
  }
}