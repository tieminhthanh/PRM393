import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/formatter.dart';
import '../../domain/entities/product.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';

// ==========================================
// MÀU SẮC TỪ THIẾT KẾ TAILWIND
// ==========================================
const Color _primaryColor = Color(0xFF0df259);
const Color _forestColor = Color(0xFF104224);
const Color _bgLightColor = Color(0xFFf5f8f6);

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  int _selectedCategoryIndex = 0;
  List<String> _categories = ['Tất cả'];

  @override
  void initState() {
    super.initState();
    // Trigger load sản phẩm từ database
    context.read<ProductBloc>().add(LoadProducts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLightColor,
      body: SafeArea(
        child: BlocListener<ProductBloc, ProductState>(
          listener: (context, state) {
            // Update categories từ dữ liệu khi load thành công
            if (state is ProductLoaded) {
              final categoriesSet = {
                'Tất cả',
                ...state.products.map((p) => p.category).where((c) => c != null).cast<String>()
              };
              setState(() {
                _categories = categoriesSet.toList();
                // Reset category filter khi load lại dữ liệu
                _selectedCategoryIndex = 0;
              });
            }
          },
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed('/product/add').then((_) {
          // Reload products sau khi thêm
          context.read<ProductBloc>().add(LoadProducts());
        }),
        backgroundColor: _primaryColor,
        foregroundColor: _forestColor,
        icon: const Icon(Icons.add),
        label: const Text('Thêm sản phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ==========================================
  // 1. HEADER & TÌM KIẾM
  // ==========================================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: Colors.white.withOpacity(0.9),
      child: Column(
        children: [
          // Row 1: Logo & Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(CupertinoIcons.leaf_arrow_circlepath, color: _forestColor),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Cửa Hàng Xanh',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _forestColor,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.cart, color: Colors.black87),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: _primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '2',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _forestColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.bell, color: Colors.black87),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          // Row 2: Search Bar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.search, color: Colors.grey.shade500),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Tìm nông sản hữu cơ...',
                            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: _forestColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(CupertinoIcons.qrcode_viewfinder, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Row 3: Categories
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final isSelected = _selectedCategoryIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryIndex = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? _primaryColor : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected
                          ? [BoxShadow(color: _primaryColor.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2))]
                          : null,
                    ),
                    child: Text(
                      _categories[index],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? _forestColor : Colors.grey.shade700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. PRODUCT GRID (Tích hợp BLoC)
  // ==========================================
  Widget _buildBody() {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) {
          return const Center(child: CircularProgressIndicator(color: _forestColor));
        }

        if (state is ProductError) {
          return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
        }

        if (state is ProductLoaded) {
          final allProducts = state.products;

          // Filter products theo category được chọn
          final filteredProducts = _selectedCategoryIndex == 0 
              ? allProducts 
              : allProducts.where((p) => p.category == _categories[_selectedCategoryIndex]).toList();

          return RefreshIndicator(
            onRefresh: () async => context.read<ProductBloc>().add(LoadProducts()),
            color: _primaryColor,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sản phẩm nổi bật', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Xem tất cả', style: TextStyle(color: _forestColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65, // Điều chỉnh tỷ lệ khung hình thẻ sản phẩm
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) => _buildProductCard(filteredProducts[index]),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  // ==========================================
  // 3. THIẾT KẾ THẺ SẢN PHẨM (CARD)
  // ==========================================
  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(
        '/product/detail',
        arguments: product,
      ).then((_) {
        // Reload sau khi edit/xóa
        context.read<ProductBloc>().add(LoadProducts());
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hình ảnh & Badge & Menu
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                    image: DecorationImage(
                      image: NetworkImage(product.imageUrl ?? 'https://picsum.photos/seed/${product.id}/400/400'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.verified, color: _primaryColor, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'VERIFIED GREEN',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _forestColor),
                        ),
                      ],
                    ),
                  ),
                ),
                // Quick actions menu (top right)
                Positioned(
                  top: 8,
                  right: 8,
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.of(context).pushNamed(
                          '/product/edit',
                          arguments: product,
                        ).then((_) {
                          context.read<ProductBloc>().add(LoadProducts());
                        });
                      } else if (value == 'delete') {
                        _showDeleteConfirm(context, product.id);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16, color: _forestColor),
                            SizedBox(width: 8),
                            Text('Sửa'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa'),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.more_vert, color: _forestColor, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Thông tin text
          Text(
            product.category ?? 'Nông sản',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 4),
          Text(
            product.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          // Giá & Nút Add
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppFormatter.currency(product.price),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _forestColor),
                  ),
                  if (product.unit != null)
                    Text(
                      '/${product.unit}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                ],
              ),
              Container(
                height: 32,
                width: 32,
                decoration: const BoxDecoration(
                  color: _forestColor,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, int? productId) {
    if (productId == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa sản phẩm này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ProductBloc>().add(DeleteProduct(productId));
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. BOTTOM NAVIGATION TÙY CHỈNH
  // ==========================================
  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(icon: CupertinoIcons.building_2_fill, label: 'Cửa hàng', isSelected: true),
            _buildNavItem(icon: CupertinoIcons.location, label: 'Nguồn gốc'),
            _buildNavItem(icon: CupertinoIcons.heart, label: 'Yêu thích'),
            _buildNavItem(icon: CupertinoIcons.person, label: 'Hồ sơ'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, bool isSelected = false}) {
    final color = isSelected ? _forestColor : Colors.grey.shade400;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}