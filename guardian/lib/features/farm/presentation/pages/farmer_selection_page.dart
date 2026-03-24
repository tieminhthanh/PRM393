import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guardian/features/farm/presentation/bloc/farm_bloc.dart';
import 'package:guardian/features/farm/presentation/bloc/farm_event.dart';
import 'package:guardian/features/farm/presentation/bloc/farm_state.dart';
import 'package:guardian/features/farm/presentation/pages/farm_add_edit_page.dart';

class FarmerSelectionPage extends StatefulWidget {
  const FarmerSelectionPage({super.key});

  @override
  State<FarmerSelectionPage> createState() => _FarmerSelectionPageState();
}

class _FarmerSelectionPageState extends State<FarmerSelectionPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
        title: const Text('Chọn Nông Dân'),
        elevation: 2,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm nông dân...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                if (value.isEmpty) {
                  context.read<FarmBloc>().add(const LoadFarmersEvent());
                } else {
                  context.read<FarmBloc>().add(SearchFarmersEvent(value));
                }
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<FarmBloc, FarmState>(
              builder: (context, state) {
                if (state is FarmLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is FarmersLoadedState) {
                  if (state.farmers.isEmpty) {
                    return const Center(
                      child: Text('Không có nông dân nào'),
                    );
                  }
                  return ListView.builder(
                    itemCount: state.farmers.length,
                    itemBuilder: (context, index) {
                      final farmer = state.farmers[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(farmer.fullName),
                        subtitle: Text(farmer.contactPhone ?? ''),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FarmAddEditPage(
                                farmerId: farmer.userId,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                } else if (state is FarmErrorState) {
                  return Center(
                    child: Text('Lỗi: ${state.message}'),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}