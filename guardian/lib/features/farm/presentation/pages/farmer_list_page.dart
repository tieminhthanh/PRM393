import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guardian/features/farm/domain/entities/farmer.dart';
import 'package:guardian/features/farm/presentation/bloc/farm_bloc.dart';
import 'package:guardian/features/farm/presentation/bloc/farm_event.dart';
import 'package:guardian/features/farm/presentation/bloc/farm_state.dart';
import 'package:guardian/features/farm/presentation/pages/farmer_detail_page.dart';

class FarmerListPage extends StatefulWidget {
  const FarmerListPage({Key? key}) : super(key: key);

  @override
  State<FarmerListPage> createState() => _FarmerListPageState();
}

class _FarmerListPageState extends State<FarmerListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load danh sách nông dân khi page mở
    context.read<FarmBloc>().add(const LoadFarmersEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Nông Dân'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FarmerDetailPage(),
                ),
              ).then((_) {
                if (mounted) {
                  context.read<FarmBloc>().add(const LoadFarmersEvent());
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm nông dân...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<FarmBloc>().add(
                            const LoadFarmersEvent(),
                          );
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {});
                if (value.isEmpty) {
                  context.read<FarmBloc>().add(const LoadFarmersEvent());
                } else {
                  context.read<FarmBloc>().add(SearchFarmersEvent(value));
                }
              },
            ),
          ),
          // Farmers List
          Expanded(
            child: BlocBuilder<FarmBloc, FarmState>(
              builder: (context, state) {
                if (state is FarmLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is FarmersLoadedState) {
                  if (state.farmers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text('Chưa có nông dân nào'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const FarmerDetailPage(),
                                ),
                              ).then((_) {
                                if (mounted) {
                                  context.read<FarmBloc>().add(const LoadFarmersEvent());
                                }
                              });
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Thêm nông dân'),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: state.farmers.length,
                    itemBuilder: (context, index) {
                      final farmer = state.farmers[index];
                      return FarmerListTile(
                        farmer: farmer,
                        onTap: () {
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
                                const LoadFarmersEvent(),
                              );
                            }
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
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text('Lỗi: ${state.message}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<FarmBloc>().add(
                              const LoadFarmersEvent(),
                            );
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
          ),
        ],
      ),
    );
  }
}

class FarmerListTile extends StatelessWidget {
  final Farmer farmer;
  final VoidCallback onTap;

  const FarmerListTile({super.key, required this.farmer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(child: Text(farmer.fullName[0].toUpperCase())),
        title: Text(farmer.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (farmer.village != null) Text('Làng: ${farmer.village}'),
            if (farmer.contactPhone != null)
              Text('SĐT: ${farmer.contactPhone}'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
