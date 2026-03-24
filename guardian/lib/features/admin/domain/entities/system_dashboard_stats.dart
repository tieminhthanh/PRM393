import 'chart_series_point.dart';

class SystemDashboardStats {
  final int totalEnterprises;
  final int totalAdmins;
  final int totalFarmers;
  final int totalProducts;
  final int totalOrders;
  final int totalNotifications;
  final int activeUsers;
  final int inactiveUsers;
  final int openMachineRequests;
  final List<ChartSeriesPoint> revenueSeries;
  final List<ChartSeriesPoint> orderSeries;
  final List<ChartSeriesPoint> bookingSeries;
  final List<Map<String, dynamic>> adminProfiles;
  final List<Map<String, dynamic>> topEnterprises;
  final List<Map<String, dynamic>> topProducts;
  final List<Map<String, dynamic>> topMachines;
  final List<Map<String, dynamic>> topRegions;

  const SystemDashboardStats({
    required this.totalEnterprises,
    required this.totalAdmins,
    required this.totalFarmers,
    required this.totalProducts,
    required this.totalOrders,
    required this.totalNotifications,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.openMachineRequests,
    required this.revenueSeries,
    required this.orderSeries,
    required this.bookingSeries,
    required this.adminProfiles,
    required this.topEnterprises,
    required this.topProducts,
    required this.topMachines,
    required this.topRegions,
  });
}
