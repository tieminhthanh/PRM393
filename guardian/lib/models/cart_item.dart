import 'product.dart';

class CartItem {
  final String cartItemId;
  final String cartId;
  final String productId;
  final double quantity;
  final Product? product;

  CartItem({
    required this.cartItemId,
    required this.cartId,
    required this.productId,
    required this.quantity,
    this.product,
  });

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      cartItemId: map['CartItemId'] ?? '',
      cartId: map['CartId'] ?? '',
      productId: map['ProductId'] ?? '',
      quantity: (map['Quantity'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'CartItemId': cartItemId,
      'CartId': cartId,
      'ProductId': productId,
      'Quantity': quantity,
    };
  }

  double get totalPrice => (product?.price ?? 0) * quantity;
}
