import 'dart:typed_data';

import '../../../../core/database/database_helper.dart';
import '../../domain/entities/admin_control_snapshot.dart';
import '../../domain/entities/chart_series_point.dart';
import '../../domain/entities/enterprise_profile.dart';
import '../../domain/entities/system_dashboard_stats.dart';

abstract class AdminDataSource {
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

class AdminLocalDataSourceImpl implements AdminDataSource {
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
        s.Description,
        s.LogoUrl,
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
        s.Description,
        s.LogoUrl,
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
        'Description': profile.description,
        'LogoUrl': profile.logoUrl,
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
        'Description': profile.description,
        'LogoUrl': profile.logoUrl,
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

    final revenueSeries = await _getRevenueSeries();
    final orderSeries = await _getOrderSeries();
    final bookingSeries = await _getBookingSeries();

    final alignedLabels = _mergeLabels([revenueSeries, orderSeries, bookingSeries]);
    final alignedRevenue = _alignSeries(alignedLabels, revenueSeries);
    final alignedOrders = _alignSeries(alignedLabels, orderSeries);
    final alignedBookings = _alignSeries(alignedLabels, bookingSeries);

    final adminProfiles = await dbService.rawQuery('''
      SELECT a.AdminId, a.FullName, a.Position, u.Email, u.IsActive
      FROM AdminProfiles a
      JOIN Users u ON u.UserId = a.AdminId
      ORDER BY a.CreatedAt DESC, a.FullName ASC
    ''');

    final topEnterprises = await dbService.rawQuery('''
      SELECT
        s.CompanyName,
        COALESCE(SUM(oi.Quantity * oi.Price), 0) AS Revenue,
        COUNT(DISTINCT o.OrderId) AS OrderCount,
        u.IsActive
      FROM SMEProfiles s
      JOIN Users u ON u.UserId = s.UserId
      LEFT JOIN commerce_Products p ON p.SellerId = s.UserId
      LEFT JOIN commerce_OrderItems oi ON oi.ProductId = p.ProductId
      LEFT JOIN commerce_Orders o ON o.OrderId = oi.OrderId
      GROUP BY s.UserId, s.CompanyName, u.IsActive
      ORDER BY Revenue DESC, s.CompanyName ASC
      LIMIT 5
    ''');

    final topProducts = await dbService.rawQuery('''
      SELECT
        p.Title,
        COALESCE(SUM(oi.Quantity), 0) AS QuantitySold,
        COALESCE(SUM(oi.Quantity * oi.Price), 0) AS Revenue,
        u.DisplayName AS SellerName
      FROM commerce_OrderItems oi
      JOIN commerce_Products p ON p.ProductId = oi.ProductId
      JOIN Users u ON u.UserId = p.SellerId
      GROUP BY p.ProductId, p.Title, u.DisplayName
      ORDER BY QuantitySold DESC, Revenue DESC
      LIMIT 5
    ''');

    final topMachines = await dbService.rawQuery('''
      SELECT
        m.MachineType,
        COUNT(b.BookingId) AS BookingCount,
        COALESCE(SUM(b.TotalPrice), 0) AS Revenue
      FROM logistics_AgriMachines m
      LEFT JOIN logistics_MachineBookings b ON b.MachineId = m.MachineId
      GROUP BY m.MachineId, m.MachineType
      ORDER BY BookingCount DESC, Revenue DESC
      LIMIT 5
    ''');

    final topRegions = await dbService.rawQuery('''
      SELECT
        COALESCE(a.Province, 'Không rõ') AS Region,
        COUNT(b.BookingId) AS BookingCount
      FROM logistics_MachineBookings b
      JOIN iot_Farms f ON f.FarmId = b.FarmId
      LEFT JOIN core_UserAddresses a ON a.UserId = f.FarmerId
      GROUP BY COALESCE(a.Province, 'Không rõ')
      ORDER BY BookingCount DESC
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
      revenueSeries: alignedRevenue,
      orderSeries: alignedOrders,
      bookingSeries: alignedBookings,
      adminProfiles: adminProfiles,
      topEnterprises: topEnterprises,
      topProducts: topProducts,
      topMachines: topMachines,
      topRegions: topRegions,
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
      description: map['Description'] as String?,
      logoUrl: map['LogoUrl'] as String?,
      email: map['Email'] as String?,
      displayName: map['DisplayName'] as String?,
      isActive: (map['IsActive'] as int? ?? 0) == 1,
      createdAt: map['CreatedAt'] as String?,
      productCount: (map['ProductCount'] as int?) ?? 0,
    );
  }

  @override
  Future<AdminControlSnapshot> getAdminControlSnapshot() async {
    final users = await dbService.rawQuery('''
      SELECT UserId, DisplayName, Email, RoleType, IsActive, CreatedAt
      FROM Users
      ORDER BY CreatedAt DESC
      LIMIT 8
    ''');

    final machines = await dbService.rawQuery('''
      SELECT m.MachineId, m.MachineType, m.BasePricePerHour, m.IsApproved,
             u.DisplayName AS OwnerName
      FROM logistics_AgriMachines m
      JOIN Users u ON u.UserId = m.OwnerId
      ORDER BY m.MachineId DESC
      LIMIT 8
    ''');

    final farms = await dbService.rawQuery('''
      SELECT f.FarmId, f.FarmName, f.AreaHectares, f.IsVerified,
             u.DisplayName AS FarmerName
      FROM iot_Farms f
      JOIN Users u ON u.UserId = f.FarmerId
      ORDER BY f.FarmId DESC
      LIMIT 8
    ''');

    final orders = await dbService.rawQuery('''
      SELECT o.OrderId, o.OrderTotal, o.Status, o.CreatedAt,
             u.DisplayName AS BuyerName
      FROM commerce_Orders o
      JOIN Users u ON u.UserId = o.BuyerId
      ORDER BY o.CreatedAt DESC
      LIMIT 8
    ''');

    return AdminControlSnapshot(
      users: users,
      machines: machines,
      farms: farms,
      orders: orders,
    );
  }

  @override
  Future<void> toggleUserStatus(int userId, bool isActive) {
    return dbService.update(
      'Users',
      {'IsActive': isActive ? 1 : 0},
      where: 'UserId = ?',
      whereArgs: [userId],
    );
  }

  @override
  Future<void> updateMachineApproval(int machineId, bool isApproved) {
    return dbService.update(
      'logistics_AgriMachines',
      {'IsApproved': isApproved ? 1 : 0},
      where: 'MachineId = ?',
      whereArgs: [machineId],
    );
  }

  @override
  Future<void> updateFarmVerification(int farmId, bool isVerified) {
    return dbService.update(
      'iot_Farms',
      {'IsVerified': isVerified ? 1 : 0},
      where: 'FarmId = ?',
      whereArgs: [farmId],
    );
  }

  @override
  Future<void> updateOrderStatus(int orderId, String status) {
    return dbService.update(
      'commerce_Orders',
      {'Status': status},
      where: 'OrderId = ?',
      whereArgs: [orderId],
    );
  }

  Future<List<ChartSeriesPoint>> _getRevenueSeries() async {
    final rows = await dbService.rawQuery('''
      SELECT strftime('%Y-%m', CreatedAt) AS Period,
             SUM(OrderTotal) AS Total
      FROM commerce_Orders
      GROUP BY Period
      ORDER BY Period ASC
      LIMIT 6
    ''');
    return _mapSeries(rows, valueKey: 'Total', fallbackStart: 12000000);
  }

  Future<List<ChartSeriesPoint>> _getOrderSeries() async {
    final rows = await dbService.rawQuery('''
      SELECT strftime('%Y-%m', CreatedAt) AS Period,
             COUNT(*) AS Count
      FROM commerce_Orders
      GROUP BY Period
      ORDER BY Period ASC
      LIMIT 6
    ''');
    return _mapSeries(rows, valueKey: 'Count', fallbackStart: 12);
  }

  Future<List<ChartSeriesPoint>> _getBookingSeries() async {
    final rows = await dbService.rawQuery('''
      SELECT strftime('%Y-%m', StartTime) AS Period,
             COUNT(*) AS Count
      FROM logistics_MachineBookings
      GROUP BY Period
      ORDER BY Period ASC
      LIMIT 6
    ''');
    return _mapSeries(rows, valueKey: 'Count', fallbackStart: 6);
  }

  List<ChartSeriesPoint> _mapSeries(
    List<Map<String, dynamic>> rows, {
    required String valueKey,
    required double fallbackStart,
  }) {
    if (rows.isEmpty) {
      return _fallbackSeries(startValue: fallbackStart);
    }

    final series = rows.map((row) {
      final label = row['Period'] as String? ?? '';
      final rawValue = row[valueKey];
      final value = rawValue is int
          ? rawValue.toDouble()
          : rawValue is double
              ? rawValue
              : double.tryParse(rawValue?.toString() ?? '') ?? 0.0;
      return ChartSeriesPoint(label: label, value: value);
    }).toList();

    series.sort((a, b) => a.label.compareTo(b.label));
    return series;
  }

  List<ChartSeriesPoint> _fallbackSeries({
    required double startValue,
  }) {
    final now = DateTime.now();
    return List.generate(6, (index) {
      final monthOffset = 5 - index;
      final date = DateTime(now.year, now.month - monthOffset, 1);
      final label = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final value = startValue + (index * startValue * 0.12);
      return ChartSeriesPoint(label: label, value: value);
    });
  }

  List<String> _mergeLabels(List<List<ChartSeriesPoint>> seriesList) {
    final labels = <String>{};
    for (final series in seriesList) {
      labels.addAll(series.map((point) => point.label));
    }
    final sorted = labels.toList()..sort();
    if (sorted.isEmpty) {
      return _fallbackSeries(startValue: 1).map((e) => e.label).toList();
    }
    return sorted;
  }

  List<ChartSeriesPoint> _alignSeries(
    List<String> labels,
    List<ChartSeriesPoint> series,
  ) {
    final lookup = {
      for (final point in series) point.label: point.value,
    };
    return labels
        .map((label) => ChartSeriesPoint(label: label, value: lookup[label] ?? 0.0))
        .toList();
  }
}
