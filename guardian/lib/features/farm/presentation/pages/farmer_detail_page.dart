import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guardian/features/farm/domain/entities/farm.dart';
import 'package:guardian/features/farm/domain/entities/farmer.dart';
import 'package:guardian/features/farm/presentation/bloc/farm_bloc.dart';
import 'package:guardian/features/farm/presentation/bloc/farm_event.dart';
import 'package:guardian/features/farm/presentation/bloc/farm_state.dart';
import 'package:guardian/features/farm/presentation/pages/farm_detail_page.dart';

class FarmerDetailPage extends StatefulWidget {
  final Farmer? farmer;
  final bool isViewMode;

  const FarmerDetailPage({super.key, this.farmer, this.isViewMode = false});

  @override
  State<FarmerDetailPage> createState() => _FarmerDetailPageState();
}

class _FarmerDetailPageState extends State<FarmerDetailPage> {
  late TextEditingController _userIdController;
  late TextEditingController _fullNameController;
  late TextEditingController _villageController;
  late TextEditingController _contactNameController;
  late TextEditingController _contactPhoneController;

  int _preferredVoice = 1;

  @override
  void initState() {
    super.initState();

    final farmer = widget.farmer;
    _userIdController = TextEditingController(
      text: farmer?.userId.toString() ?? '',
    );
    _fullNameController = TextEditingController(text: farmer?.fullName ?? '');
    _villageController = TextEditingController(text: farmer?.village ?? '');
    _contactNameController = TextEditingController(
      text: farmer?.contactName ?? '',
    );
    _contactPhoneController = TextEditingController(
      text: farmer?.contactPhone ?? '',
    );
    _preferredVoice = farmer?.preferredVoice ?? 1;

    if (farmer != null) {
      context.read<FarmBloc>().add(LoadFarmsEvent(farmer.userId));
    }
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _fullNameController.dispose();
    _villageController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.farmer != null && !widget.isViewMode;

    return WillPopScope(
      onWillPop: () async {
        // Load lại farmers trước khi pop về farmer_list_page
        if (mounted) {
          context.read<FarmBloc>().add(const LoadFarmersEvent());
        }
        return true;
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isViewMode
              ? 'Chi tiết Nông Dân'
              : (isEditing ? 'Chỉnh sửa Nông Dân' : 'Thêm Nông Dân Mới'),
        ),
        actions: [
          if (widget.isViewMode) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                if (widget.farmer != null) {
                  context.read<FarmBloc>().add(
                    LoadFarmsEvent(widget.farmer!.userId),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FarmerDetailPage(
                      farmer: widget.farmer,
                      isViewMode: false,
                    ),
                  ),
                ).then((_) {
                  if (widget.farmer != null) {
                    if (mounted) {
                      context.read<FarmBloc>().add(
                        LoadFarmsEvent(widget.farmer!.userId),
                      );
                    }
                  }
                });
              },
            ),
          ],
        ],
      ),
      body: BlocBuilder<FarmBloc, FarmState>(
        builder: (context, state) {
          final farms = state is FarmsLoadedState ? state.farms : <Farm>[];

          if (widget.isViewMode && widget.farmer != null) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<FarmBloc>().add(LoadFarmsEvent(widget.farmer!.userId));
                context.read<FarmBloc>().add(LoadFarmerDetailEvent(widget.farmer!.userId));
                // Wait a short moment to allow bloc to process
                await Future.delayed(const Duration(milliseconds: 300));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thông tin nông dân',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _InfoRow(
                            label: 'ID:',
                            value: widget.farmer!.userId.toString(),
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: 'Tên:',
                            value: widget.farmer!.fullName,
                          ),
                          if (widget.farmer!.contactPhone != null) ...[
                            const SizedBox(height: 8),
                            _InfoRow(
                              label: 'Số điện thoại:',
                              value: widget.farmer!.contactPhone!,
                            ),
                          ],
                          if (widget.farmer!.village != null) ...[
                            const SizedBox(height: 8),
                            _InfoRow(
                              label: 'Làng/Xã:',
                              value: widget.farmer!.village!,
                            ),
                          ],
                          if (widget.farmer!.contactName != null) ...[
                            const SizedBox(height: 8),
                            _InfoRow(
                              label: 'Người liên hệ:',
                              value: widget.farmer!.contactName!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Các trang trại quản lý',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (state is FarmLoadingState)
                    const Center(child: CircularProgressIndicator())
                  else if (farms.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Nông dân này chưa có trang trại nào'),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: farms.length,
                      itemBuilder: (context, index) {
                        final farm = farms[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(
                                Icons.agriculture,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(farm.farmName ?? 'Chưa đặt tên'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (farm.location != null)
                                  Text('Địa điểm: ${farm.location}'),
                                Text('Diện tích: ${farm.areaHectares} ha'),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      FarmDetailPage(farm: farm),
                                ),
                              ).then((_) {
                                if (widget.farmer != null) {
                                  if (mounted) {
                                    context.read<FarmBloc>().add(
                                      LoadFarmsEvent(widget.farmer!.userId),
                                    );
                                  }
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        }

          return BlocListener<FarmBloc, FarmState>(
            listener: (context, state) {
              if (state is FarmerSavedState) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lưu nông dân thành công!')),
                );
                Navigator.pop(context);
              } else if (state is FarmErrorState) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: ${state.message}')),
                );
              }
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _userIdController,
                    enabled: !isEditing,
                    decoration: InputDecoration(
                      labelText: 'ID Người dùng',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _fullNameController,
                    decoration: InputDecoration(
                      labelText: 'Tên đầy đủ *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _villageController,
                    decoration: InputDecoration(
                      labelText: 'Làng/Thôn',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactNameController,
                    decoration: InputDecoration(
                      labelText: 'Tên liên hệ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactPhoneController,
                    decoration: InputDecoration(
                      labelText: 'Số điện thoại liên hệ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _preferredVoice,
                    decoration: InputDecoration(
                      labelText: 'Ngôn ngữ ưa thích',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 1,
                        child: Text('Tiếng Việt (Miền Tây)'),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text('Tiếng Việt (Miền Bắc)'),
                      ),
                      DropdownMenuItem(
                        value: 3,
                        child: Text('Tiếng Việt (Miền Trung)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _preferredVoice = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (_fullNameController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Vui lòng nhập tên nông dân'),
                                ),
                              );
                              return;
                            }

                            final userId = isEditing
                                ? widget.farmer!.userId
                                : int.tryParse(_userIdController.text) ?? 0;

                            context.read<FarmBloc>().add(
                              SaveFarmerEvent(
                                userId: userId,
                                fullName: _fullNameController.text,
                                village: _villageController.text.isEmpty
                                    ? null
                                    : _villageController.text,
                                contactName: _contactNameController.text.isEmpty
                                    ? null
                                    : _contactNameController.text,
                                contactPhone:
                                    _contactPhoneController.text.isEmpty
                                    ? null
                                    : _contactPhoneController.text,
                                preferredVoice: _preferredVoice,
                              ),
                            );
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Lưu'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.cancel),
                          label: const Text('Hủy'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isEditing) ...[
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Xác nhận xóa'),
                            content: const Text(
                              'Bạn có chắc chắn muốn xóa nông dân này?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Hủy'),
                              ),
                              TextButton(
                                onPressed: () {
                                  context.read<FarmBloc>().add(
                                    DeleteFarmerEvent(widget.farmer!.userId),
                                  );
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Xóa',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Xóa nông dân'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
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
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
