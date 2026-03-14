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
  final List<Map<String, dynamic>> adminProfiles;
  final List<Map<String, dynamic>> topEnterprises;

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
    required this.adminProfiles,
    required this.topEnterprises,
  });
}