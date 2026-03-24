import '../../domain/entities/admin_control_snapshot.dart';
import '../../domain/entities/enterprise_profile.dart';
import '../../domain/entities/system_dashboard_stats.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasource/admin_local_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl({
    required this.localDataSource,
    this.remoteDataSource,
  });

  final AdminDataSource localDataSource;
  final AdminDataSource? remoteDataSource;

  @override
  Future<List<EnterpriseProfile>> getEnterpriseProfiles() {
    if (remoteDataSource == null) {
      return localDataSource.getEnterpriseProfiles();
    }
    return _tryRemote(
      remoteDataSource!.getEnterpriseProfiles,
      localDataSource.getEnterpriseProfiles,
    );
  }

  @override
  Future<void> saveEnterpriseProfile(EnterpriseProfile profile) async {
    if (remoteDataSource != null) {
      await _tryRemoteWrite(() => remoteDataSource!.saveEnterpriseProfile(profile));
    }
    await localDataSource.saveEnterpriseProfile(profile);
  }

  @override
  Future<void> toggleEnterpriseStatus(int userId, bool isActive) async {
    if (remoteDataSource != null) {
      await _tryRemoteWrite(
        () => remoteDataSource!.toggleEnterpriseStatus(userId, isActive),
      );
    }
    await localDataSource.toggleEnterpriseStatus(userId, isActive);
  }

  @override
  Future<SystemDashboardStats> getSystemDashboardStats() {
    if (remoteDataSource == null) {
      return localDataSource.getSystemDashboardStats();
    }
    return _tryRemote(
      remoteDataSource!.getSystemDashboardStats,
      localDataSource.getSystemDashboardStats,
    );
  }

  @override
  Future<AdminControlSnapshot> getAdminControlSnapshot() {
    if (remoteDataSource == null) {
      return localDataSource.getAdminControlSnapshot();
    }
    return _tryRemote(
      remoteDataSource!.getAdminControlSnapshot,
      localDataSource.getAdminControlSnapshot,
    );
  }

  @override
  Future<void> toggleUserStatus(int userId, bool isActive) async {
    if (remoteDataSource != null) {
      await _tryRemoteWrite(
        () => remoteDataSource!.toggleUserStatus(userId, isActive),
      );
    }
    await localDataSource.toggleUserStatus(userId, isActive);
  }

  @override
  Future<void> updateMachineApproval(int machineId, bool isApproved) async {
    if (remoteDataSource != null) {
      await _tryRemoteWrite(
        () => remoteDataSource!.updateMachineApproval(machineId, isApproved),
      );
    }
    await localDataSource.updateMachineApproval(machineId, isApproved);
  }

  @override
  Future<void> updateFarmVerification(int farmId, bool isVerified) async {
    if (remoteDataSource != null) {
      await _tryRemoteWrite(
        () => remoteDataSource!.updateFarmVerification(farmId, isVerified),
      );
    }
    await localDataSource.updateFarmVerification(farmId, isVerified);
  }

  @override
  Future<void> updateOrderStatus(int orderId, String status) async {
    if (remoteDataSource != null) {
      await _tryRemoteWrite(
        () => remoteDataSource!.updateOrderStatus(orderId, status),
      );
    }
    await localDataSource.updateOrderStatus(orderId, status);
  }

  Future<void> _tryRemoteWrite(Future<void> Function() remoteCall) async {
    try {
      await remoteCall().timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  Future<T> _tryRemote<T>(
    Future<T> Function() remoteCall,
    Future<T> Function() localCall,
  ) async {
    try {
      return await remoteCall().timeout(const Duration(seconds: 3));
    } catch (_) {
      return localCall();
    }
  }
}
