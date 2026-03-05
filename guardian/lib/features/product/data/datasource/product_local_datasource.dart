import '../../../../core/database/database_helper.dart';
import '../models/product_model.dart';

abstract class ProductLocalDataSource {
  Future<List<ProductModel>> getProducts();
  Future<ProductModel?> getProductById(int id);
  Future<List<String>> getProductImages(int productId);
  Future<void> insertProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(int id);
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final DatabaseService dbService;
  final DomainQueries domainQueries;

  ProductLocalDataSourceImpl(this.dbService, this.domainQueries);

  @override
  Future<List<ProductModel>> getProducts() async {
    // Tận dụng hàm bạn đã viết sẵn trong DomainQueries
    final result = await domainQueries.getProductsWithSeller();

    // Nếu muốn lấy thêm ảnh chính, bạn có thể map thêm logic gọi dbService.getPrimaryImage() ở đây
    return result.map((map) => ProductModel.fromMap(map)).toList();
  }

  @override
  Future<List<String>> getProductImages(int productId) async {
    final result = await domainQueries.getProductImages(productId);
    return result
        .map((record) => record['ImageUrl'] as String)
        .toList();
  }

  @override
  Future<ProductModel?> getProductById(int id) async {
    final result = await dbService.queryById(
      'commerce_Products',
      'ProductId',
      id,
    );
    if (result != null) {
      return ProductModel.fromMap(result);
    }
    return null;
  }

  @override
  Future<void> insertProduct(ProductModel product) async {
    await dbService.insert('commerce_Products', product.toMap());
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    await dbService.update(
      'commerce_Products',
      product.toMap(),
      where: 'ProductId = ?',
      whereArgs: [product.id],
    );
  }

  @override
  Future<void> deleteProduct(int id) async {
    await dbService.delete(
      'commerce_Products',
      where: 'ProductId = ?',
      whereArgs: [id],
    );
  }
}
