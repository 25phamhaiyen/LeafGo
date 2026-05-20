// lib/features/admin/presentation/pages/user_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/models/admin_models.dart';
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
  String? _role;
  bool? _isActive;
  bool? _isOnline;
  int _page = 1;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _token(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated ? authState.user.accessToken : '';
  }

  void _fetch(BuildContext context, {int? page}) {
    _page = page ?? _page;
    context.read<AdminBloc>().add(
      AdminFetchUsers(
        accessToken: _token(context),
        page: _page,
        role: _role,
        search: _searchCtrl.text.trim().isEmpty
            ? null
            : _searchCtrl.text.trim(),
        isActive: _isActive,
        isOnline: _isOnline,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<AdminBloc>()..add(AdminFetchUsers(accessToken: _token(context))),
      child: Builder(
        builder: (context) {
          return BlocListener<AdminBloc, AdminState>(
            listener: (context, state) {
              if (state is AdminActionSuccess) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
                _fetch(context, page: _page);
              }
              if (state is AdminFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: ${state.message}')),
                );
              }
            },
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Quản lý người dùng'),
                actions: [
                  IconButton(
                    tooltip: 'Thêm người dùng',
                    icon: const Icon(Icons.person_add_alt_1),
                    onPressed: () => _showUserForm(context),
                  ),
                ],
              ),
              body: Column(
                children: [
                  _Filters(
                    searchCtrl: _searchCtrl,
                    role: _role,
                    isActive: _isActive,
                    isOnline: _isOnline,
                    onRoleChanged: (value) {
                      setState(() => _role = value);
                      _fetch(context, page: 1);
                    },
                    onStatusChanged: (value) {
                      setState(() => _isActive = value);
                      _fetch(context, page: 1);
                    },
                    onOnlineChanged: (value) {
                      setState(() => _isOnline = value);
                      _fetch(context, page: 1);
                    },
                    onSearch: () => _fetch(context, page: 1),
                  ),
                  Expanded(
                    child: BlocBuilder<AdminBloc, AdminState>(
                      builder: (context, state) {
                        if (state is AdminLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (state is AdminUsersLoaded) {
                          return _UserList(
                            users: state.users,
                            onRefresh: () async => _fetch(context),
                            onPageChanged: (page) =>
                                _fetch(context, page: page),
                            onEdit: (user) =>
                                _showUserForm(context, user: user),
                            onToggle: (user) => context.read<AdminBloc>().add(
                              AdminToggleUserStatus(
                                accessToken: _token(context),
                                id: user.id,
                                isActive: !user.isActive,
                              ),
                            ),
                            onDelete: (user) => _confirmDelete(context, user),
                          );
                        }
                        if (state is AdminFailure) {
                          return Center(child: Text('Lỗi: ${state.message}'));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AdminUserModel user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa người dùng'),
        content: Text('Xóa tài khoản ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    context.read<AdminBloc>().add(
      AdminDeleteUser(accessToken: _token(context), id: user.id),
    );
  }

  Future<void> _showUserForm(
    BuildContext context, {
    AdminUserModel? user,
  }) async {
    final fullNameCtrl = TextEditingController(text: user?.fullName ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final phoneCtrl = TextEditingController(text: user?.phoneNumber ?? '');
    final passwordCtrl = TextEditingController();
    var role = user?.role ?? 'User';
    var isActive = user?.isActive ?? true;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(user == null ? 'Thêm người dùng' : 'Sửa người dùng'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: fullNameCtrl,
                      decoration: const InputDecoration(labelText: 'Họ tên'),
                      validator: _required,
                    ),
                    TextFormField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                      ),
                      validator: _required,
                    ),
                    if (user == null) ...[
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: _required,
                      ),
                      TextFormField(
                        controller: passwordCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Mật khẩu',
                        ),
                        obscureText: true,
                        validator: _required,
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: role,
                        decoration: const InputDecoration(labelText: 'Vai trò'),
                        items: const [
                          DropdownMenuItem(value: 'User', child: Text('User')),
                          DropdownMenuItem(
                            value: 'Driver',
                            child: Text('Driver'),
                          ),
                          DropdownMenuItem(
                            value: 'Admin',
                            child: Text('Admin'),
                          ),
                        ],
                        onChanged: (value) =>
                            setDialogState(() => role = value ?? 'User'),
                      ),
                    ] else
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Đang hoạt động'),
                        value: isActive,
                        onChanged: (value) =>
                            setDialogState(() => isActive = value),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  final bloc = context.read<AdminBloc>();
                  if (user == null) {
                    bloc.add(
                      AdminCreateUser(
                        accessToken: _token(context),
                        email: emailCtrl.text.trim(),
                        password: passwordCtrl.text,
                        fullName: fullNameCtrl.text.trim(),
                        phoneNumber: phoneCtrl.text.trim(),
                        role: role,
                      ),
                    );
                  } else {
                    bloc.add(
                      AdminUpdateUser(
                        accessToken: _token(context),
                        id: user.id,
                        fullName: fullNameCtrl.text.trim(),
                        phoneNumber: phoneCtrl.text.trim(),
                        isActive: isActive,
                      ),
                    );
                  }
                  Navigator.pop(dialogContext);
                },
                child: const Text('Lưu'),
              ),
            ],
          );
        },
      ),
    );

    fullNameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    passwordCtrl.dispose();
  }
}

class _Filters extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String? role;
  final bool? isActive;
  final bool? isOnline;
  final ValueChanged<String?> onRoleChanged;
  final ValueChanged<bool?> onStatusChanged;
  final ValueChanged<bool?> onOnlineChanged;
  final VoidCallback onSearch;

  const _Filters({
    required this.searchCtrl,
    required this.role,
    required this.isActive,
    required this.isOnline,
    required this.onRoleChanged,
    required this.onStatusChanged,
    required this.onOnlineChanged,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: searchCtrl,
            decoration: InputDecoration(
              hintText: 'Tìm theo tên, email, số điện thoại',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Tìm kiếm',
                icon: const Icon(Icons.send),
                onPressed: onSearch,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onSubmitted: (_) => onSearch(),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('Tất cả', role == null, () => onRoleChanged(null)),
                _chip('User', role == 'User', () => onRoleChanged('User')),
                _chip(
                  'Driver',
                  role == 'Driver',
                  () => onRoleChanged('Driver'),
                ),
                _chip('Admin', role == 'Admin', () => onRoleChanged('Admin')),
                const SizedBox(width: 8),
                _chip(
                  'Đang hoạt động',
                  isActive == true,
                  () => onStatusChanged(isActive == true ? null : true),
                ),
                _chip(
                  'Bị khóa',
                  isActive == false,
                  () => onStatusChanged(isActive == false ? null : false),
                ),
                _chip(
                  'Online',
                  isOnline == true,
                  () => onOnlineChanged(isOnline == true ? null : true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final PaginatedResponse<AdminUserModel> users;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<AdminUserModel> onEdit;
  final ValueChanged<AdminUserModel> onToggle;
  final ValueChanged<AdminUserModel> onDelete;

  const _UserList({
    required this.users,
    required this.onRefresh,
    required this.onPageChanged,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (users.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: const [
            SizedBox(height: 160),
            Center(child: Text('Không tìm thấy người dùng.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 12),
        itemCount: users.items.length + 1,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == users.items.length) {
            return _Pagination(
              page: users.page,
              totalPages: users.totalPages,
              hasPreviousPage: users.hasPreviousPage,
              hasNextPage: users.hasNextPage,
              onPageChanged: onPageChanged,
            );
          }
          final user = users.items[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: user.avatar != null
                  ? NetworkImage(user.avatar!)
                  : null,
              child: user.avatar == null ? Text(_initial(user.fullName)) : null,
            ),
            title: Text(user.fullName),
            subtitle: Text(
              '${user.role} • ${user.email}\n${user.phoneNumber}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit(user);
                if (value == 'toggle') onToggle(user);
                if (value == 'delete') onDelete(user);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(user.isActive ? 'Khóa' : 'Mở khóa'),
                ),
                const PopupMenuItem(value: 'delete', child: Text('Xóa')),
              ],
            ),
            onTap: () => _showDetails(context, user),
          );
        },
      ),
    );
  }

  void _showDetails(BuildContext context, AdminUserModel user) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => ListView(
        padding: const EdgeInsets.all(20),
        shrinkWrap: true,
        children: [
          Text(
            user.fullName,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _detail('Email', user.email),
          _detail('Số điện thoại', user.phoneNumber),
          _detail('Vai trò', user.role),
          _detail('Trạng thái', user.isActive ? 'Hoạt động' : 'Bị khóa'),
          _detail('Online', user.isOnline ? 'Có' : 'Không'),
          if (user.vehicle != null) ...[
            const Divider(),
            _detail('Biển số', user.vehicle!.licensePlate),
            _detail('Loại xe', user.vehicle!.vehicleTypeName),
            _detail('Hãng xe', user.vehicle!.vehicleBrand),
          ],
          if (user.stats != null) ...[
            const Divider(),
            _detail('Tổng chuyến', user.stats!.totalRides.toString()),
            _detail('Đã chi', _money(user.stats!.totalSpent)),
            _detail('Thu nhập', _money(user.stats!.totalEarnings)),
            _detail('Đánh giá', user.stats!.averageRating.toStringAsFixed(1)),
          ],
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  final int page;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final ValueChanged<int> onPageChanged;

  const _Pagination({
    required this.page,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Trang trước',
            onPressed: hasPreviousPage ? () => onPageChanged(page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('Trang $page/$totalPages'),
          IconButton(
            tooltip: 'Trang sau',
            onPressed: hasNextPage ? () => onPageChanged(page + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

String? _required(String? value) {
  if (value == null || value.trim().isEmpty) return 'Bắt buộc';
  return null;
}

String _initial(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
}

String _money(double value) {
  final rounded = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < rounded.length; i++) {
    final fromEnd = rounded.length - i;
    buffer.write(rounded[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write('.');
  }
  return '$bufferđ';
}
