import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:guardian/features/product/presentation/pages/product_list_page.dart';
import 'package:guardian/features/routes/app_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildMenuCard(
            context,
            title: 'Sản Phẩm',
            icon: CupertinoIcons.cube_box,
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProductListPage()),
              );
            },
          ),
          _buildMenuCard(
            context,
            title: 'Doanh nghiệp',
            icon: CupertinoIcons.building_2_fill,
            color: Colors.teal,
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.adminDashboard);
            },
          ),
          _buildMenuCard(
            context,
            title: 'Nông Trại',
            icon: CupertinoIcons.leaf_arrow_circlepath,
            color: Colors.green,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng Nông Trại đang phát triển')),
              );
            },
          ),
          _buildMenuCard(
            context,
            title: 'Thống Kê',
            icon: CupertinoIcons.chart_bar_alt_fill,
            color: Colors.indigo,
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.adminDashboard);
            },
          ),
          _buildMenuCard(
            context,
            title: 'Hỗ Trợ Admin',
            icon: CupertinoIcons.person_2_square_stack_fill,
            color: Colors.deepOrange,
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.adminDashboard);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}