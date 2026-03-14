import 'package:flutter/material.dart';

import '../../data/datasource/admin_local_datasource.dart';
import '../../domain/entities/enterprise_profile.dart';
import '../../domain/entities/system_dashboard_stats.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({
    super.key,
    required this.adminLocalDataSource,
  });

  final AdminLocalDataSource adminLocalDataSource;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<List<EnterpriseProfile>> _profilesFuture;
  late Future<SystemDashboardStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _reloadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reloadData() {
    _profilesFuture = widget.adminLocalDataSource.getEnterpriseProfiles();
    _statsFuture = widget.adminLocalDataSource.getSystemDashboardStats();
  }

  Future<void> _refreshAll() async {
    setState(_reloadData);
    await Future.wait([_profilesFuture, _statsFuture]);
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
        ],
      ),
    );
  }

  Future<void> _handleSaveProfile(EnterpriseProfile profile) async {
    await widget.adminLocalDataSource.saveEnterpriseProfile(profile);
    await _refreshAll();
  }

  Future<void> _handleToggleStatus(int userId, bool isActive) async {
    await widget.adminLocalDataSource.toggleEnterpriseStatus(userId, isActive);
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
                title: 'Top doanh nghiệp theo số sản phẩm',
                child: Column(
                  children: stats.topEnterprises.isEmpty
                      ? const [
                          _EmptyState(message: 'Chưa có doanh nghiệp nào phát sinh sản phẩm.')
                        ]
                      : stats.topEnterprises.map((enterprise) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: (enterprise['IsActive'] as int? ?? 0) == 1
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFEE2E2),
                              child: Icon(
                                Icons.business,
                                color: (enterprise['IsActive'] as int? ?? 0) == 1
                                    ? const Color(0xFF0F5C45)
                                    : const Color(0xFFB91C1C),
                              ),
                            ),
                            title: Text(enterprise['CompanyName'] as String? ?? 'Không rõ'),
                            trailing: Text('${enterprise['ProductCount'] ?? 0} SP'),
                          );
                        }).toList(),
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
                            title: Text(admin['FullName'] as String? ?? 'Admin'),
                            subtitle: Text(admin['Position'] as String? ?? 'Chưa cập nhật vị trí'),
                            trailing: Text(
                              (admin['IsActive'] as int? ?? 0) == 1 ? 'Đang hoạt động' : 'Tạm khóa',
                              style: TextStyle(
                                color: (admin['IsActive'] as int? ?? 0) == 1
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
                child: Icon(
                  Icons.apartment,
                  color: profile.isActive
                      ? const Color(0xFF0F5C45)
                      : const Color(0xFFB91C1C),
                ),
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

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;

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