import 'dart:typed_data';

import '../../../../core/database/database_helper.dart';
import '../../domain/entities/enterprise_profile.dart';
import '../../domain/entities/system_dashboard_stats.dart';

abstract class AdminLocalDataSource {
  Future<List<EnterpriseProfile>> getEnterpriseProfiles();
  Future<void> saveEnterpriseProfile(EnterpriseProfile profile);
  Future<void> toggleEnterpriseStatus(int userId, bool isActive);
  Future<SystemDashboardStats> getSystemDashboardStats();
}

class AdminLocalDataSourceImpl implements AdminLocalDataSource {
  AdminLocalDataSourceImpl(this.dbService);

  final DatabaseService dbService;

  static final Uint8List _defaultPasswordHash = Uint8List.fromList(
    'Temp@123'.codeUnits,
  );

  @override
  Future<List<EnterpriseProfile>> getEnterpriseProfiles() async {
    final result = await dbService.rawQuery('''
      SELECT
        s.UserId,
        s.CompanyName,
        s.TaxCode,
        s.ContactName,
        s.ContactPhone,
        s.AddressSummary,
        u.Email,
        u.DisplayName,
        u.IsActive,
        u.CreatedAt,
        COUNT(DISTINCT p.ProductId) AS ProductCount
      FROM SMEProfiles s
      JOIN Users u ON u.UserId = s.UserId
      LEFT JOIN commerce_Products p ON p.SellerId = s.UserId
      GROUP BY
        s.UserId,
        s.CompanyName,
        s.TaxCode,
        s.ContactName,
        s.ContactPhone,
        s.AddressSummary,
        u.Email,
        u.DisplayName,
        u.IsActive,
        u.CreatedAt
      ORDER BY u.CreatedAt DESC, s.CompanyName ASC
    ''');

    return result.map(_mapEnterpriseProfile).toList();
  }

  @override
  Future<void> saveEnterpriseProfile(EnterpriseProfile profile) async {
    if (profile.userId == null) {
      final userId = await dbService.insert('Users', {
        'PhoneNumber': '09${DateTime.now().millisecondsSinceEpoch.toString().substring(4, 12)}',
        'Email': profile.email,
        'PasswordHash': _defaultPasswordHash,
        'RoleType': 'SME',
        'DisplayName': profile.displayName ?? profile.companyName,
        'IsActive': profile.isActive ? 1 : 0,
      });

      await dbService.insert('SMEProfiles', {
        'UserId': userId,
        'CompanyName': profile.companyName,
        'TaxCode': profile.taxCode,
        'ContactName': profile.contactName,
        'ContactPhone': profile.contactPhone,
        'AddressSummary': profile.addressSummary,
      });
      return;
    }

    await dbService.update(
      'Users',
      {
        'Email': profile.email,
        'DisplayName': profile.displayName ?? profile.companyName,
        'IsActive': profile.isActive ? 1 : 0,
      }..removeWhere((key, value) => value == null),
      where: 'UserId = ?',
      whereArgs: [profile.userId],
    );

    await dbService.update(
      'SMEProfiles',
      {
        'CompanyName': profile.companyName,
        'TaxCode': profile.taxCode,
        'ContactName': profile.contactName,
        'ContactPhone': profile.contactPhone,
        'AddressSummary': profile.addressSummary,
      }..removeWhere((key, value) => value == null),
      where: 'UserId = ?',
      whereArgs: [profile.userId],
    );
  }

  @override
  Future<void> toggleEnterpriseStatus(int userId, bool isActive) {
    return dbService.update(
      'Users',
      {'IsActive': isActive ? 1 : 0},
      where: 'UserId = ?',
      whereArgs: [userId],
    );
  }

  @override
  Future<SystemDashboardStats> getSystemDashboardStats() async {
    final enterpriseCount = await dbService.count('SMEProfiles');
    final adminCount = await dbService.count('AdminProfiles');
    final farmerCount = await dbService.count('FarmerProfiles');
    final productCount = await dbService.count('commerce_Products');
    final orderCount = await dbService.count('commerce_Orders');
    final notificationCount = await dbService.count('Notifications');
    final activeUsers = await dbService.count(
      'Users',
      where: 'IsActive = ?',
      whereArgs: [1],
    );
    final inactiveUsers = await dbService.count(
      'Users',
      where: 'IsActive = ?',
      whereArgs: [0],
    );
    final openMachineRequests = await dbService.count(
      'logistics_MachineHailingRequests',
      where: 'Status = ?',
      whereArgs: ['MATCHING'],
    );

    final adminProfiles = await dbService.rawQuery('''
      SELECT a.AdminId, a.FullName, a.Position, u.Email, u.IsActive
      FROM AdminProfiles a
      JOIN Users u ON u.UserId = a.AdminId
      ORDER BY a.CreatedAt DESC, a.FullName ASC
    ''');

    final topEnterprises = await dbService.rawQuery('''
      SELECT
        s.CompanyName,
        COUNT(p.ProductId) AS ProductCount,
        u.IsActive
      FROM SMEProfiles s
      JOIN Users u ON u.UserId = s.UserId
      LEFT JOIN commerce_Products p ON p.SellerId = s.UserId
      GROUP BY s.UserId, s.CompanyName, u.IsActive
      ORDER BY ProductCount DESC, s.CompanyName ASC
      LIMIT 5
    ''');

    return SystemDashboardStats(
      totalEnterprises: enterpriseCount,
      totalAdmins: adminCount,
      totalFarmers: farmerCount,
      totalProducts: productCount,
      totalOrders: orderCount,
      totalNotifications: notificationCount,
      activeUsers: activeUsers,
      inactiveUsers: inactiveUsers,
      openMachineRequests: openMachineRequests,
      adminProfiles: adminProfiles,
      topEnterprises: topEnterprises,
    );
  }

  EnterpriseProfile _mapEnterpriseProfile(Map<String, dynamic> map) {
    return EnterpriseProfile(
      userId: map['UserId'] as int?,
      companyName: map['CompanyName'] as String,
      taxCode: map['TaxCode'] as String,
      contactName: map['ContactName'] as String?,
      contactPhone: map['ContactPhone'] as String?,
      addressSummary: map['AddressSummary'] as String?,
      email: map['Email'] as String?,
      displayName: map['DisplayName'] as String?,
      isActive: (map['IsActive'] as int? ?? 0) == 1,
      createdAt: map['CreatedAt'] as String?,
      productCount: (map['ProductCount'] as int?) ?? 0,
    );
  }
}