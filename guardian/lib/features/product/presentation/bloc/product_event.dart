// Import trực tiếp Entity từ tầng Domain
import 'package:guardian/features/product/domain/entities/product.dart';

abstract class ProductEvent {}

class LoadProducts extends ProductEvent {}

class AddProduct extends ProductEvent {
  // Giữ nguyên là Product (Entity)
  final Product product;
  AddProduct(this.product);
}

class UpdateProduct extends ProductEvent {
  final Product product;
  UpdateProduct(this.product);
}

class DeleteProduct extends ProductEvent {
  final int id;
  DeleteProduct(this.id);
}