class Product {
  final String productId;
  final String sellerId;
  final String title;
  final String description;
  final String category;
  final double price;
  final String unit;
  final String? imageUrl;
  final DateTime createdAt;

  Product({
    required this.productId,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.unit,
    this.imageUrl,
    required this.createdAt,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      productId: map['ProductId'] ?? '',
      sellerId: map['SellerId'] ?? '',
      title: map['Title'] ?? '',
      description: map['Description'] ?? '',
      category: map['Category'] ?? '',
      price: (map['Price'] ?? 0.0).toDouble(),
      unit: map['Unit'] ?? 'Kg',
      imageUrl: map['ImageUrl'],
      createdAt: DateTime.parse(map['CreatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ProductId': productId,
      'SellerId': sellerId,
      'Title': title,
      'Description': description,
      'Category': category,
      'Price': price,
      'Unit': unit,
      'CreatedAt': createdAt.toIso8601String(),
    };
  }
}
