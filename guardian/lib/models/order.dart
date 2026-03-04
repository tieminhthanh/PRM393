class Order {
  final String orderId;
  final String buyerId;
  final double orderTotal;
  final String status;
  final DateTime createdAt;

  Order({
    required this.orderId,
    required this.buyerId,
    required this.orderTotal,
    required this.status,
    required this.createdAt,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      orderId: map['OrderId'] ?? '',
      buyerId: map['BuyerId'] ?? '',
      orderTotal: (map['OrderTotal'] ?? 0.0).toDouble(),
      status: map['Status'] ?? 'CREATED',
      createdAt: DateTime.parse(map['CreatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'OrderId': orderId,
      'BuyerId': buyerId,
      'OrderTotal': orderTotal,
      'Status': status,
      'CreatedAt': createdAt.toIso8601String(),
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'CREATED':
        return 'Vừa tạo';
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'PROCESSING':
        return 'Đang xử lý';
      case 'SHIPPED':
        return 'Đã gửi';
      case 'DELIVERED':
        return 'Đã giao';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }
}
