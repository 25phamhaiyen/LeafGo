// lib/features/admin/presentation/pages/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';
import 'user_management_screen.dart'; // We'll create this next

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final authState = context.read<AuthBloc>().state;
        final token = (authState is AuthAuthenticated) ? authState.user.accessToken : '';
        return sl<AdminBloc>()..add(AdminFetchDashboardData(token));
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                final authState = context.read<AuthBloc>().state;
                final token = (authState is AuthAuthenticated) ? authState.user.accessToken : '';
                context.read<AdminBloc>().add(AdminFetchDashboardData(token));
              },
            ),
          ],
        ),
        body: BlocBuilder<AdminBloc, AdminState>(
          builder: (context, state) {
            if (state is AdminLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is AdminDashboardLoaded) {
              final stats = state.stats;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng quan',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _StatCard(
                          label: 'Tổng số users',
                          value: stats.totalUsers.toString(),
                          icon: Icons.people,
                          color: Colors.blue,
                        ),
                        _StatCard(
                          label: 'Tổng số tài xế online',
                          value: '${stats.onlineDrivers}/${stats.totalDrivers}',
                          icon: Icons.drive_eta,
                          color: Colors.green,
                        ),
                        _StatCard(
                          label: 'Số chuyến đi hôm nay',
                          value: stats.todayRides.toString(),
                          icon: Icons.route,
                          color: Colors.orange,
                        ),
                        _StatCard(
                          label: 'Doanh thu',
                          value: '${stats.totalRevenue.toInt()}đ',
                          icon: Icons.payments,
                          color: Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _MenuTile(
                      title: 'Quản lý Users',
                      subtitle: 'Quản lý khách hàng và tài xế',
                      icon: Icons.manage_accounts,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UserManagementScreen()),
                      ),
                    ),
                    _MenuTile(
                      title: 'Lịch sử chuyến đi',
                      subtitle: 'Xem và theo dõi tất cả chuyến đi',
                      icon: Icons.history,
                      onTap: () {
                        // Navigate to Ride Management
                      },
                    ),
                    _MenuTile(
                      title: 'Quản lý loại xe',
                      subtitle: 'Quản lý loại xe',
                      icon: Icons.car_repair,
                      onTap: () {
                        // Navigate to Vehicle Type Management
                      },
                    ),
                  ],
                ),
              );
            } else if (state is AdminFailure) {
              return Center(child: Text('Lỗi: ${state.message}'));
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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

  const _MenuTile({required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
