import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/admin_control_snapshot.dart';
import '../../domain/entities/chart_series_point.dart';
import '../../domain/entities/enterprise_profile.dart';
import '../../domain/entities/system_dashboard_stats.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({
    super.key,
    required this.adminRepository,
    this.initialTabIndex = 0,
  });

  final AdminRepository adminRepository;
  final int initialTabIndex;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<List<EnterpriseProfile>> _profilesFuture;
  late Future<SystemDashboardStats> _statsFuture;
  late Future<AdminControlSnapshot> _controlFuture;

  @override
  void initState() {
    super.initState();
    final safeIndex = widget.initialTabIndex.clamp(0, 2);
    _tabController = TabController(length: 3, vsync: this, initialIndex: safeIndex);
    _reloadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reloadData() {
    _profilesFuture = widget.adminRepository.getEnterpriseProfiles();
    _statsFuture = widget.adminRepository.getSystemDashboardStats();
    _controlFuture = widget.adminRepository.getAdminControlSnapshot();
  }

  Future<void> _refreshAll() async {
    setState(_reloadData);
    await Future.wait([_profilesFuture, _statsFuture, _controlFuture]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('Doanh nghiệp & Quản trị hệ thống'),
        backgroundColor: const Color(0xFF0F5C45),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFF6D860),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Hồ sơ doanh nghiệp'),
            Tab(text: 'Thống kê hệ thống'),
            Tab(text: 'Kiểm soát'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _EnterpriseManagementTab(
            profilesFuture: _profilesFuture,
            onRefresh: _refreshAll,
            onSaveProfile: _handleSaveProfile,
            onToggleStatus: _handleToggleStatus,
          ),
          _SystemStatsTab(
            statsFuture: _statsFuture,
            onRefresh: _refreshAll,
          ),
          _AdminControlTab(
            controlFuture: _controlFuture,
            onRefresh: _refreshAll,
            onToggleUserStatus: _handleToggleUserStatus,
            onMachineApproval: _handleMachineApproval,
            onFarmVerification: _handleFarmVerification,
            onOrderStatus: _handleOrderStatus,
          ),
        ],
      ),
    );
  }

  Future<void> _handleSaveProfile(EnterpriseProfile profile) async {
    await widget.adminRepository.saveEnterpriseProfile(profile);
    await _refreshAll();
  }

  Future<void> _handleToggleStatus(int userId, bool isActive) async {
    await widget.adminRepository.toggleEnterpriseStatus(userId, isActive);
    await _refreshAll();
  }

  Future<void> _handleToggleUserStatus(int userId, bool isActive) async {
    await widget.adminRepository.toggleUserStatus(userId, isActive);
    await _refreshAll();
  }

  Future<void> _handleMachineApproval(int machineId, bool isApproved) async {
    await widget.adminRepository.updateMachineApproval(machineId, isApproved);
    await _refreshAll();
  }

  Future<void> _handleFarmVerification(int farmId, bool isVerified) async {
    await widget.adminRepository.updateFarmVerification(farmId, isVerified);
    await _refreshAll();
  }

  Future<void> _handleOrderStatus(int orderId, String status) async {
    await widget.adminRepository.updateOrderStatus(orderId, status);
    await _refreshAll();
  }
}

class _EnterpriseManagementTab extends StatefulWidget {
  const _EnterpriseManagementTab({
    required this.profilesFuture,
    required this.onRefresh,
    required this.onSaveProfile,
    required this.onToggleStatus,
  });

  final Future<List<EnterpriseProfile>> profilesFuture;
  final Future<void> Function() onRefresh;
  final Future<void> Function(EnterpriseProfile profile) onSaveProfile;
  final Future<void> Function(int userId, bool isActive) onToggleStatus;

  @override
  State<_EnterpriseManagementTab> createState() => _EnterpriseManagementTabState();
}

class _EnterpriseManagementTabState extends State<_EnterpriseManagementTab> {
  String _searchTerm = '';

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: FutureBuilder<List<EnterpriseProfile>>(
        future: widget.profilesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: 'Không tải được hồ sơ doanh nghiệp.',
              onRetry: widget.onRefresh,
            );
          }

          final profiles = snapshot.data ?? const <EnterpriseProfile>[];
          final filteredProfiles = profiles.where((profile) {
            if (_searchTerm.isEmpty) return true;
            final keyword = _searchTerm.toLowerCase();
            return profile.companyName.toLowerCase().contains(keyword) ||
                profile.taxCode.toLowerCase().contains(keyword) ||
                (profile.contactName?.toLowerCase().contains(keyword) ?? false);
          }).toList();

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _SectionBanner(
                title: 'Quản lý hồ sơ doanh nghiệp',
                subtitle: 'Cập nhật thông tin SME, bật/tắt hoạt động và hỗ trợ admin kiểm soát seller.',
                actionLabel: 'Thêm doanh nghiệp',
                onAction: () => _openProfileSheet(context),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên doanh nghiệp, mã số thuế, liên hệ',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => _searchTerm = value.trim()),
              ),
              const SizedBox(height: 16),
              if (filteredProfiles.isEmpty)
                const _EmptyState(message: 'Chưa có hồ sơ phù hợp với bộ lọc hiện tại.')
              else
                ...filteredProfiles.map(
                  (profile) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _EnterpriseCard(
                      profile: profile,
                      onEdit: () => _openProfileSheet(context, profile: profile),
                      onToggleStatus: (value) async {
                        if (profile.userId == null) return;
                        await widget.onToggleStatus(profile.userId!, value);
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openProfileSheet(
    BuildContext context, {
    EnterpriseProfile? profile,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showModalBottomSheet<EnterpriseProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EnterpriseFormSheet(profile: profile),
    );

    if (result != null) {
      await widget.onSaveProfile(result);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            profile == null
                ? 'Đã thêm hồ sơ doanh nghiệp.'
                : 'Đã cập nhật hồ sơ doanh nghiệp.',
          ),
        ),
      );
    }
  }
}

class _SystemStatsTab extends StatelessWidget {
  const _SystemStatsTab({
    required this.statsFuture,
    required this.onRefresh,
  });

  final Future<SystemDashboardStats> statsFuture;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: FutureBuilder<SystemDashboardStats>(
        future: statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: 'Không tải được thống kê hệ thống.',
              onRetry: onRefresh,
            );
          }

          final stats = snapshot.data;
          if (stats == null) {
            return const _EmptyState(message: 'Chưa có dữ liệu thống kê.');
          }

          final totalUsers = stats.activeUsers + stats.inactiveUsers;
          final activeRatio = totalUsers == 0 ? 0.0 : stats.activeUsers / totalUsers;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const _SectionBanner(
                title: 'Dashboard quản trị',
                subtitle: 'Theo dõi vận hành tổng thể, nhịp độ doanh nghiệp và vùng cần admin hỗ trợ.',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricCard(label: 'Doanh nghiệp', value: '${stats.totalEnterprises}', color: const Color(0xFF0F5C45), icon: Icons.apartment),
                  _MetricCard(label: 'Admin', value: '${stats.totalAdmins}', color: const Color(0xFF1565C0), icon: Icons.admin_panel_settings),
                  _MetricCard(label: 'Nông hộ', value: '${stats.totalFarmers}', color: const Color(0xFF7B5E00), icon: Icons.agriculture),
                  _MetricCard(label: 'Sản phẩm', value: '${stats.totalProducts}', color: const Color(0xFF8E24AA), icon: Icons.inventory_2),
                  _MetricCard(label: 'Đơn hàng', value: '${stats.totalOrders}', color: const Color(0xFFD84315), icon: Icons.receipt_long),
                  _MetricCard(label: 'Thông báo', value: '${stats.totalNotifications}', color: const Color(0xFF455A64), icon: Icons.notifications_active),
                ],
              ),
              const SizedBox(height: 20),
              _ChartPanel(
                title: 'Doanh thu theo thời gian',
                subtitle: 'Tổng doanh thu đơn hàng (theo tháng)',
                child: _RevenueLineChart(series: stats.revenueSeries),
              ),
              const SizedBox(height: 16),
              _ChartPanel(
                title: 'Đơn hàng & thuê máy',
                subtitle: 'So sánh số đơn hàng và số lượt thuê máy',
                child: _OrdersBookingBarChart(
                  orderSeries: stats.orderSeries,
                  bookingSeries: stats.bookingSeries,
                ),
              ),
              const SizedBox(height: 16),
              _InsightPanel(
                title: 'Sức khỏe hệ thống',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProgressRow(
                      label: 'Người dùng đang hoạt động',
                      valueLabel: '${stats.activeUsers}/$totalUsers',
                      value: activeRatio,
                      color: const Color(0xFF0F5C45),
                    ),
                    const SizedBox(height: 12),
                    _SummaryLine(label: 'Người dùng bị khóa', value: '${stats.inactiveUsers}'),
                    _SummaryLine(label: 'Yêu cầu máy đang chờ ghép', value: '${stats.openMachineRequests}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InsightPanel(
                title: 'Thống kê Machine',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SubSectionTitle('Máy được thuê nhiều nhất'),
                    if (stats.topMachines.isEmpty)
                      const _EmptyState(message: 'Chưa có dữ liệu thuê máy.')
                    else
                      ...stats.topMachines.map((machine) {
                        final count = machine['BookingCount'] ?? machine['bookingCount'] ?? 0;
                        final revenue = _formatCurrency(machine['Revenue'] ?? machine['revenue']);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFFF3C4),
                            child: Icon(Icons.agriculture, color: Color(0xFF7B5E00)),
                          ),
                          title: Text(
                            machine['MachineType'] as String? ??
                                machine['machineType'] as String? ??
                                'Máy nông nghiệp',
                          ),
                          subtitle: Text('Doanh thu $revenue'),
                          trailing: Text('$count lượt'),
                        );
                      }),
                    const SizedBox(height: 12),
                    const _SubSectionTitle('Khu vực có nhu cầu cao'),
                    if (stats.topRegions.isEmpty)
                      const _EmptyState(message: 'Chưa có dữ liệu khu vực.')
                    else
                      ...stats.topRegions.map((region) {
                        final count = region['BookingCount'] ?? region['bookingCount'] ?? 0;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFDCEBFF),
                            child: Icon(Icons.location_on, color: Color(0xFF1565C0)),
                          ),
                          title: Text(
                            region['Region'] as String? ??
                                region['region'] as String? ??
                                'Khu vực',
                          ),
                          trailing: Text('$count lượt'),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InsightPanel(
                title: 'Marketplace Insights',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SubSectionTitle('Sản phẩm bán chạy'),
                    if (stats.topProducts.isEmpty)
                      const _EmptyState(message: 'Chưa có dữ liệu sản phẩm.')
                    else
                      ...stats.topProducts.map((product) {
                        final quantity = product['QuantitySold'] ?? product['quantitySold'] ?? 0;
                        final revenue = _formatCurrency(product['Revenue'] ?? product['revenue']);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFEDE9FE),
                            child: Icon(Icons.shopping_bag, color: Color(0xFF5B21B6)),
                          ),
                          title: Text(
                            product['Title'] as String? ??
                                product['title'] as String? ??
                                'Sản phẩm',
                          ),
                          subtitle: Text('Doanh thu $revenue'),
                          trailing: Text('$quantity lượt'),
                        );
                      }),
                    const SizedBox(height: 12),
                    const _SubSectionTitle('Top SME theo doanh thu'),
                    if (stats.topEnterprises.isEmpty)
                      const _EmptyState(message: 'Chưa có dữ liệu doanh nghiệp.')
                    else
                      ...stats.topEnterprises.map((enterprise) {
                        final revenue = _formatCurrency(enterprise['Revenue'] ?? enterprise['revenue']);
                        final orders = enterprise['OrderCount'] ?? enterprise['orderCount'] ?? 0;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: _boolFromAny(
                              enterprise['IsActive'] ?? enterprise['isActive'],
                            )
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEE2E2),
                            child: Icon(
                              Icons.business,
                              color: _boolFromAny(
                                enterprise['IsActive'] ?? enterprise['isActive'],
                              )
                                  ? const Color(0xFF0F5C45)
                                  : const Color(0xFFB91C1C),
                            ),
                          ),
                          title: Text(
                            enterprise['CompanyName'] as String? ??
                                enterprise['companyName'] as String? ??
                                'Không rõ',
                          ),
                          subtitle: Text('Doanh thu $revenue'),
                          trailing: Text('$orders đơn'),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InsightPanel(
                title: 'Hỗ trợ admin',
                child: Column(
                  children: stats.adminProfiles.isEmpty
                      ? const [
                          _EmptyState(message: 'Chưa có hồ sơ admin.')
                        ]
                      : stats.adminProfiles.map((admin) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFDCEBFF),
                              child: Icon(Icons.support_agent, color: Color(0xFF1565C0)),
                            ),
                            title: Text(
                              admin['FullName'] as String? ??
                                  admin['fullName'] as String? ??
                                  'Admin',
                            ),
                            subtitle: Text(
                              admin['Position'] as String? ??
                                  admin['position'] as String? ??
                                  'Chưa cập nhật vị trí',
                            ),
                            trailing: Text(
                              _boolFromAny(admin['IsActive'] ?? admin['isActive'])
                                  ? 'Đang hoạt động'
                                  : 'Tạm khóa',
                              style: TextStyle(
                                color: _boolFromAny(admin['IsActive'] ?? admin['isActive'])
                                    ? const Color(0xFF0F5C45)
                                    : const Color(0xFFB91C1C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminControlTab extends StatelessWidget {
  const _AdminControlTab({
    required this.controlFuture,
    required this.onRefresh,
    required this.onToggleUserStatus,
    required this.onMachineApproval,
    required this.onFarmVerification,
    required this.onOrderStatus,
  });

  final Future<AdminControlSnapshot> controlFuture;
  final Future<void> Function() onRefresh;
  final Future<void> Function(int userId, bool isActive) onToggleUserStatus;
  final Future<void> Function(int machineId, bool isApproved) onMachineApproval;
  final Future<void> Function(int farmId, bool isVerified) onFarmVerification;
  final Future<void> Function(int orderId, String status) onOrderStatus;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: FutureBuilder<AdminControlSnapshot>(
        future: controlFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: 'Không tải được dữ liệu kiểm soát.',
              onRetry: onRefresh,
            );
          }

          final control = snapshot.data;
          if (control == null) {
            return const _EmptyState(message: 'Chưa có dữ liệu kiểm soát.');
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const _SectionBanner(
                title: 'Trung tâm kiểm soát',
                subtitle: 'Duyệt người dùng, máy móc, nông trại và theo dõi đơn hàng.',
              ),
              const SizedBox(height: 16),
              _InsightPanel(
                title: 'Người dùng',
                child: Column(
                  children: control.users.isEmpty
                      ? const [
                          _EmptyState(message: 'Chưa có người dùng.')
                        ]
                      : control.users.map((user) {
                        final isActive = _boolFromAny(user['IsActive'] ?? user['isActive']);
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: isActive
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFEE2E2),
                              child: Icon(
                                Icons.person,
                                color: isActive ? const Color(0xFF0F5C45) : const Color(0xFFB91C1C),
                              ),
                            ),
                            title: Text(
                              user['DisplayName'] as String? ??
                                  user['displayName'] as String? ??
                                  'Người dùng',
                            ),
                            subtitle: Text(
                              '${user['RoleType'] ?? user['roleType'] ?? 'N/A'} • ${user['Email'] ?? user['email'] ?? 'Chưa có email'}',
                            ),
                            trailing: Switch.adaptive(
                              value: isActive,
                              onChanged: (value) async {
                                final id = user['UserId'] as int? ?? user['userId'] as int?;
                                if (id == null) return;
                                await onToggleUserStatus(id, value);
                              },
                            ),
                          );
                        }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              _InsightPanel(
                title: 'Máy nông nghiệp',
                child: Column(
                  children: control.machines.isEmpty
                      ? const [
                          _EmptyState(message: 'Chưa có máy cần duyệt.')
                        ]
                      : control.machines.map((machine) {
                        final isApproved = _boolFromAny(
                          machine['IsApproved'] ?? machine['isApproved'],
                        );
                          final price = _formatCurrency(machine['BasePricePerHour']);
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: isApproved
                                  ? const Color(0xFFE0F2FE)
                                  : const Color(0xFFFDE2E2),
                              child: Icon(
                                Icons.agriculture,
                                color: isApproved ? const Color(0xFF1565C0) : const Color(0xFFB91C1C),
                              ),
                            ),
                            title: Text(
                              machine['MachineType'] as String? ??
                                  machine['machineType'] as String? ??
                                  'Máy nông nghiệp',
                            ),
                            subtitle: Text(
                              'Chủ sở hữu: ${machine['OwnerName'] ?? machine['ownerName'] ?? 'N/A'} • $price/giờ',
                            ),
                            trailing: Switch.adaptive(
                              value: isApproved,
                              onChanged: (value) async {
                                final id = machine['MachineId'] as int? ?? machine['machineId'] as int?;
                                if (id == null) return;
                                await onMachineApproval(id, value);
                              },
                            ),
                          );
                        }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              _InsightPanel(
                title: 'Nông trại',
                child: Column(
                  children: control.farms.isEmpty
                      ? const [
                          _EmptyState(message: 'Chưa có nông trại cần duyệt.')
                        ]
                      : control.farms.map((farm) {
                        final isVerified = _boolFromAny(
                          farm['IsVerified'] ?? farm['isVerified'],
                        );
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: isVerified
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFDE2E2),
                              child: Icon(
                                Icons.eco,
                                color: isVerified ? const Color(0xFF0F5C45) : const Color(0xFFB91C1C),
                              ),
                            ),
                            title: Text(
                              farm['FarmName'] as String? ??
                                  farm['farmName'] as String? ??
                                  'Nông trại',
                            ),
                            subtitle: Text(
                              'Chủ trại: ${farm['FarmerName'] ?? farm['farmerName'] ?? 'N/A'} • ${farm['AreaHectares'] ?? farm['areaHectares'] ?? 0} ha',
                            ),
                            trailing: Switch.adaptive(
                              value: isVerified,
                              onChanged: (value) async {
                                final id = farm['FarmId'] as int? ?? farm['farmId'] as int?;
                                if (id == null) return;
                                await onFarmVerification(id, value);
                              },
                            ),
                          );
                        }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              _InsightPanel(
                title: 'Đơn hàng',
                child: Column(
                  children: control.orders.isEmpty
                      ? const [
                          _EmptyState(message: 'Chưa có đơn hàng.')
                        ]
                      : control.orders.map((order) {
                          final total = _formatCurrency(order['OrderTotal'] ?? order['orderTotal']);
                          final status = (order['Status'] ?? order['status'] ?? 'CREATED').toString();
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFF3E8FF),
                              child: Icon(Icons.receipt_long, color: Color(0xFF6D28D9)),
                            ),
                            title: Text('Đơn #${order['OrderId'] ?? order['orderId'] ?? '-'} • $total'),
                            subtitle: Text('Người mua: ${order['BuyerName'] ?? order['buyerName'] ?? 'N/A'}'),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                final id = order['OrderId'] as int? ?? order['orderId'] as int?;
                                if (id == null) return;
                                await onOrderStatus(id, value);
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'CREATED', child: Text('Đã tạo')),
                                PopupMenuItem(value: 'PAID', child: Text('Đã thanh toán')),
                                PopupMenuItem(value: 'SHIPPING', child: Text('Đang giao')),
                                PopupMenuItem(value: 'COMPLETED', child: Text('Hoàn tất')),
                                PopupMenuItem(value: 'CANCELLED', child: Text('Hủy')),
                                PopupMenuItem(value: 'DISPUTED', child: Text('Tranh chấp')),
                              ],
                              child: _StatusChip(label: status),
                            ),
                          );
                        }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EnterpriseFormSheet extends StatefulWidget {
  const _EnterpriseFormSheet({this.profile});

  final EnterpriseProfile? profile;

  @override
  State<_EnterpriseFormSheet> createState() => _EnterpriseFormSheetState();
}

class _EnterpriseFormSheetState extends State<_EnterpriseFormSheet> {
  late final TextEditingController _companyController;
  late final TextEditingController _taxCodeController;
  late final TextEditingController _contactController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _logoController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _companyController = TextEditingController(text: profile?.companyName ?? '');
    _taxCodeController = TextEditingController(text: profile?.taxCode ?? '');
    _contactController = TextEditingController(text: profile?.contactName ?? '');
    _phoneController = TextEditingController(text: profile?.contactPhone ?? '');
    _emailController = TextEditingController(text: profile?.email ?? '');
    _addressController = TextEditingController(text: profile?.addressSummary ?? '');
    _descriptionController = TextEditingController(text: profile?.description ?? '');
    _logoController = TextEditingController(text: profile?.logoUrl ?? '');
    _isActive = profile?.isActive ?? true;
  }

  @override
  void dispose() {
    _companyController.dispose();
    _taxCodeController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.profile != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEditMode ? 'Cập nhật hồ sơ doanh nghiệp' : 'Thêm hồ sơ doanh nghiệp',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _FormField(label: 'Tên doanh nghiệp', controller: _companyController),
              _FormField(label: 'Mã số thuế', controller: _taxCodeController),
              _FormField(label: 'Người liên hệ', controller: _contactController),
              _FormField(label: 'Số điện thoại', controller: _phoneController, keyboardType: TextInputType.phone),
              _FormField(label: 'Email', controller: _emailController, keyboardType: TextInputType.emailAddress),
              _FormField(label: 'Địa chỉ', controller: _addressController, maxLines: 3),
              _FormField(label: 'Mô tả doanh nghiệp', controller: _descriptionController, maxLines: 4),
              _FormField(
                label: 'Logo URL',
                controller: _logoController,
                keyboardType: TextInputType.url,
                onChanged: (_) => setState(() {}),
              ),
              if (_logoController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    _logoController.text.trim(),
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 140,
                      color: const Color(0xFFF8FAFC),
                      child: const Center(child: Text('Không tải được logo')),
                    ),
                  ),
                ),
              ],
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Cho phép doanh nghiệp hoạt động'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F5C45),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(isEditMode ? 'Lưu thay đổi' : 'Tạo hồ sơ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_companyController.text.trim().isEmpty || _taxCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên doanh nghiệp và mã số thuế là bắt buộc.')),
      );
      return;
    }

    Navigator.of(context).pop(
      EnterpriseProfile(
        userId: widget.profile?.userId,
        companyName: _companyController.text.trim(),
        taxCode: _taxCodeController.text.trim(),
        contactName: _contactController.text.trim().isEmpty ? null : _contactController.text.trim(),
        contactPhone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        addressSummary: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        logoUrl: _logoController.text.trim().isEmpty ? null : _logoController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        displayName: _companyController.text.trim(),
        isActive: _isActive,
        createdAt: widget.profile?.createdAt,
        productCount: widget.profile?.productCount ?? 0,
      ),
    );
  }
}

class _SectionBanner extends StatelessWidget {
  const _SectionBanner({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F5C45), Color(0xFF1B7F5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF6D860),
                foregroundColor: const Color(0xFF0F5C45),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _EnterpriseCard extends StatelessWidget {
  const _EnterpriseCard({
    required this.profile,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final EnterpriseProfile profile;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggleStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: profile.isActive
                    ? const Color(0xFFDDF6E8)
                    : const Color(0xFFFDE2E2),
                backgroundImage: (profile.logoUrl != null && profile.logoUrl!.isNotEmpty)
                    ? NetworkImage(profile.logoUrl!)
                    : null,
                child: (profile.logoUrl == null || profile.logoUrl!.isEmpty)
                    ? Icon(
                        Icons.apartment,
                        color: profile.isActive
                            ? const Color(0xFF0F5C45)
                            : const Color(0xFFB91C1C),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.companyName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('MST: ${profile.taxCode}'),
                    if (profile.contactName != null) Text('Liên hệ: ${profile.contactName}'),
                    if (profile.email != null) Text(profile.email!),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(label: 'Sản phẩm', value: '${profile.productCount}'),
              _InfoChip(
                label: 'Trạng thái',
                value: profile.isActive ? 'Hoạt động' : 'Tạm khóa',
              ),
              if (profile.contactPhone != null)
                _InfoChip(label: 'Điện thoại', value: profile.contactPhone!),
            ],
          ),
          if (profile.addressSummary != null) ...[
            const SizedBox(height: 12),
            Text(
              profile.addressSummary!,
              style: const TextStyle(color: Color(0xFF475467)),
            ),
          ],
          if (profile.description != null && profile.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              profile.description!,
              style: const TextStyle(color: Color(0xFF667085)),
            ),
          ],
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Cho phép hiển thị trên hệ thống'),
            value: profile.isActive,
            onChanged: onToggleStatus,
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 44) / 2;
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Color(0xFF667085))),
        ],
      ),
    );
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Color(0xFF667085))),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _RevenueLineChart extends StatelessWidget {
  const _RevenueLineChart({required this.series});

  final List<ChartSeriesPoint> series;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const _EmptyState(message: 'Chưa có dữ liệu doanh thu.');
    }

    final spots = series
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.value))
        .toList();
    final maxValue = series.map((e) => e.value).fold<double>(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (series.length - 1).toDouble(),
          minY: 0,
          maxY: maxValue <= 0 ? 1 : maxValue * 1.2,
          gridData: FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= series.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _shortLabel(series[index].label),
                      style: const TextStyle(fontSize: 10, color: Color(0xFF667085)),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) => Text(
                  _compactCurrency(value),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF667085)),
                ),
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF0F5C45),
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF0F5C45).withValues(alpha: 0.15),
              ),
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersBookingBarChart extends StatelessWidget {
  const _OrdersBookingBarChart({
    required this.orderSeries,
    required this.bookingSeries,
  });

  final List<ChartSeriesPoint> orderSeries;
  final List<ChartSeriesPoint> bookingSeries;

  @override
  Widget build(BuildContext context) {
    if (orderSeries.isEmpty || bookingSeries.isEmpty) {
      return const _EmptyState(message: 'Chưa có dữ liệu đơn hàng/thuê máy.');
    }

    final length = orderSeries.length < bookingSeries.length
        ? orderSeries.length
        : bookingSeries.length;
    if (length == 0) {
      return const _EmptyState(message: 'Chưa có dữ liệu đơn hàng/thuê máy.');
    }

    final maxValue = [
      ...orderSeries.take(length).map((e) => e.value),
      ...bookingSeries.take(length).map((e) => e.value),
    ].fold<double>(0, (a, b) => a > b ? a : b);

    final groups = List.generate(length, (index) {
      final orderValue = orderSeries[index].value;
      final bookingValue = bookingSeries[index].value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: orderValue,
            color: const Color(0xFFD84315),
            width: 10,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: bookingValue,
            color: const Color(0xFF1565C0),
            width: 10,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
        barsSpace: 4,
      );
    });

    return Column(
      children: [
        const _ChartLegend(),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              maxY: maxValue <= 0 ? 1 : maxValue * 1.2,
              minY: 0,
              barGroups: groups,
              gridData: FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10, color: Color(0xFF667085)),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.round();
                      if (index < 0 || index >= length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _shortLabel(orderSeries[index].label),
                          style: const TextStyle(fontSize: 10, color: Color(0xFF667085)),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _LegendItem(color: Color(0xFFD84315), label: 'Đơn hàng'),
        SizedBox(width: 16),
        _LegendItem(color: Color(0xFF1565C0), label: 'Thuê máy'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF667085))),
      ],
    );
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SubSectionTitle extends StatelessWidget {
  const _SubSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475467)),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.color,
  });

  final String label;
  final String valueLabel;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text(valueLabel)],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 10,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF667085))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label: $value'),
    );
  }
}

final NumberFormat _compactCurrencyFormatter =
    NumberFormat.compactCurrency(locale: 'vi_VN', symbol: '₫');
final NumberFormat _currencyFormatter =
    NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

String _compactCurrency(double value) {
  return _compactCurrencyFormatter.format(value);
}

String _formatCurrency(dynamic value) {
  if (value is num) {
    return _currencyFormatter.format(value);
  }
  final parsed = double.tryParse(value?.toString() ?? '') ?? 0.0;
  return _currencyFormatter.format(parsed);
}

String _shortLabel(String label) {
  if (label.contains('-')) {
    final parts = label.split('-');
    if (parts.length >= 2) {
      final year = parts[0];
      final month = parts[1];
      return '$month/${year.substring(year.length - 2)}';
    }
  }
  return label;
}

Color _statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'PAID':
      return const Color(0xFF0F5C45);
    case 'SHIPPING':
      return const Color(0xFF1565C0);
    case 'COMPLETED':
      return const Color(0xFF16A34A);
    case 'CANCELLED':
      return const Color(0xFFB91C1C);
    case 'DISPUTED':
      return const Color(0xFFB45309);
    default:
      return const Color(0xFF475467);
  }
}

bool _boolFromAny(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value == 1;
  if (value is String) return value == '1' || value.toLowerCase() == 'true';
  return false;
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: onChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF667085)),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
            ],
          ),
        ),
      ],
    );
  }
}
