import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guardian/features/farm/domain/entities/farm.dart';
import 'package:guardian/features/farm/domain/entities/farm_image.dart';
import 'package:guardian/features/farm/domain/entities/farmer.dart';
import 'package:guardian/features/farm/presentation/bloc/farm_bloc.dart';
import 'package:guardian/features/farm/presentation/bloc/farm_event.dart';
import 'package:guardian/features/farm/presentation/bloc/farm_state.dart';
import 'package:guardian/features/farm/presentation/pages/farmer_detail_page.dart';
import 'package:guardian/features/farm/presentation/pages/farm_add_edit_page.dart';

class FarmDetailPage extends StatefulWidget {
  final Farm farm;

  const FarmDetailPage({super.key, required this.farm});

  @override
  State<FarmDetailPage> createState() => _FarmDetailPageState();
}

class _FarmDetailPageState extends State<FarmDetailPage> {
  Farm? _currentFarm;
  List<FarmImage> _images = [];
  Farmer? _currentFarmer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentFarm = widget.farm;
    // Load chi tiết trang trại và ảnh
    context.read<FarmBloc>().add(LoadFarmDetailEvent(widget.farm.farmId));
    // Load thông tin nông dân
    context.read<FarmBloc>().add(LoadFarmerDetailEvent(widget.farm.farmerId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.farm.farmName ?? 'Chi tiết Trang trại'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FarmAddEditPage(
                    farmerId: widget.farm.farmerId,
                    farm: widget.farm,
                  ),
                ),
              ).then((_) {
                context.read<FarmBloc>().add(
                  LoadFarmDetailEvent(widget.farm.farmId),
                );
              });
            },
          ),
        ],
      ),
      body: BlocBuilder<FarmBloc, FarmState>(
        builder: (context, state) {
          // Cập nhật dữ liệu vùng cục bộ để không mất farm/farmer khi đổi state
          if (state is FarmLoadingState) {
            _isLoading = true;
          } else {
            _isLoading = false;
          }

          if (state is FarmDetailLoadedState) {
            _currentFarm = state.farm;
            _images = state.images;
          }

          if (state is FarmerDetailLoadedState) {
            _currentFarmer = state.farmer;
          }

          final currentFarm = _currentFarm ?? widget.farm;
          final images = _images;
          final farmer = _currentFarmer;

          // Hiển thị loading overlay nếu đang load
          final isLoading = _isLoading;

          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Farm Images Section
                    if (images.isNotEmpty)
                      SizedBox(
                        height: 250,
                        child: PageView.builder(
                          itemCount: images.length,
                          itemBuilder: (context, index) {
                            final image = images[index];
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  image.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.broken_image),
                                    );
                                  },
                                ),
                                if (image.isPrimary == 1)
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Ảnh chính',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image_not_supported),
                        ),
                      ),

                    // Farmer Info Section
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text(
                                'Chủ sở hữu',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const Spacer(),
                              if (farmer != null)
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FarmerDetailPage(
                                          farmer: farmer,
                                          isViewMode: true,
                                        ),
                                      ),
                                    ).then((_) {
                                      if (mounted) {
                                        context.read<FarmBloc>().add(
                                          LoadFarmDetailEvent(widget.farm.farmId),
                                        );
                                        context.read<FarmBloc>().add(
                                          LoadFarmerDetailEvent(
                                            widget.farm.farmerId,
                                          ),
                                        );
                                      }
                                    });
                                  },
                                  icon: const Icon(Icons.visibility),
                                  label: const Text('Xem chủ sở hữu'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(label: 'Tên:', value: currentFarm.farmerName ?? 'Chưa xác định'),
                          if (farmer != null) ...[
                            if (farmer.contactPhone != null) ...[
                              const SizedBox(height: 8),
                              _InfoRow(
                                label: 'Số điện thoại:',
                                value: farmer.contactPhone!,
                              ),
                            ],
                            if (farmer.village != null) ...[
                              const SizedBox(height: 8),
                              _InfoRow(
                                label: 'Làng/Xã:',
                                value: farmer.village!,
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),

                    // Farm Info Section
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Farm Name
                          if (currentFarm.farmName != null)
                            _InfoRow(
                              label: 'Tên trang trại:',
                              value: currentFarm.farmName!,
                            ),
                          const SizedBox(height: 12),

                          // Location
                          if (currentFarm.location != null)
                            _InfoRow(
                              label: 'Địa điểm:',
                              value: currentFarm.location!,
                            ),
                          const SizedBox(height: 12),

                          // Area Hectares
                          _InfoRow(
                            label: 'Diện tích:',
                            value: '${currentFarm.areaHectares} hectare',
                          ),
                          const SizedBox(height: 12),

                          // Crop Type
                          if (currentFarm.cropType != null)
                            _InfoRow(
                              label: 'Loại cây trồng:',
                              value: currentFarm.cropType!,
                            ),
                          const SizedBox(height: 12),

                          // Certifications
                          if (currentFarm.certifications != null)
                            _InfoRow(
                              label: 'Chứng chỉ:',
                              value: currentFarm.certifications!,
                            ),

                          const SizedBox(height: 32),

                          // Images Management Section
                          if (images.isNotEmpty) ...[
                            const Text(
                              'Quản lý ảnh',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: images.length,
                              itemBuilder: (context, index) {
                                final image = images[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: Image.network(
                                      image.imageUrl,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.broken_image,
                                            );
                                          },
                                    ),
                                    title: Text(
                                      image.isPrimary == 1
                                          ? 'Ảnh chính'
                                          : 'Ảnh phụ',
                                    ),
                                    trailing: SizedBox(
                                      width: 120,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          if (image.isPrimary == 0)
                                            IconButton(
                                              icon: const Icon(
                                                Icons.star_outline,
                                              ),
                                              onPressed: () {
                                                context.read<FarmBloc>().add(
                                                  SetPrimaryImageEvent(
                                                    farmId: currentFarm.farmId,
                                                    imageId: image.imageId,
                                                  ),
                                                );
                                              },
                                            ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            color: Colors.red,
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('Xóa ảnh'),
                                                  content: const Text(
                                                    'Bạn có chắc muốn xóa ảnh này?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                          ),
                                                      child: const Text('Hủy'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        context
                                                            .read<FarmBloc>()
                                                            .add(
                                                              DeleteFarmImageEvent(
                                                                image.imageId,
                                                              ),
                                                            );
                                                        Navigator.pop(context);
                                                      },
                                                      child: const Text(
                                                        'Xóa',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Add Image Button
                          ElevatedButton.icon(
                            onPressed: () {
                              _showAddImageDialog(context, currentFarm.farmId);
                            },
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text('Thêm ảnh'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Loading overlay
              if (isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showAddImageDialog(BuildContext context, int farmId) {
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm ảnh'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'URL ảnh',
            hintText: 'Nhập đường dẫn ảnh',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              if (urlController.text.isNotEmpty) {
                context.read<FarmBloc>().add(
                  AddFarmImageEvent(
                    farmId: farmId,
                    imageUrl: urlController.text,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(value)),
      ],
    );
  }
}
