import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guardian/features/farm/domain/entities/farm.dart';
import 'package:guardian/features/farm/domain/entities/farmer.dart';
import 'package:guardian/features/farm/presentation/bloc/farm_bloc.dart';
import 'package:guardian/features/farm/presentation/bloc/farm_event.dart';
import 'package:guardian/features/farm/presentation/bloc/farm_state.dart';
import 'package:guardian/features/farm/presentation/pages/farmer_selection_page.dart';
import 'package:guardian/features/farm/presentation/pages/farm_detail_page.dart';
import 'package:guardian/features/farm/presentation/pages/farmer_detail_page.dart';

class AllFarmsPage extends StatefulWidget {
  const AllFarmsPage({super.key});

  @override
  State<AllFarmsPage> createState() => _AllFarmsPageState();
}

class _AllFarmsPageState extends State<AllFarmsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Farm> _allFarms = [];
  List<Farm> _filteredFarms = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Load danh sách tất cả trang trại khi page mở
    context.read<FarmBloc>().add(const LoadAllFarmsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _filterFarms(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Start new timer with 300ms delay
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        if (query.isEmpty) {
          _filteredFarms = _allFarms;
        } else {
          _filteredFarms = _allFarms.where((farm) {
            final name = farm.farmName?.toLowerCase() ?? '';
            final location = farm.location?.toLowerCase() ?? '';
            final cropType = farm.cropType?.toLowerCase() ?? '';
            final searchQuery = query.toLowerCase();

            return name.contains(searchQuery) ||
                   location.contains(searchQuery) ||
                   cropType.contains(searchQuery);
          }).toList();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Trang Trại'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FarmerSelectionPage()),
              ).then((_) {
                // Reload farms after adding
                context.read<FarmBloc>().add(const LoadAllFarmsEvent());
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm trang trại...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
              onChanged: _filterFarms,
            ),
          ),
        ),
      ),
      body: BlocBuilder<FarmBloc, FarmState>(
        builder: (context, state) {
          if (state is AllFarmsLoadedState) {
            // Update local data when farms are loaded
            if (_allFarms.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _allFarms = state.farms;
                  _filteredFarms = state.farms;
                  _filterFarms(_searchController.text);
                });
              });
            }
          }

          if (state is FarmLoadingState && _allFarms.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AllFarmsLoadedState || _allFarms.isNotEmpty) {
            if (_filteredFarms.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.agriculture, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      _searchController.text.isEmpty
                          ? 'Chưa có trang trại nào'
                          : 'Không tìm thấy trang trại phù hợp',
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    if (_searchController.text.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          _searchController.clear();
                          _filterFarms('');
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Xóa bộ lọc'),
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const FarmerSelectionPage()),
                          ).then((_) {
                            // Reload farms after adding
                            context.read<FarmBloc>().add(const LoadAllFarmsEvent());
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm trang trại đầu tiên'),
                      ),
                    ],
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredFarms.length,
              itemBuilder: (context, index) {
                final farm = _filteredFarms[index];
                return _buildFarmCard(context, farm);
              },
            );
          } else if (state is FarmErrorState) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi: ${state.message}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<FarmBloc>().add(const LoadAllFarmsEvent());
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildFarmCard(BuildContext context, Farm farm) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.agriculture, color: Colors.white),
        ),
        title: Text(
          farm.farmName ?? 'Chưa đặt tên',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (farm.farmerName != null)
              Text('Chủ sở hữu: ${farm.farmerName ?? 'Chưa xác định'}', style: const TextStyle(fontWeight: FontWeight.w500)),
            if (farm.location != null)
              Text('Địa điểm: ${farm.location}'),
            Text('Diện tích: ${farm.areaHectares} ha'),
            if (farm.cropType != null)
              Text('Loại cây trồng: ${farm.cropType}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: 'Xem chủ sở hữu',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FarmerDetailPage(
                      farmer: Farmer(
                        userId: farm.farmerId,
                        fullName: farm.farmerName ?? 'Nông dân',
                      ),
                      isViewMode: true,
                    ),
                  ),
                ).then((_) {
                  context.read<FarmBloc>().add(const LoadAllFarmsEvent());
                });
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'view':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FarmDetailPage(farm: farm),
                      ),
                    ).then((_) {
                      context.read<FarmBloc>().add(const LoadAllFarmsEvent());
                    });
                    break;
                  case 'edit':
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chức năng chỉnh sửa đang được phát triển')),
                    );
                    break;
                  case 'delete':
                    _showDeleteConfirmation(context, farm);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility),
                      SizedBox(width: 8),
                      Text('Xem chi tiết'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Chỉnh sửa'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Xóa', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FarmDetailPage(farm: farm),
            ),
          ).then((_) {
            context.read<FarmBloc>().add(const LoadAllFarmsEvent());
          });
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Farm farm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa trang trại "${farm.farmName ?? 'này'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete farm
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng xóa đang được phát triển')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}