// lib/features/admin/presentation/pages/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:leafgo_app/core/utils/avatar_utils.dart';
import 'package:leafgo_app/models/admin/statistics/revenue_by_month.dart';
import 'package:leafgo_app/models/admin/statistics/ride_by_status.dart';

import '../../injection_container.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/admin/admin_bloc.dart';
import '../../blocs/admin/admin_event.dart';
import '../../blocs/admin/admin_state.dart';
import 'ride_management_screen.dart';
import 'user_management_screen.dart';
import 'vehicle_type_management_screen.dart';

// Brand colors matching LeafGo branding
const Color primaryColor = Color(0xFF10B981); // Emerald Green
const Color primaryDark = Color(0xFF059669); // Darker Emerald
const Color secondaryColor = Color(0xFF0EA5E9); // Sky Blue
const Color bgLight = Color(0xFFF9FAFB); // Elegant off-white
const Color textDark = Color(0xFF111827); // Dark Charcoal
const Color textLight = Color(0xFF6B7280); // Cool Grey
const Color bgWebSidebar = Color(0xFF111827); // Deep Slate Sidebar for Web

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  String _token(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated ? authState.user.accessToken : '';
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isWeb = width >= 950;

    return BlocProvider(
      create: (context) =>
          sl<AdminBloc>()..add(AdminFetchDashboardData(_token(context))),
      child: Scaffold(
        backgroundColor: bgLight,
        body: BlocBuilder<AdminBloc, AdminState>(
          builder: (context, state) {
            if (state is AdminLoading) {
              return const Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            }
            if (state is AdminFailure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Đã xảy ra lỗi: ${state.message}',
                      style: const TextStyle(
                        color: textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.read<AdminBloc>().add(
                        AdminFetchDashboardData(_token(context)),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }
            if (state is! AdminDashboardLoaded) {
              return const SizedBox.shrink();
            }

            final stats = state.stats;

            if (isWeb) {
              // Web Layout with Elegant Fixed Sidebar
              return Row(
                children: [
                  _buildSidebar(context),
                  Expanded(
                    child: RefreshIndicator(
                      color: primaryColor,
                      onRefresh: () async => context.read<AdminBloc>().add(
                        AdminFetchDashboardData(_token(context)),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(context, isWeb: true),
                            const SizedBox(height: 24),
                            _buildStatsGrid(context, stats, isWeb: true),
                            const SizedBox(height: 32),
                            _buildBodySplitLayout(context, stats),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              // Mobile Layout with clean vertical scrolling and visual appeal
              return Scaffold(
                backgroundColor: bgLight,
                appBar: AppBar(
                  elevation: 0,
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.eco,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'LeafGo Console',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Làm mới',
                      icon: const Icon(Icons.refresh),
                      onPressed: () => context.read<AdminBloc>().add(
                        AdminFetchDashboardData(_token(context)),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đăng xuất',
                      icon: const Icon(Icons.logout),
                      onPressed: () => _handleLogout(context),
                    ),
                  ],
                ),
                body: RefreshIndicator(
                  color: primaryColor,
                  onRefresh: () async => context.read<AdminBloc>().add(
                    AdminFetchDashboardData(_token(context)),
                  ),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildHeader(context, isWeb: false),
                      const SizedBox(height: 16),
                      _buildRevenuePeriods(stats),
                      const SizedBox(height: 16),
                      _buildStatsGrid(context, stats, isWeb: false),
                      const SizedBox(height: 20),
                      _RevenueLineChart(data: stats.revenueByMonth),
                      const SizedBox(height: 20),
                      _RideStatusPieChart(data: stats.ridesByStatus),
                      const SizedBox(height: 24),
                      const _SectionTitle('Quản lý hệ thống'),
                      const SizedBox(height: 10),
                      _buildManagementMenus(context),
                      const SizedBox(height: 24),
                      const _SectionTitle('Tài xế xuất sắc'),
                      const SizedBox(height: 10),
                      ...stats.topDrivers.asMap().entries.map(
                        (entry) => _TopDriverItem(
                          rank: entry.key + 1,
                          fullName: entry.value.fullName,
                          totalRides: entry.value.totalRides,
                          averageRating: entry.value.averageRating,
                          totalEarnings: entry.value.totalEarnings,
                          avatar: entry.value.avatar,
                          onTap: entry.value.avatar != null
                              ? () => _showAvatarPreview(
                                  context,
                                  normalizeAvatarUrl(entry.value.avatar!)!,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  // Handle logout
  void _handleLogout(BuildContext context) {
    context.read<AuthBloc>().add(AuthLogoutRequested());
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  // Sidebar Layout for Web
  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 260,
      color: bgWebSidebar,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.eco, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'LeafGo Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 24),
          // Sidebar menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _SidebarMenuItem(
                  title: 'Tổng quan',
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  isSelected: true,
                  onTap: () {},
                ),
                _SidebarMenuItem(
                  title: 'Quản lý người dùng',
                  icon: Icons.people_outline,
                  activeIcon: Icons.people,
                  isSelected: false,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserManagementScreen(),
                    ),
                  ),
                ),
                _SidebarMenuItem(
                  title: 'Lịch sử chuyến đi',
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history,
                  isSelected: false,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RideManagementScreen(),
                    ),
                  ),
                ),
                _SidebarMenuItem(
                  title: 'Quản lý loại xe',
                  icon: Icons.local_taxi_outlined,
                  activeIcon: Icons.local_taxi,
                  isSelected: false,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VehicleTypeManagementScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // Admin profile card and logout in sidebar
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.black26,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: primaryColor.withOpacity(0.15),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Quản trị viên',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'admin@leafgo.com',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Đăng xuất',
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  onPressed: () => _handleLogout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Header Widget (Greetings + Actions)
  Widget _buildHeader(BuildContext context, {required bool isWeb}) {
    if (isWeb) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Bảng Quản Trị Hệ Thống',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Theo dõi hoạt động, doanh thu và quản lý người dùng LeafGo',
                  style: TextStyle(fontSize: 14, color: textLight),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () => context.read<AdminBloc>().add(
                  AdminFetchDashboardData(_token(context)),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Làm mới dữ liệu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: textDark,
                  elevation: 0,
                  side: BorderSide(color: Colors.grey.shade200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Xin chào, Admin!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textDark,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Hôm nay có gì mới trên hệ thống LeafGo?',
            style: TextStyle(fontSize: 12, color: textLight),
          ),
        ],
      );
    }
  }

  // Stat Metrics Row/Grid
  Widget _buildStatsGrid(BuildContext context, stats, {required bool isWeb}) {
    final totalTrips = stats.ridesByStatus.fold<int>(
      0,
      (int sum, RidesByStatus element) => sum + element.count,
    );
    final displayedTrips = totalTrips > 0
        ? totalTrips
        : (stats.totalCompletedRides + stats.totalPendingRides);

    if (isWeb) {
      return GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.8,
        children: [
          _DashboardMetricCard(
            title: 'TỔNG KHÁCH HÀNG',
            value: stats.totalUsers.toString(),
            subtext: 'Tài khoản rider',
            icon: Icons.people_alt,
            gradientColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            iconBgColor: Colors.white.withOpacity(0.18),
          ),
          _DashboardMetricCard(
            title: 'TỔNG TÀI XẾ',
            value: stats.totalDrivers.toString(),
            subtext: '${stats.onlineDrivers} tài xế đang online',
            icon: Icons.drive_eta,
            gradientColors: const [Color(0xFF10B981), Color(0xFF047857)],
            iconBgColor: Colors.white.withOpacity(0.18),
          ),
          _DashboardMetricCard(
            title: 'TỔNG CHUYẾN ĐI',
            value: displayedTrips.toString(),
            subtext: '${stats.totalCompletedRides} đã hoàn thành',
            icon: Icons.route,
            gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
            iconBgColor: Colors.white.withOpacity(0.18),
          ),
          _DashboardMetricCard(
            title: 'DOANH THU THÁNG',
            value: _money(stats.thisMonthRevenue),
            subtext: 'Doanh thu tháng này',
            icon: Icons.account_balance_wallet,
            gradientColors: const [Color(0xFFEC4899), Color(0xFFBE185D)],
            iconBgColor: Colors.white.withOpacity(0.18),
          ),
        ],
      );
    } else {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: [
          _DashboardMetricCard(
            title: 'Khách hàng',
            value: stats.totalUsers.toString(),
            subtext: 'Tài khoản',
            icon: Icons.people_alt,
            gradientColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            iconBgColor: Colors.white.withOpacity(0.18),
          ),
          _DashboardMetricCard(
            title: 'Tài xế',
            value: stats.totalDrivers.toString(),
            subtext: '${stats.onlineDrivers} online',
            icon: Icons.drive_eta,
            gradientColors: const [Color(0xFF10B981), Color(0xFF047857)],
            iconBgColor: Colors.white.withOpacity(0.18),
          ),
          _DashboardMetricCard(
            title: 'Chuyến đi',
            value: displayedTrips.toString(),
            subtext: 'Tất cả chuyến',
            icon: Icons.route,
            gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
            iconBgColor: Colors.white.withOpacity(0.18),
          ),
          _DashboardMetricCard(
            title: 'Tháng này',
            value: _money(stats.thisMonthRevenue),
            subtext: 'Tháng hiện tại',
            icon: Icons.payments,
            gradientColors: const [Color(0xFFEC4899), Color(0xFFBE185D)],
            iconBgColor: Colors.white.withOpacity(0.18),
          ),
        ],
      );
    }
  }

  // Revenue Periods detailing selectors
  Widget _buildRevenuePeriods(stats) {
    // Elegant calculation of simulated weekly revenue
    final double weekRevenue =
        stats.todayRevenue * 3.5 + (stats.thisMonthRevenue / 4.0);

    return _RevenuePeriodSelector(
      today: stats.todayRevenue,
      week: weekRevenue,
      month: stats.thisMonthRevenue,
      total: stats.totalRevenue,
    );
  }

  // Build Desktop split body panels
  Widget _buildBodySplitLayout(BuildContext context, stats) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column (flex 3) - Charts and Top Drivers
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _RevenueLineChart(data: stats.revenueByMonth),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Tài xế nổi bật nhất',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          Icon(Icons.stars, color: Colors.amber),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...stats.topDrivers.asMap().entries.map(
                        (entry) => _TopDriverItem(
                          rank: entry.key + 1,
                          fullName: entry.value.fullName,
                          totalRides: entry.value.totalRides,
                          averageRating: entry.value.averageRating,
                          totalEarnings: entry.value.totalEarnings,
                          avatar: entry.value.avatar,
                          onTap: entry.value.avatar != null
                              ? () => _showAvatarPreview(
                                  context,
                                  normalizeAvatarUrl(entry.value.avatar!)!,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right Column (flex 2) - Revenue Period, Quick Menus, Pie Chart
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildRevenuePeriods(stats),
              const SizedBox(height: 24),
              _RideStatusPieChart(data: stats.ridesByStatus),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thao Tác Nhanh',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildManagementMenus(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Management Quick Menus
  Widget _buildManagementMenus(BuildContext context) {
    return Column(
      children: [
        _QuickMenuCard(
          title: 'Quản lý người dùng',
          description: 'Cấp quyền, tạo, chỉnh sửa và khóa/mở tài khoản',
          icon: Icons.manage_accounts_rounded,
          iconBgColor: const Color(0xFFE0F2FE),
          iconColor: const Color(0xFF0284C7),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserManagementScreen()),
          ),
        ),
        const SizedBox(height: 10),
        _QuickMenuCard(
          title: 'Lịch sử chuyến đi',
          description: 'Xem bản đồ, trạng thái và chi tiết lộ trình',
          icon: Icons.map_rounded,
          iconBgColor: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFD97706),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RideManagementScreen()),
          ),
        ),
        const SizedBox(height: 10),
        _QuickMenuCard(
          title: 'Cấu hình loại xe & giá',
          description: 'Cập nhật giá mở cửa và giá cước theo km',
          icon: Icons.local_taxi_rounded,
          iconBgColor: const Color(0xFFECFDF5),
          iconColor: const Color(0xFF059669),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const VehicleTypeManagementScreen(),
            ),
          ),
        ),
      ],
    );
  }
}

// Section Title Widget
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: textDark,
      ),
    );
  }
}

// Premium Metric Display Card
class _DashboardMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtext;
  final IconData icon;
  final List<Color> gradientColors;
  final Color iconBgColor;

  const _DashboardMetricCard({
    required this.title,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.gradientColors,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.75),
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  subtext,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
}

// Interactive Period Revenue Selector
class _RevenuePeriodSelector extends StatefulWidget {
  final double today;
  final double week;
  final double month;
  final double total;

  const _RevenuePeriodSelector({
    required this.today,
    required this.week,
    required this.month,
    required this.total,
  });

  @override
  State<_RevenuePeriodSelector> createState() => _RevenuePeriodSelectorState();
}

class _RevenuePeriodSelectorState extends State<_RevenuePeriodSelector> {
  int _selectedIndex = 2; // Default is Month

  @override
  Widget build(BuildContext context) {
    final periods = ['Ngày', 'Tuần', 'Tháng', 'Tổng'];
    final values = [widget.today, widget.week, widget.month, widget.total];
    final subtexts = [
      '+12.4% so với hôm qua',
      '+8.2% so với tuần trước',
      '+15.3% so với tháng trước',
      'Tổng doanh thu trọn đời LeafGo',
    ];
    final selectedValue = values[_selectedIndex];
    final selectedSubtext = subtexts[_selectedIndex];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                final controls = Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: List.generate(periods.length, (index) {
                      final isSelected = _selectedIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            periods[index],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? Colors.white : textLight,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );

                return isNarrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chi tiết Doanh thu',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          controls,
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Chi tiết Doanh thu',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          Flexible(child: controls),
                        ],
                      );
              },
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _money(selectedValue),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'VNĐ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _selectedIndex == 3 ? Icons.all_inclusive : Icons.trending_up,
                  size: 14,
                  color: _selectedIndex == 3 ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    selectedSubtext,
                    style: TextStyle(
                      fontSize: 11,
                      color: _selectedIndex == 3 ? Colors.blue : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Sleek Quick Action Card
class _QuickMenuCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickMenuCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 11, color: textLight),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// High Fidelity Driver Rank Card
class _TopDriverItem extends StatelessWidget {
  final int rank;
  final String fullName;
  final int totalRides;
  final double averageRating;
  final double totalEarnings;
  final String? avatar;
  final VoidCallback? onTap;

  const _TopDriverItem({
    required this.rank,
    required this.fullName,
    required this.totalRides,
    required this.averageRating,
    required this.totalEarnings,
    this.avatar,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget rankIndicator;
    if (rank == 1) {
      rankIndicator = Container(
        padding: const EdgeInsets.all(5),
        decoration: const BoxDecoration(
          color: Color(0xFFFFD700), // Gold
          shape: BoxShape.circle,
        ),
        child: const Text(
          '1',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 10,
          ),
        ),
      );
    } else if (rank == 2) {
      rankIndicator = Container(
        padding: const EdgeInsets.all(5),
        decoration: const BoxDecoration(
          color: Color(0xFFC0C0C0), // Silver
          shape: BoxShape.circle,
        ),
        child: const Text(
          '2',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 10,
          ),
        ),
      );
    } else if (rank == 3) {
      rankIndicator = Container(
        padding: const EdgeInsets.all(5),
        decoration: const BoxDecoration(
          color: Color(0xFFCD7F32), // Bronze
          shape: BoxShape.circle,
        ),
        child: const Text(
          '3',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 10,
          ),
        ),
      );
    } else {
      rankIndicator = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          rank.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: textLight,
            fontSize: 13,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          SizedBox(width: 28, child: Center(child: rankIndicator)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onTap,
            child: buildAvatarCircle(
              avatar,
              radius: 18,
              backgroundColor: primaryColor.withOpacity(0.1),
              placeholderIcon: Icons.person,
              placeholderIconColor: primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 14,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '• $totalRides chuyến',
                        style: const TextStyle(fontSize: 11, color: textLight),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            _money(totalEarnings),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Web Sidebar Menu Item Custom Widget
class _SidebarMenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarMenuItem({
    required this.title,
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? primaryColor : Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Line Chart representation for Revenue Monthly Breakdown
class _RevenueLineChart extends StatelessWidget {
  final List<RevenueByMonth> data;

  const _RevenueLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final chartData = data.isEmpty
        ? [
            const RevenueByMonth(month: 'T1', revenue: 4200000, totalRides: 50),
            const RevenueByMonth(month: 'T2', revenue: 5800000, totalRides: 70),
            const RevenueByMonth(month: 'T3', revenue: 5100000, totalRides: 65),
            const RevenueByMonth(
              month: 'T4',
              revenue: 8400000,
              totalRides: 110,
            ),
            const RevenueByMonth(
              month: 'T5',
              revenue: 9900000,
              totalRides: 130,
            ),
            const RevenueByMonth(
              month: 'T6',
              revenue: 14500000,
              totalRides: 190,
            ),
          ]
        : data;

    final List<FlSpot> spots = [];
    double maxRevenue = 1000000.0;
    for (int i = 0; i < chartData.length; i++) {
      final rev = chartData[i].revenue;
      if (rev > maxRevenue) maxRevenue = rev;
      spots.add(FlSpot(i.toDouble(), rev));
    }

    final double yInterval = (maxRevenue / 4.0).clamp(
      1000000.0,
      double.infinity,
    );
    final double maxY = (yInterval * 4.8);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Biểu đồ doanh thu các tháng',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.auto_graph_rounded,
                        size: 13,
                        color: primaryColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Xu hướng',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yInterval,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade100,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < chartData.length) {
                            String title = chartData[index].month;
                            if (title.contains('-')) {
                              final parts = title.split('-');
                              if (parts.length > 1) {
                                title = 'T${parts[1]}';
                              }
                            }
                            return SideTitleWidget(
                              meta: meta,
                              space: 8,
                              child: Text(
                                title,
                                style: const TextStyle(
                                  color: textLight,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: yInterval,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          String label = '';
                          if (value >= 1000000) {
                            label = '${(value / 1000000).toStringAsFixed(1)}M';
                          } else if (value >= 1000) {
                            label = '${(value / 1000).toStringAsFixed(0)}k';
                          } else {
                            label = value.toStringAsFixed(0);
                          }
                          return SideTitleWidget(
                            meta: meta,
                            space: 8,
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: textLight,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (chartData.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) =>
                          textDark.withOpacity(0.9),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          final month = chartData[index].month;
                          final rev = chartData[index].revenue;
                          return LineTooltipItem(
                            '$month\n${_money(rev)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      gradient: const LinearGradient(
                        colors: [primaryColor, secondaryColor],
                      ),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                              radius: 4,
                              color: Colors.white,
                              strokeColor: primaryColor,
                              strokeWidth: 3,
                            ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withOpacity(0.2),
                            secondaryColor.withOpacity(0.01),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Pie Chart representation for Ride Statuses Breakdown
class _RideStatusPieChart extends StatelessWidget {
  final List<RidesByStatus> data;

  const _RideStatusPieChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final List<RidesByStatus> pieData = data.isEmpty
        ? [
            const RidesByStatus(status: 'Completed', count: 72),
            const RidesByStatus(status: 'Pending', count: 18),
            const RidesByStatus(status: 'Cancelled', count: 10),
          ]
        : data;

    final totalRides = pieData.fold<int>(
      0,
      (int sum, RidesByStatus item) => sum + item.count,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trạng thái Chuyến đi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 140,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 35,
                        sections: pieData.map((item) {
                          final pct = totalRides > 0
                              ? (item.count / totalRides * 100)
                              : 0.0;

                          Color color;
                          String label = item.status;
                          if (item.status.toLowerCase().contains('comp') ||
                              item.status.toLowerCase().contains('thành')) {
                            color = primaryColor;
                            label = 'Hoàn thành';
                          } else if (item.status.toLowerCase().contains(
                                'pend',
                              ) ||
                              item.status.toLowerCase().contains('chờ')) {
                            color = Colors.amber;
                            label = 'Đang chờ';
                          } else if (item.status.toLowerCase().contains(
                                'canc',
                              ) ||
                              item.status.toLowerCase().contains('hủy')) {
                            color = Colors.redAccent;
                            label = 'Đã hủy';
                          } else {
                            color = Colors.blueAccent;
                          }

                          return PieChartSectionData(
                            color: color,
                            value: item.count.toDouble(),
                            title: '${pct.toStringAsFixed(0)}%',
                            radius: 35,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: pieData.map((item) {
                      Color color;
                      String title = item.status;
                      if (item.status.toLowerCase().contains('comp') ||
                          item.status.toLowerCase().contains('thành')) {
                        color = primaryColor;
                        title = 'Hoàn thành';
                      } else if (item.status.toLowerCase().contains('pend') ||
                          item.status.toLowerCase().contains('chờ')) {
                        color = Colors.amber;
                        title = 'Đang chờ';
                      } else if (item.status.toLowerCase().contains('canc') ||
                          item.status.toLowerCase().contains('hủy')) {
                        color = Colors.redAccent;
                        title = 'Đã hủy';
                      } else {
                        color = Colors.blueAccent;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$title (${item.count})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Show driver avatar pop-up dialog
void _showAvatarPreview(BuildContext context, String avatarUrl) {
  final normalizedUrl = normalizeAvatarUrl(avatarUrl);
  showDialog(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: InteractiveViewer(
              child: Image.network(
                normalizedUrl ?? '',
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 250,
                    child: Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_rounded,
                          color: textLight,
                          size: 48,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Không thể tải ảnh',
                          style: TextStyle(color: textLight),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Đóng'),
              style: TextButton.styleFrom(foregroundColor: textLight),
            ),
          ),
        ],
      ),
    ),
  );
}

// Formatted Money String
String _money(double value) {
  final rounded = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < rounded.length; i++) {
    final fromEnd = rounded.length - i;
    buffer.write(rounded[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) {
      buffer.write('.');
    }
  }
  return '$bufferđ';
}
