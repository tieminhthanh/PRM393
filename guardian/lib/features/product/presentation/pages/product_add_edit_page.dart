import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/product.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';

class ProductAddEditPage extends StatefulWidget {
  final Product? product;

  const ProductAddEditPage({
    super.key,
    this.product,
  });

  @override
  State<ProductAddEditPage> createState() => _ProductAddEditPageState();
}

class _ProductAddEditPageState extends State<ProductAddEditPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _unitController;
  late TextEditingController _sellerIdController;
  late TextEditingController _categoryController;

  final List<String> _categories = [
    'Nông sản',
    'Trái cây',
    'Vật tư',
    'Gia vị',
    'Ngũ cốc',
    'Khác',
  ];

  String? _selectedCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.product?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.product?.description ?? '',
    );
    _priceController = TextEditingController(
      text: widget.product?.price.toString() ?? '',
    );
    _unitController = TextEditingController(text: widget.product?.unit ?? 'kg');
    _sellerIdController = TextEditingController(
      text: widget.product?.sellerId.toString() ?? '1',
    );
    _categoryController = TextEditingController(
      text: widget.product?.category ?? '',
    );
    _selectedCategory = widget.product?.category ?? _categories.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _sellerIdController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.product != null;

    return Scaffold(
      backgroundColor: const Color(0xFFf5f8f6),
      appBar: AppBar(
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        title: Text(isEditMode ? 'Chỉnh Sửa Sản Phẩm' : 'Thêm Sản Phẩm'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                _buildTextField(
                  controller: _titleController,
                  label: 'Tên Sản Phẩm *',
                  hint: 'VD: Cà phê Robusta chất lượng cao',
                  icon: CupertinoIcons.cube_box,
                ),
                const SizedBox(height: 16),

                // Price
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _priceController,
                        label: 'Giá *',
                        hint: '0',
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        icon: CupertinoIcons.money_dollar,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _unitController,
                        label: 'Đơn Vị',
                        hint: 'kg',
                        icon: CupertinoIcons.cube,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Category
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(CupertinoIcons.tag, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        const Text(
                          'Danh Mục *',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(8),
                        underline: const SizedBox(),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedCategory = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Mô Tả',
                  hint: 'Nhập mô tả chi tiết về sản phẩm...',
                  icon: CupertinoIcons.doc_text,
                  maxLines: 5,
                ),
                const SizedBox(height: 16),

                // Seller ID
                _buildTextField(
                  controller: _sellerIdController,
                  label: 'ID Người Bán *',
                  hint: 'VD: 1',
                  keyboardType: TextInputType.number,
                  icon: CupertinoIcons.person,
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          // Sticky Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFf5f8f6),
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Lưu',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.green.shade400),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          keyboardType: keyboardType,
          maxLines: maxLines,
        ),
      ],
    );
  }

  void _saveProduct() {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    final isEditMode = widget.product != null;
    final product = Product(
      id: widget.product?.id,
      sellerId: int.parse(_sellerIdController.text),
      title: _titleController.text,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      category: _selectedCategory,
      price: double.parse(_priceController.text),
      unit: _unitController.text.isEmpty ? null : _unitController.text,
    );

    // Trigger BLoC event
    if (isEditMode) {
      context.read<ProductBloc>().add(UpdateProduct(product));
    } else {
      context.read<ProductBloc>().add(AddProduct(product));
    }

    // Đóng page sau 1 giây
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  bool _validateForm() {
    if (_titleController.text.isEmpty) {
      _showSnackBar('Vui lòng nhập tên sản phẩm');
      return false;
    }
    if (_priceController.text.isEmpty) {
      _showSnackBar('Vui lòng nhập giá');
      return false;
    }
    if (double.tryParse(_priceController.text) == null) {
      _showSnackBar('Giá phải là số hợp lệ');
      return false;
    }
    if (_sellerIdController.text.isEmpty) {
      _showSnackBar('Vui lòng nhập ID người bán');
      return false;
    }
    if (int.tryParse(_sellerIdController.text) == null) {
      _showSnackBar('ID người bán phải là số hợp lệ');
      return false;
    }
    return true;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
