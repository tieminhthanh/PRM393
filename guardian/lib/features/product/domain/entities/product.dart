class Product {
  final int? id;
  final int sellerId;
  final String title;
  final String? description;
  final String? category;
  final double price;
  final String? unit;
  final String? createdAt;

  // Các trường mở rộng để hiển thị UI (lấy từ phép JOIN)
  final String? sellerName;
  final String? imageUrl;

  const Product({
    this.id,
    required this.sellerId,
    required this.title,
    this.description,
    this.category,
    required this.price,
    this.unit,
    this.createdAt,
    this.sellerName,
    this.imageUrl,
  });
}
