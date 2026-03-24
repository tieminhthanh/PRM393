import '../entities/admin_control_snapshot.dart';
import '../entities/enterprise_profile.dart';
import '../entities/system_dashboard_stats.dart';

abstract class AdminRepository {
  Future<List<EnterpriseProfile>> getEnterpriseProfiles();
  Future<void> saveEnterpriseProfile(EnterpriseProfile profile);
  Future<void> toggleEnterpriseStatus(int userId, bool isActive);
  Future<SystemDashboardStats> getSystemDashboardStats();
  Future<AdminControlSnapshot> getAdminControlSnapshot();
  Future<void> toggleUserStatus(int userId, bool isActive);
  Future<void> updateMachineApproval(int machineId, bool isApproved);
  Future<void> updateFarmVerification(int farmId, bool isVerified);
  Future<void> updateOrderStatus(int orderId, String status);
}
