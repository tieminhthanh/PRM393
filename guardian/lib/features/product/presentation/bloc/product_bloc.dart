import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/product_repository.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository repository;

  ProductBloc({required this.repository}) : super(ProductInitial()) {
    
    // Xử lý sự kiện Load danh sách sản phẩm
    on<LoadProducts>((event, emit) async {
      emit(ProductLoading());
      try {
        final products = await repository.getProducts();
        emit(ProductLoaded(products));
      } catch (e) {
        emit(ProductError("Không thể tải danh sách sản phẩm: ${e.toString()}"));
      }
    });

    // Xử lý sự kiện thêm sản phẩm mới
    on<AddProduct>((event, emit) async {
      emit(ProductLoading());
      try {
        await repository.createProduct(event.product);
        // Sau khi thêm thành công, load lại danh sách
        add(LoadProducts());
      } catch (e) {
        emit(ProductError("Lỗi khi thêm sản phẩm: ${e.toString()}"));
      }
    });

    // Xử lý sự kiện cập nhật sản phẩm
    on<UpdateProduct>((event, emit) async {
      emit(ProductLoading());
      try {
        await repository.updateProduct(event.product);
        // Sau khi cập nhật thành công, load lại danh sách
        add(LoadProducts());
      } catch (e) {
        emit(ProductError("Lỗi khi cập nhật sản phẩm: ${e.toString()}"));
      }
    });

    // Xử lý sự kiện xóa sản phẩm
    on<DeleteProduct>((event, emit) async {
      emit(ProductLoading());
      try {
        await repository.deleteProduct(event.id);
        add(LoadProducts());
      } catch (e) {
        emit(ProductError("Lỗi khi xóa sản phẩm: ${e.toString()}"));
      }
    });
  }
}