// lib/features/admin/presentation/pages/user_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _searchCtrl = TextEditingController();
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final authState = context.read<AuthBloc>().state;
        final token = (authState is AuthAuthenticated) ? authState.user.accessToken : '';
        return sl<AdminBloc>()..add(AdminFetchUsers(accessToken: token));
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý Users'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm users...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () => _onSearch(context),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onSubmitted: (_) => _onSearch(context),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip(context, 'Tất cả', null),
                        _filterChip(context, 'Người dùng', 'User'),
                        _filterChip(context, 'Tài xế', 'Driver'),
                        _filterChip(context, 'Quản trị viên', 'Admin'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: BlocBuilder<AdminBloc, AdminState>(
          builder: (context, state) {
            if (state is AdminLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is AdminUsersLoaded) {
              final users = state.users.items;
              if (users.isEmpty) {
                return const Center(child: Text('Không tìm thấy người dùng.'));
              }
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
                      child: user.avatar == null ? Text(user.fullName[0].toUpperCase()) : null,
                    ),
                    title: Text(user.fullName),
                    subtitle: Text('${user.role} • ${user.phoneNumber}'),
                    trailing: Icon(
                      Icons.circle,
                      size: 12,
                      color: user.isActive ? Colors.green : Colors.red,
                    ),
                    onTap: () {
                      // Show details
                    },
                  );
                },
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

  Widget _filterChip(BuildContext context, String label, String? role) {
    final isSelected = _selectedRole == role;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedRole = role);
          _onSearch(context);
        },
      ),
    );
  }

  void _onSearch(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final token = (authState is AuthAuthenticated) ? authState.user.accessToken : '';
    context.read<AdminBloc>().add(AdminFetchUsers(
      accessToken: token,
      search: _searchCtrl.text,
      role: _selectedRole,
    ));
  }
}
