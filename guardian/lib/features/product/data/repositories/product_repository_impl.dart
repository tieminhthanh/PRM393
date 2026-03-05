import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasource/product_local_datasource.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductLocalDataSource localDataSource;

  ProductRepositoryImpl(this.localDataSource);

  @override
  Future<List<Product>> getProducts() async {
    return await localDataSource.getProducts();
  }

  @override
  Future<List<String>> getProductImages(int productId) async {
    return await localDataSource.getProductImages(productId);
  }

  @override
  Future<Product?> getProductById(int id) async {
    return await localDataSource.getProductById(id);
  }

  @override
  Future<void> createProduct(Product product) async {
    final model = ProductModel(
      sellerId: product.sellerId,
      title: product.title,
      description: product.description,
      category: product.category,
      price: product.price,
      unit: product.unit,
    );
    await localDataSource.insertProduct(model);
  }

  @override
  Future<void> updateProduct(Product product) async {
    // Chuyển đổi tương tự createProduct và gọi update
    final model = ProductModel(
      id: product.id,
      sellerId: product.sellerId,
      title: product.title,
      description: product.description,
      category: product.category,
      price: product.price,
      unit: product.unit,
    );
    await localDataSource.updateProduct(model);
  }

  @override
  Future<void> deleteProduct(int id) async {
    await localDataSource.deleteProduct(id);
  }
}
