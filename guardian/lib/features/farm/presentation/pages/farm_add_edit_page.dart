import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guardian/features/farm/domain/entities/farm.dart';
import 'package:guardian/features/farm/presentation/bloc/farm_bloc.dart';
import 'package:guardian/features/farm/presentation/bloc/farm_event.dart';
import 'package:guardian/features/farm/presentation/bloc/farm_state.dart';

class FarmAddEditPage extends StatefulWidget {
  final int farmerId;
  final Farm? farm;

  const FarmAddEditPage({
    super.key,
    required this.farmerId,
    this.farm,
  });

  @override
  State<FarmAddEditPage> createState() => _FarmAddEditPageState();
}

class _FarmAddEditPageState extends State<FarmAddEditPage> {
  late TextEditingController _farmNameController;
  late TextEditingController _locationController;
  late TextEditingController _areaHectaresController;
  late TextEditingController _cropTypeController;
  late TextEditingController _certificationsController;

  @override
  void initState() {
    super.initState();
    _farmNameController = TextEditingController(text: widget.farm?.farmName ?? '');
    _locationController = TextEditingController(text: widget.farm?.location ?? '');
    _areaHectaresController =
        TextEditingController(text: widget.farm?.areaHectares.toString() ?? '');
    _cropTypeController = TextEditingController(text: widget.farm?.cropType ?? '');
    _certificationsController =
        TextEditingController(text: widget.farm?.certifications ?? '');
  }

  @override
  void dispose() {
    _farmNameController.dispose();
    _locationController.dispose();
    _areaHectaresController.dispose();
    _cropTypeController.dispose();
    _certificationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.farm != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh sửa Trang trại' : 'Thêm Trang trại Mới'),
      ),
      body: BlocListener<FarmBloc, FarmState>(
        listener: (context, state) {
          if (state is FarmAddedState || state is FarmUpdatedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isEditing ? 'Cập nhật trang trại thành công!' : 'Thêm trang trại thành công!',
                ),
              ),
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
              // Farm Name
              TextFormField(
                controller: _farmNameController,
                decoration: InputDecoration(
                  labelText: 'Tên trang trại',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Location
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Địa điểm/Địa chỉ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Area Hectares
              TextFormField(
                controller: _areaHectaresController,
                decoration: InputDecoration(
                  labelText: 'Diện tích (hectare) *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              // Crop Type
              TextFormField(
                controller: _cropTypeController,
                decoration: InputDecoration(
                  labelText: 'Loại cây trồng',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Ví dụ: Lúa, Cà chua, Dưa chuột...',
                ),
              ),
              const SizedBox(height: 16),
              // Certifications
              TextFormField(
                controller: _certificationsController,
                decoration: InputDecoration(
                  labelText: 'Chứng chỉ/Tiêu chuẩn',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Ví dụ: VietGAP, Organic...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_areaHectaresController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập diện tích')),
                          );
                          return;
                        }

                        final areaHectares =
                            double.tryParse(_areaHectaresController.text) ?? 0.0;

                        if (isEditing) {
                          context.read<FarmBloc>().add(
                                UpdateFarmEvent(
                                  farmId: widget.farm!.farmId,
                                  farmerId: widget.farmerId,
                                  farmName: _farmNameController.text.isEmpty
                                      ? null
                                      : _farmNameController.text,
                                  location: _locationController.text.isEmpty
                                      ? null
                                      : _locationController.text,
                                  areaHectares: areaHectares,
                                  cropType: _cropTypeController.text.isEmpty
                                      ? null
                                      : _cropTypeController.text,
                                  certifications: _certificationsController.text.isEmpty
                                      ? null
                                      : _certificationsController.text,
                                ),
                              );
                        } else {
                          context.read<FarmBloc>().add(
                                AddFarmEvent(
                                  farmerId: widget.farmerId,
                                  farmName: _farmNameController.text.isEmpty
                                      ? null
                                      : _farmNameController.text,
                                  location: _locationController.text.isEmpty
                                      ? null
                                      : _locationController.text,
                                  areaHectares: areaHectares,
                                  cropType: _cropTypeController.text.isEmpty
                                      ? null
                                      : _cropTypeController.text,
                                  certifications: _certificationsController.text.isEmpty
                                      ? null
                                      : _certificationsController.text,
                                ),
                              );
                        }
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
                        content: const Text('Bạn có chắc chắn muốn xóa trang trại này?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () {
                              context.read<FarmBloc>().add(
                                    DeleteFarmEvent(widget.farm!.farmId),
                                  );
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Xóa trang trại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
