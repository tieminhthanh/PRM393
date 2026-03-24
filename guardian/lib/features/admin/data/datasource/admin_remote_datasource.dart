import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/admin_control_snapshot.dart';
import '../../domain/entities/chart_series_point.dart';
import '../../domain/entities/enterprise_profile.dart';
import '../../domain/entities/system_dashboard_stats.dart';
import 'admin_local_datasource.dart';

class AdminRemoteDataSourceImpl implements AdminDataSource {
  AdminRemoteDataSourceImpl({
    required this.client,
    required this.constants,
  });

  final ApiClient client;
  final ApiConstants constants;

  @override
  Future<List<EnterpriseProfile>> getEnterpriseProfiles() async {
    final response = await client.get(constants.endpoints.adminEnterprises);
    final list = _extractList(response);
    return list.map(_mapEnterpriseProfile).toList();
  }

  @override
  Future<void> saveEnterpriseProfile(EnterpriseProfile profile) async {
    final body = _enterpriseToJson(profile);
    if (profile.userId == null) {
      final response = await client.post(constants.endpoints.adminEnterprises, body: body);
      _ensureSuccess(response);
      return;
    }
    final response = await client.put(
      constants.endpoints.adminEnterpriseById(profile.userId!),
      body: body,
    );
    _ensureSuccess(response);
  }

  @override
  Future<void> toggleEnterpriseStatus(int userId, bool isActive) async {
    final response = await client.put(
      constants.endpoints.adminEnterpriseStatus(userId),
      body: {'isActive': isActive},
    );
    _ensureSuccess(response);
  }

  @override
  Future<SystemDashboardStats> getSystemDashboardStats() async {
    final statsResponse = await client.get(constants.endpoints.adminStats);
    final statsPayload = _extractMap(statsResponse);

    final futures = await Future.wait([
      client.get(constants.endpoints.adminRevenue),
      client.get(constants.endpoints.adminOrdersSeries),
      client.get(constants.endpoints.adminBookingSeries),
      client.get(constants.endpoints.adminTopEnterprises),
      client.get(constants.endpoints.adminTopProducts),
      client.get(constants.endpoints.adminTopMachines),
      client.get(constants.endpoints.adminTopRegions),
      client.get(constants.endpoints.adminAdmins),
    ]);

    final revenueSeries = _extractSeries(futures[0]);
    final orderSeries = _extractSeries(futures[1]);
    final bookingSeries = _extractSeries(futures[2]);
    final topEnterprises = _extractList(futures[3]);
    final topProducts = _extractList(futures[4]);
    final topMachines = _extractList(futures[5]);
    final topRegions = _extractList(futures[6]);
    final adminProfiles = _extractList(futures[7]);

    return SystemDashboardStats(
      totalEnterprises: _intFromMap(statsPayload, ['totalEnterprises', 'enterpriseCount', 'smeCount']),
      totalAdmins: _intFromMap(statsPayload, ['totalAdmins', 'adminCount']),
      totalFarmers: _intFromMap(statsPayload, ['totalFarmers', 'farmerCount']),
      totalProducts: _intFromMap(statsPayload, ['totalProducts', 'productCount']),
      totalOrders: _intFromMap(statsPayload, ['totalOrders', 'orderCount']),
      totalNotifications: _intFromMap(statsPayload, ['totalNotifications', 'notificationCount']),
      activeUsers: _intFromMap(statsPayload, ['activeUsers']),
      inactiveUsers: _intFromMap(statsPayload, ['inactiveUsers']),
      openMachineRequests: _intFromMap(statsPayload, ['openMachineRequests', 'openRequests']),
      revenueSeries: revenueSeries,
      orderSeries: orderSeries,
      bookingSeries: bookingSeries,
      adminProfiles: adminProfiles,
      topEnterprises: topEnterprises,
      topProducts: topProducts,
      topMachines: topMachines,
      topRegions: topRegions,
    );
  }

  @override
  Future<AdminControlSnapshot> getAdminControlSnapshot() async {
    final futures = await Future.wait([
      client.get(constants.endpoints.adminUsers),
      client.get(constants.endpoints.adminMachines),
      client.get(constants.endpoints.adminFarms),
      client.get(constants.endpoints.adminOrders),
    ]);

    return AdminControlSnapshot(
      users: _extractList(futures[0]),
      machines: _extractList(futures[1]),
      farms: _extractList(futures[2]),
      orders: _extractList(futures[3]),
    );
  }

  @override
  Future<void> toggleUserStatus(int userId, bool isActive) async {
    final response = await client.put(
      constants.endpoints.adminUserStatus(userId),
      body: {'isActive': isActive},
    );
    _ensureSuccess(response);
  }

  @override
  Future<void> updateMachineApproval(int machineId, bool isApproved) async {
    final response = await client.put(
      constants.endpoints.adminMachineApproval(machineId),
      body: {'isApproved': isApproved},
    );
    _ensureSuccess(response);
  }

  @override
  Future<void> updateFarmVerification(int farmId, bool isVerified) async {
    final response = await client.put(
      constants.endpoints.adminFarmVerification(farmId),
      body: {'isVerified': isVerified},
    );
    _ensureSuccess(response);
  }

  @override
  Future<void> updateOrderStatus(int orderId, String status) async {
    final response = await client.put(
      constants.endpoints.adminOrderStatus(orderId),
      body: {'status': status},
    );
    _ensureSuccess(response);
  }

  List<Map<String, dynamic>> _extractList(ApiResponse<Map<String, dynamic>> response) {
    _ensureSuccess(response);
    final raw = response.data ?? {};
    final payload = raw['data'] ?? raw['items'] ?? raw['result'] ?? raw;
    if (payload is List) {
      return payload.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    if (raw['data'] is List) {
      return (raw['data'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    return [];
  }

  Map<String, dynamic> _extractMap(ApiResponse<Map<String, dynamic>> response) {
    _ensureSuccess(response);
    final raw = response.data ?? {};
    final payload = raw['data'] ?? raw['result'] ?? raw;
    if (payload is Map<String, dynamic>) return payload;
    return raw;
  }

  List<ChartSeriesPoint> _extractSeries(ApiResponse<Map<String, dynamic>> response) {
    final list = _extractList(response);
    return list.map((item) {
      final label = item['label'] ?? item['period'] ?? item['date'] ?? '';
      final rawValue = item['value'] ?? item['total'] ?? item['count'] ?? 0;
      final value = rawValue is num ? rawValue.toDouble() : double.tryParse(rawValue.toString()) ?? 0.0;
      return ChartSeriesPoint(label: label.toString(), value: value);
    }).toList();
  }

  EnterpriseProfile _mapEnterpriseProfile(Map<String, dynamic> map) {
    return EnterpriseProfile(
      userId: _intFromAny(map['userId'] ?? map['UserId']),
      companyName: (map['companyName'] ?? map['CompanyName'] ?? '').toString(),
      taxCode: (map['taxCode'] ?? map['TaxCode'] ?? '').toString(),
      contactName: map['contactName'] ?? map['ContactName'],
      contactPhone: map['contactPhone'] ?? map['ContactPhone'],
      addressSummary: map['addressSummary'] ?? map['AddressSummary'],
      description: map['description'] ?? map['Description'],
      logoUrl: map['logoUrl'] ?? map['LogoUrl'],
      email: map['email'] ?? map['Email'],
      displayName: map['displayName'] ?? map['DisplayName'],
      isActive: _boolFromAny(map['isActive'] ?? map['IsActive']),
      createdAt: map['createdAt'] ?? map['CreatedAt'],
      productCount: _intFromAny(map['productCount'] ?? map['ProductCount']) ?? 0,
    );
  }

  Map<String, dynamic> _enterpriseToJson(EnterpriseProfile profile) {
    return {
      'companyName': profile.companyName,
      'taxCode': profile.taxCode,
      'contactName': profile.contactName,
      'contactPhone': profile.contactPhone,
      'addressSummary': profile.addressSummary,
      'description': profile.description,
      'logoUrl': profile.logoUrl,
      'email': profile.email,
      'displayName': profile.displayName,
      'isActive': profile.isActive,
    }..removeWhere((key, value) => value == null);
  }

  void _ensureSuccess(ApiResponse<Map<String, dynamic>> response) {
    if (!response.isSuccess) {
      throw Exception(response.error ?? 'API error');
    }
  }

  int _intFromMap(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final raw = map[key];
      final value = _intFromAny(raw);
      if (value != null) return value;
    }
    return 0;
  }

  int? _intFromAny(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  bool _boolFromAny(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }
}
