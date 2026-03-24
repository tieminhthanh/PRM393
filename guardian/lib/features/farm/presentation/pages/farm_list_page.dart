import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guardian/features/farm/domain/entities/farm.dart';
import 'package:guardian/features/farm/presentation/bloc/farm_bloc.dart';
import 'package:guardian/features/farm/presentation/bloc/farm_event.dart';
import 'package:guardian/features/farm/presentation/bloc/farm_state.dart';
import 'package:guardian/features/farm/presentation/pages/farm_detail_page.dart';
import 'package:guardian/features/farm/presentation/pages/farm_add_edit_page.dart';

class FarmListPage extends StatefulWidget {
  final int farmerId;
  final String farmerName;

  const FarmListPage({
    super.key,
    required this.farmerId,
    required this.farmerName,
  });

  @override
  State<FarmListPage> createState() => _FarmListPageState();
}

class _FarmListPageState extends State<FarmListPage> {
  @override
  void initState() {
    super.initState();
    // Load danh sách trang trại khi page mở
    context.read<FarmBloc>().add(LoadFarmsEvent(widget.farmerId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trang trại của ${widget.farmerName}'),
        elevation: 2,
      ),
      body: BlocBuilder<FarmBloc, FarmState>(
        builder: (context, state) {
          if (state is FarmLoadingState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is FarmsLoadedState) {
            if (state.farms.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.agriculture, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Chưa có trang trại nào'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FarmAddEditPage(
                              farmerId: widget.farmerId,
                            ),
                          ),
                        ).then((_) {
                          context
                              .read<FarmBloc>()
                              .add(LoadFarmsEvent(widget.farmerId));
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm trang trại'),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: state.farms.length,
              itemBuilder: (context, index) {
                final farm = state.farms[index];
                return FarmListTile(
                  farm: farm,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FarmDetailPage(farm: farm),
                      ),
                    ).then((_) {
                      context
                          .read<FarmBloc>()
                          .add(LoadFarmsEvent(widget.farmerId));
                    });
                  },
                );
              },
            );
          } else if (state is FarmErrorState) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<FarmBloc>()
                          .add(LoadFarmsEvent(widget.farmerId));
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FarmAddEditPage(
                farmerId: widget.farmerId,
              ),
            ),
          ).then((_) {
            context.read<FarmBloc>().add(LoadFarmsEvent(widget.farmerId));
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class FarmListTile extends StatelessWidget {
  final Farm farm;
  final VoidCallback onTap;

  const FarmListTile({
    super.key,
    required this.farm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: const Icon(Icons.eco),
        ),
        title: Text(farm.farmName ?? 'Trang trại (không có tên)'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (farm.location != null) Text('Địa điểm: ${farm.location}'),
            Text('Diện tích: ${farm.areaHectares} hectare'),
            if (farm.cropType != null) Text('Loại cây trồng: ${farm.cropType}'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
