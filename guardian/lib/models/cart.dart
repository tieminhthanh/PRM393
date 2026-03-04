import 'cart_item.dart';

class Cart {
  final String cartId;
  final String userId;
  final List<CartItem> items;
  final DateTime updatedAt;

  Cart({
    required this.cartId,
    required this.userId,
    required this.items,
    required this.updatedAt,
  });

  factory Cart.fromMap(Map<String, dynamic> map) {
    return Cart(
      cartId: map['CartId'] ?? '',
      userId: map['UserId'] ?? '',
      items: [],
      updatedAt: DateTime.parse(map['UpdatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'CartId': cartId,
      'UserId': userId,
      'UpdatedAt': updatedAt.toIso8601String(),
    };
  }

  double get totalPrice => items.fold(0, (sum, item) => sum + item.totalPrice);

  int get totalItems => items.length;

  double get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
}
