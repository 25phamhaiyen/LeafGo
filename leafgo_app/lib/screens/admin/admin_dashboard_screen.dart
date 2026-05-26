// lib/features/admin/presentation/pages/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leafgo_app/core/utils/avatar_utils.dart';

import '../../injection_container.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/admin/admin_bloc.dart';
import '../../blocs/admin/admin_event.dart';
import '../../blocs/admin/admin_state.dart';
import 'ride_management_screen.dart';
import 'user_management_screen.dart';
import 'vehicle_type_management_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  String _token(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated ? authState.user.accessToken : '';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<AdminBloc>()..add(AdminFetchDashboardData(_token(context))),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Admin Dashboard'),
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
                  onPressed: () {
                    context.read<AuthBloc>().add(AuthLogoutRequested());
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  },
                ),
              ],
            ),
            body: BlocBuilder<AdminBloc, AdminState>(
              builder: (context, state) {
                if (state is AdminLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AdminFailure) {
                  return Center(child: Text('Lỗi: ${state.message}'));
                }
                if (state is! AdminDashboardLoaded) {
                  return const SizedBox.shrink();
                }

                final stats = state.stats;
                return RefreshIndicator(
                  onRefresh: () async => context.read<AdminBloc>().add(
                    AdminFetchDashboardData(_token(context)),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Tổng quan',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: MediaQuery.of(context).size.width > 700
                            ? 4
                            : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.35,
                        children: [
                          _StatCard(
                            label: 'Người dùng',
                            value: stats.totalUsers.toString(),
                            icon: Icons.people,
                            color: Colors.blue,
                          ),
                          _StatCard(
                            label: 'Tài xế online',
                            value:
                                '${stats.onlineDrivers}/${stats.totalDrivers}',
                            icon: Icons.drive_eta,
                            color: Colors.green,
                          ),
                          _StatCard(
                            label: 'Chuyến hôm nay',
                            value: stats.todayRides.toString(),
                            icon: Icons.route,
                            color: Colors.orange,
                          ),
                          _StatCard(
                            label: 'Doanh thu tháng',
                            value: _money(stats.thisMonthRevenue),
                            icon: Icons.payments,
                            color: Colors.teal,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _MenuTile(
                        title: 'Quản lý người dùng',
                        subtitle: 'Tạo, sửa, khóa/mở và xóa tài khoản',
                        icon: Icons.manage_accounts,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserManagementScreen(),
                          ),
                        ),
                      ),
                      _MenuTile(
                        title: 'Lịch sử chuyến đi',
                        subtitle: 'Tra cứu chuyến đi theo trạng thái',
                        icon: Icons.history,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RideManagementScreen(),
                          ),
                        ),
                      ),
                      _MenuTile(
                        title: 'Quản lý loại xe',
                        subtitle: 'Cấu hình giá mở cửa và giá theo km',
                        icon: Icons.local_taxi,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VehicleTypeManagementScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionTitle('Tài xế nổi bật'),
                      ...stats.topDrivers.map(
                        (driver) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          onTap: driver.avatar != null
                              ? () => _showAvatarPreview(
                                  context,
                                  normalizeAvatarUrl(driver.avatar!)!,
                                )
                              : null,
                          leading: buildAvatarCircle(
                            driver.avatar,
                            radius: 20,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            placeholderIcon: Icons.person,
                            placeholderIconColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                          ),
                          title: Text(driver.fullName),
                          subtitle: Text(
                            '${driver.totalRides} chuyến • ${driver.averageRating.toStringAsFixed(1)} sao',
                          ),
                          trailing: Text(_money(driver.totalEarnings)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

void _showAvatarPreview(BuildContext context, String avatarUrl) {
  final normalizedUrl = normalizeAvatarUrl(avatarUrl);
  showDialog(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InteractiveViewer(
              child: Image.network(
                normalizedUrl ?? '',
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 200,
                  child: Center(child: Text('Không thể tải ảnh')),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    ),
  );
}

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
