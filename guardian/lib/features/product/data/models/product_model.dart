import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    super.id,
    required super.sellerId,
    required super.title,
    super.description,
    super.category,
    required super.price,
    super.unit,
    super.createdAt,
    super.sellerName,
    super.imageUrl,
  });

  // Chuyển đổi dữ liệu từ SQLite (Map) sang Object
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['ProductId'] as int?,
      sellerId: map['SellerId'] as int,
      title: map['Title'] as String,
      description: map['Description'] as String?,
      category: map['Category'] as String?,
      price: (map['Price'] as num).toDouble(),
      unit: map['Unit'] as String?,
      createdAt: map['CreatedAt'] as String?,
      // Lấy từ hàm getProductsWithSeller() trong database_helper
      sellerName: map['SellerName'] as String?, 
      // Lấy từ bảng Images nếu có JOIN
      imageUrl: map['ImageUrl'] as String?, 
    );
  }

  // Chuyển đổi Object sang Map để Insert/Update vào SQLite
  Map<String, dynamic> toMap() {
    return {
      'ProductId': id,
      'SellerId': sellerId,
      'Title': title,
      'Description': description,
      'Category': category,
      'Price': price,
      'Unit': unit,
      // Không map sellerName và imageUrl vì chúng không nằm trong bảng commerce_Products
    }..removeWhere((key, value) => value == null); // Loại bỏ null để SQLite tự dùng default
  }
}