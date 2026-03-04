import 'product.dart';

class OrderItem {
  final String orderItemId;
  final String orderId;
  final String productId;
  final double quantity;
  final double price;
  final Product? product;

  OrderItem({
    required this.orderItemId,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.price,
    this.product,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      orderItemId: map['OrderItemId'] ?? '',
      orderId: map['OrderId'] ?? '',
      productId: map['ProductId'] ?? '',
      quantity: (map['Quantity'] ?? 0.0).toDouble(),
      price: (map['Price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'OrderItemId': orderItemId,
      'OrderId': orderId,
      'ProductId': productId,
      'Quantity': quantity,
      'Price': price,
    };
  }

  double get totalPrice => price * quantity;
}
