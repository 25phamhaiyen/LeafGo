// lib/features/admin/presentation/pages/user_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leafgo_app/core/utils/avatar_utils.dart';
import 'package:leafgo_app/models/admin/userManagement/admin_user_model.dart';
import 'package:leafgo_app/models/admin/userManagement/paginated_response_model.dart';

import '../../injection_container.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/admin/admin_bloc.dart';
import '../../blocs/admin/admin_event.dart';
import '../../blocs/admin/admin_state.dart';

// ─── Color tokens ────────────────────────────────────────────────────────────

class _AppColors {
  // Purple (Admin)
  static const purple50 = Color(0xFFEEEDFE);
  static const purple200 = Color(0xFFAFA9EC);
  static const purple600 = Color(0xFF534AB7);
  static const purple800 = Color(0xFF3C3489);

  // Teal (User / online)
  static const teal50 = Color(0xFFE1F5EE);
  static const teal200 = Color(0xFF5DCAA5);
  static const teal600 = Color(0xFF0F6E56);
  static const teal800 = Color(0xFF085041);

  // Amber (Driver)
  static const amber50 = Color(0xFFFAEEDA);
  static const amber200 = Color(0xFFEF9F27);
  static const amber600 = Color(0xFF854F0B);
  static const amber800 = Color(0xFF633806);

  // Coral (delete / danger)
  static const coral50 = Color(0xFFFAECE7);
  static const coral200 = Color(0xFFF0997B);
  static const coral600 = Color(0xFF993C1D);
  static const coral800 = Color(0xFF712B13);

  // Green (active)
  static const green50 = Color(0xFFEAF3DE);
  static const green200 = Color(0xFF97C459);
  static const green800 = Color(0xFF27500A);

  // Red (locked)
  static const red50 = Color(0xFFFCEBEB);
  static const red200 = Color(0xFFF09595);
  static const red800 = Color(0xFF791F1F);

  // Gray
  static const gray100 = Color(0xFFD3D1C7);
  static const gray600 = Color(0xFF5F5E5A);
}

// ─── Avatar color helper ─────────────────────────────────────────────────────

_AvatarScheme _avatarScheme(String role) {
  switch (role) {
    case 'Admin':
      return const _AvatarScheme(
        background: _AppColors.purple50,
        foreground: _AppColors.purple800,
        accent: _AppColors.purple600,
      );
    case 'Driver':
      return const _AvatarScheme(
        background: _AppColors.amber50,
        foreground: _AppColors.amber800,
        accent: _AppColors.amber600,
      );
    default: // User
      return const _AvatarScheme(
        background: _AppColors.teal50,
        foreground: _AppColors.teal800,
        accent: _AppColors.teal600,
      );
  }
}

class _AvatarScheme {
  final Color background;
  final Color foreground;
  final Color accent;
  const _AvatarScheme({
    required this.background,
    required this.foreground,
    required this.accent,
  });
}

// ─── Money formatter ─────────────────────────────────────────────────────────

String _formatMoney(double value) {
  final rounded = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < rounded.length; i++) {
    final fromEnd = rounded.length - i;
    buffer.write(rounded[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write('.');
  }
  return '$bufferđ';
}

// ─── Validator ───────────────────────────────────────────────────────────────

String? _required(String? value) {
  if (value == null || value.trim().isEmpty) return 'Bắt buộc';
  return null;
}

// ─── Role badge config ───────────────────────────────────────────────────────

_BadgeStyle _roleBadge(String role) {
  switch (role) {
    case 'Admin':
      return const _BadgeStyle(
        background: _AppColors.purple50,
        foreground: _AppColors.purple800,
        border: _AppColors.purple200,
      );
    case 'Driver':
      return const _BadgeStyle(
        background: _AppColors.amber50,
        foreground: _AppColors.amber800,
        border: _AppColors.amber200,
      );
    default:
      return const _BadgeStyle(
        background: _AppColors.teal50,
        foreground: _AppColors.teal800,
        border: _AppColors.teal200,
      );
  }
}

_BadgeStyle _statusBadge(bool isActive) {
  return isActive
      ? const _BadgeStyle(
          background: _AppColors.green50,
          foreground: _AppColors.green800,
          border: _AppColors.green200,
        )
      : const _BadgeStyle(
          background: _AppColors.red50,
          foreground: _AppColors.red800,
          border: _AppColors.red200,
        );
}

class _BadgeStyle {
  final Color background;
  final Color foreground;
  final Color border;
  const _BadgeStyle({
    required this.background,
    required this.foreground,
    required this.border,
  });
}

// ─── Main screen ─────────────────────────────────────────────────────────────

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
                ).showSnackBar(_successSnackBar(state.message));
                _fetch(context, page: _page);
              }
              if (state is AdminFailure) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(_errorSnackBar('Lỗi: ${state.message}'));
              }
            },
            child: Scaffold(
              backgroundColor: const Color(0xFFF5F4F8),
              body: Column(
                children: [
                  _TopBar(onAdd: () => _showUserForm(context)),
                  _FilterBar(
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
                            child: CircularProgressIndicator(
                              color: _AppColors.purple600,
                            ),
                          );
                        }
                        if (state is AdminUsersLoaded) {
                          return _UserCardGrid(
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
                          return _ErrorState(message: state.message);
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

  // ── Dialogs ────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(BuildContext context, AdminUserModel user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _ConfirmDeleteDialog(user: user),
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
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _UserFormDialog(
        user: user,
        onSave: (fullName, phoneNumber, email, password, role, isActive) {
          if (context.mounted) {
            final bloc = context.read<AdminBloc>();
            if (user == null) {
              bloc.add(
                AdminCreateUser(
                  accessToken: _token(context),
                  email: email,
                  password: password,
                  fullName: fullName,
                  phoneNumber: phoneNumber,
                  role: role,
                ),
              );
            } else {
              bloc.add(
                AdminUpdateUser(
                  accessToken: _token(context),
                  id: user.id,
                  fullName: fullName,
                  phoneNumber: phoneNumber,
                  isActive: isActive,
                ),
              );
            }
          }
          Navigator.pop(dialogContext);
        },
      ),
    );
  }

  // ── SnackBar helpers ───────────────────────────────────────────────────────

  SnackBar _successSnackBar(String msg) => SnackBar(
    content: Row(
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: _AppColors.teal50,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ],
    ),
    backgroundColor: _AppColors.teal800,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  SnackBar _errorSnackBar(String msg) => SnackBar(
    content: Row(
      children: [
        const Icon(Icons.error_outline, color: _AppColors.coral50, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ],
    ),
    backgroundColor: _AppColors.coral800,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );
}

// ─── Top bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onAdd;
  const _TopBar({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          // Back button (if navigator has previous route)
          if (Navigator.of(context).canPop())
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                color: _AppColors.gray600,
                tooltip: 'Quay lại',
              ),
            ),
          const Text(
            'Quản lý người dùng',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          // Add button
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: const Text('Thêm'),
            style: FilledButton.styleFrom(
              backgroundColor: _AppColors.purple600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter bar ──────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String? role;
  final bool? isActive;
  final bool? isOnline;
  final ValueChanged<String?> onRoleChanged;
  final ValueChanged<bool?> onStatusChanged;
  final ValueChanged<bool?> onOnlineChanged;
  final VoidCallback onSearch;

  const _FilterBar({
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: searchCtrl,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên, email, số điện thoại',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: _AppColors.gray100,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: _AppColors.gray600,
                size: 20,
              ),
              suffixIcon: IconButton(
                tooltip: 'Tìm kiếm',
                icon: const Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: _AppColors.purple600,
                ),
                onPressed: onSearch,
              ),
              filled: true,
              fillColor: const Color(0xFFF8F7FC),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFE8E6F0),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFE8E6F0),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: _AppColors.purple600,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tất cả',
                  selected: role == null,
                  onTap: () => onRoleChanged(null),
                  activeBackground: _AppColors.purple50,
                  activeForeground: _AppColors.purple800,
                  activeBorder: _AppColors.purple200,
                ),
                _FilterChip(
                  label: 'User',
                  icon: Icons.person_outline_rounded,
                  selected: role == 'User',
                  onTap: () => onRoleChanged('User'),
                  activeBackground: _AppColors.teal50,
                  activeForeground: _AppColors.teal800,
                  activeBorder: _AppColors.teal200,
                ),
                _FilterChip(
                  label: 'Driver',
                  icon: Icons.directions_car_outlined,
                  selected: role == 'Driver',
                  onTap: () => onRoleChanged('Driver'),
                  activeBackground: _AppColors.amber50,
                  activeForeground: _AppColors.amber800,
                  activeBorder: _AppColors.amber200,
                ),
                _FilterChip(
                  label: 'Admin',
                  icon: Icons.shield_outlined,
                  selected: role == 'Admin',
                  onTap: () => onRoleChanged('Admin'),
                  activeBackground: _AppColors.purple50,
                  activeForeground: _AppColors.purple800,
                  activeBorder: _AppColors.purple200,
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: const Color(0xFFE0DFF0),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                ),
                _FilterChip(
                  label: 'Hoạt động',
                  icon: Icons.check_circle_outline_rounded,
                  selected: isActive == true,
                  onTap: () => onStatusChanged(isActive == true ? null : true),
                  activeBackground: _AppColors.green50,
                  activeForeground: _AppColors.green800,
                  activeBorder: _AppColors.green200,
                ),
                _FilterChip(
                  label: 'Bị khóa',
                  icon: Icons.lock_outline_rounded,
                  selected: isActive == false,
                  onTap: () =>
                      onStatusChanged(isActive == false ? null : false),
                  activeBackground: _AppColors.red50,
                  activeForeground: _AppColors.red800,
                  activeBorder: _AppColors.red200,
                ),
                _FilterChip(
                  label: 'Online',
                  icon: Icons.wifi_rounded,
                  selected: isOnline == true,
                  onTap: () => onOnlineChanged(isOnline == true ? null : true),
                  activeBackground: _AppColors.teal50,
                  activeForeground: _AppColors.teal800,
                  activeBorder: _AppColors.teal200,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  final Color activeBackground;
  final Color activeForeground;
  final Color activeBorder;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
    required this.activeBackground,
    required this.activeForeground,
    required this.activeBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? activeBackground : const Color(0xFFF3F2F8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? activeBorder : const Color(0xFFE0DFF0),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: selected ? activeForeground : _AppColors.gray600,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected ? activeForeground : _AppColors.gray600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Card grid ───────────────────────────────────────────────────────────────

class _UserCardGrid extends StatelessWidget {
  final PaginatedResponse<AdminUserModel> users;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<AdminUserModel> onEdit;
  final ValueChanged<AdminUserModel> onToggle;
  final ValueChanged<AdminUserModel> onDelete;

  const _UserCardGrid({
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
        color: _AppColors.purple600,
        child: ListView(children: const [SizedBox(height: 120), _EmptyState()]),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: _AppColors.purple600,
      child: CustomScrollView(
        slivers: [
          // Stats row
          // SliverToBoxAdapter(child: _StatsRow(users: users.items)),
          // Card grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisExtent: 200,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final user = users.items[index];
                return _UserCard(
                  user: user,
                  onTap: () => _showDetails(context, user),
                  onEdit: () => onEdit(user),
                  onToggle: () => onToggle(user),
                  onDelete: () => onDelete(user),
                );
              }, childCount: users.items.length),
            ),
          ),
          // Pagination
          SliverToBoxAdapter(
            child: _Pagination(
              page: users.page,
              totalPages: users.totalPages,
              hasPreviousPage: users.hasPreviousPage,
              hasNextPage: users.hasNextPage,
              onPageChanged: onPageChanged,
            ),
          ),
        ],
      ),
    );
  }

  // ── Detail bottom sheet ────────────────────────────────────────────────────

  void _showDetails(BuildContext context, AdminUserModel user) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) =>
            _UserDetailSheet(user: user, controller: controller),
      ),
    );
  }
}

// ─── Stats row ───────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final List<AdminUserModel> users;
  const _StatsRow({required this.users});

  @override
  Widget build(BuildContext context) {
    final total = users.length;
    final userCnt = users.where((u) => u.role == 'User').length;
    final drvCnt = users.where((u) => u.role == 'Driver').length;
    final admCnt = users.where((u) => u.role == 'Admin').length;
    final onlCnt = users.where((u) => u.isOnline).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _StatCard(
              label: 'Tổng cộng',
              value: '$total',
              sub: 'tất cả vai trò',
              accent: _AppColors.purple600,
            ),
            _StatCard(
              label: 'User',
              value: '$userCnt',
              sub: 'khách hàng',
              accent: _AppColors.teal600,
            ),
            _StatCard(
              label: 'Driver',
              value: '$drvCnt',
              sub: 'tài xế',
              accent: _AppColors.amber600,
            ),
            _StatCard(
              label: 'Admin',
              value: '$admCnt',
              sub: 'quản trị viên',
              accent: _AppColors.coral600,
            ),
            _StatCard(
              label: 'Online',
              value: '$onlCnt',
              sub: 'đang hoạt động',
              accent: const Color(0xFF378ADD),
              valueColor: const Color(0xFF378ADD),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color accent;
  final Color? valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.accent,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          top: BorderSide(color: accent, width: 3),
          left: const BorderSide(color: Color(0xFFEEECF6), width: 0.5),
          right: const BorderSide(color: Color(0xFFEEECF6), width: 0.5),
          bottom: const BorderSide(color: Color(0xFFEEECF6), width: 0.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: _AppColors.gray600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(fontSize: 11, color: _AppColors.gray600),
          ),
        ],
      ),
    );
  }
}

// ─── User card ───────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final AdminUserModel user;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onTap,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  String get _initials {
    final parts = user.fullName.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[parts.length - 2][0]}${parts[parts.length - 1][0]}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = _avatarScheme(user.role);
    final roleBadge = _roleBadge(user.role);
    final statusBadge = _statusBadge(user.isActive);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEBEAF4), width: 0.5),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: avatar + menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with online dot
                Stack(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: scheme.background,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: user.avatar != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Image.network(
                                normalizeAvatarUrl(user.avatar!) ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    _initials,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: scheme.foreground,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                _initials,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.foreground,
                                ),
                              ),
                            ),
                    ),
                    if (user.isOnline)
                      Positioned(
                        bottom: 1,
                        right: 1,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _AppColors.teal600,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                // Context menu
                SizedBox(
                  width: 28,
                  height: 28,
                  child: PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      size: 18,
                      color: _AppColors.gray600,
                    ),
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'toggle') onToggle();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: _MenuItemRow(
                          icon: Icons.edit_outlined,
                          label: 'Sửa',
                          color: _AppColors.purple600,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: _MenuItemRow(
                          icon: user.isActive
                              ? Icons.lock_outline_rounded
                              : Icons.lock_open_rounded,
                          label: user.isActive ? 'Khóa' : 'Mở khóa',
                          color: user.isActive
                              ? _AppColors.amber600
                              : _AppColors.teal600,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: _MenuItemRow(
                          icon: Icons.delete_outline_rounded,
                          label: 'Xóa',
                          color: _AppColors.coral600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Name
            Text(
              user.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 2),
            // Email
            Text(
              user.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: _AppColors.gray600),
            ),
            const SizedBox(height: 8),
            // Badges
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                _MiniChip(
                  label: user.role,
                  background: roleBadge.background,
                  foreground: roleBadge.foreground,
                  border: roleBadge.border,
                ),
                _MiniChip(
                  label: user.isActive ? 'Hoạt động' : 'Bị khóa',
                  background: statusBadge.background,
                  foreground: statusBadge.foreground,
                  border: statusBadge.border,
                ),
              ],
            ),
            const Spacer(),
            // Footer: phone + action buttons
            const Divider(height: 1, color: Color(0xFFF0EFF8)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 12,
                  color: _AppColors.gray600,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    user.phoneNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _AppColors.gray600,
                    ),
                  ),
                ),
                // Action icon buttons
                _CardIconBtn(
                  icon: Icons.edit_outlined,
                  tooltip: 'Sửa',
                  onTap: onEdit,
                  hoverBg: _AppColors.purple50,
                  hoverFg: _AppColors.purple800,
                ),
                const SizedBox(width: 4),
                _CardIconBtn(
                  icon: user.isActive
                      ? Icons.lock_outline_rounded
                      : Icons.lock_open_rounded,
                  tooltip: user.isActive ? 'Khóa' : 'Mở khóa',
                  onTap: onToggle,
                  hoverBg: _AppColors.teal50,
                  hoverFg: _AppColors.teal800,
                ),
                const SizedBox(width: 4),
                _CardIconBtn(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Xóa',
                  onTap: onDelete,
                  hoverBg: _AppColors.red50,
                  hoverFg: _AppColors.red800,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItemRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MenuItemRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 14, color: color)),
      ],
    );
  }
}

class _CardIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color hoverBg;
  final Color hoverFg;

  const _CardIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.hoverBg,
    required this.hoverFg,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE8E6F0), width: 0.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 13, color: _AppColors.gray600),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final Color border;

  const _MiniChip({
    required this.label,
    required this.background,
    required this.foreground,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
      ),
    );
  }
}

// ─── Detail bottom sheet ─────────────────────────────────────────────────────

class _UserDetailSheet extends StatelessWidget {
  final AdminUserModel user;
  final ScrollController controller;

  const _UserDetailSheet({required this.user, required this.controller});

  String get _initials {
    final parts = user.fullName.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[parts.length - 2][0]}${parts[parts.length - 1][0]}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = _avatarScheme(user.role);

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        // Header
        Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: scheme.background,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: user.avatar != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: Image.network(
                            normalizeAvatarUrl(user.avatar!) ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                _initials,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.foreground,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            _initials,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: scheme.foreground,
                            ),
                          ),
                        ),
                ),
                if (user.isOnline)
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _AppColors.teal600,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _MiniChip(
                        label: user.role,
                        background: _roleBadge(user.role).background,
                        foreground: _roleBadge(user.role).foreground,
                        border: _roleBadge(user.role).border,
                      ),
                      const SizedBox(width: 6),
                      _MiniChip(
                        label: user.isActive ? 'Hoạt động' : 'Bị khóa',
                        background: _statusBadge(user.isActive).background,
                        foreground: _statusBadge(user.isActive).foreground,
                        border: _statusBadge(user.isActive).border,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(height: 1, color: Color(0xFFF0EFF8)),
        const SizedBox(height: 16),
        // Basic info
        _DetailSection(
          title: 'Thông tin cơ bản',
          rows: [
            _DetailRow(label: 'Email', value: user.email),
            _DetailRow(label: 'Số điện thoại', value: user.phoneNumber),
            _DetailRow(
              label: 'Online',
              value: user.isOnline ? '● Đang online' : 'Offline',
              valueColor: user.isOnline
                  ? _AppColors.teal600
                  : _AppColors.gray600,
            ),
          ],
        ),
        // Vehicle (Driver only)
        if (user.vehicle != null) ...[
          const SizedBox(height: 16),
          _DetailSection(
            title: 'Phương tiện',
            rows: [
              _DetailRow(label: 'Biển số', value: user.vehicle!.licensePlate),
              _DetailRow(
                label: 'Loại xe',
                value: user.vehicle!.vehicleTypeName,
              ),
              _DetailRow(label: 'Hãng xe', value: user.vehicle!.vehicleBrand),
            ],
          ),
        ],
        // Stats
        if (user.stats != null) ...[
          const SizedBox(height: 16),
          _SectionHeader(title: 'Thống kê'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: [
              _StatMiniCard(
                label: 'Tổng chuyến',
                value: '${user.stats!.totalRides}',
              ),
              _StatMiniCard(
                label: 'Đánh giá TB',
                value: '⭐ ${user.stats!.averageRating.toStringAsFixed(1)}',
              ),
              if (user.stats!.totalSpent > 0)
                _StatMiniCard(
                  label: 'Đã chi',
                  value: _formatMoney(user.stats!.totalSpent),
                ),
              if (user.stats!.totalEarnings > 0)
                _StatMiniCard(
                  label: 'Thu nhập',
                  value: _formatMoney(user.stats!.totalEarnings),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _AppColors.gray600,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<_DetailRow> rows;
  const _DetailSection({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF0EFF8), width: 0.5),
          ),
          child: Column(
            children: rows
                .asMap()
                .entries
                .map(
                  (entry) => Column(
                    children: [
                      entry.value,
                      if (entry.key < rows.length - 1)
                        const Divider(height: 1, color: Color(0xFFF0EFF8)),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: _AppColors.gray600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor ?? const Color(0xFF1A1A2E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatMiniCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: _AppColors.gray600),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pagination ───────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PgBtn(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Trang trước',
            enabled: hasPreviousPage,
            onTap: () => onPageChanged(page - 1),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _AppColors.purple600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Trang $page / $totalPages',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _PgBtn(
            icon: Icons.chevron_right_rounded,
            tooltip: 'Trang sau',
            enabled: hasNextPage,
            onTap: () => onPageChanged(page + 1),
          ),
        ],
      ),
    );
  }
}

class _PgBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  const _PgBtn({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled
                  ? const Color(0xFFD0CEEA)
                  : const Color(0xFFEEECF6),
              width: 0.5,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? _AppColors.purple600 : _AppColors.gray100,
          ),
        ),
      ),
    );
  }
}

// ─── Confirm delete dialog ───────────────────────────────────────────────────

class _ConfirmDeleteDialog extends StatelessWidget {
  final AdminUserModel user;
  const _ConfirmDeleteDialog({required this.user});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(
            Icons.delete_outline_rounded,
            color: _AppColors.coral600,
            size: 22,
          ),
          SizedBox(width: 8),
          Text(
            'Xóa người dùng',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      content: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            color: _AppColors.gray600,
            height: 1.5,
          ),
          children: [
            const TextSpan(text: 'Bạn có chắc muốn xóa tài khoản '),
            TextSpan(
              text: user.fullName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const TextSpan(text: '? Hành động này không thể hoàn tác.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            foregroundColor: _AppColors.gray600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: _AppColors.coral600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Xóa'),
        ),
      ],
    );
  }
}

// ─── User form dialog ─────────────────────────────────────────────────────────

class _UserFormDialog extends StatefulWidget {
  final AdminUserModel? user;
  final Function(
    String fullName,
    String phoneNumber,
    String email,
    String password,
    String role,
    bool isActive,
  )
  onSave;

  const _UserFormDialog({required this.user, required this.onSave});

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _passwordCtrl;
  late String _role;
  late bool _isActive;
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _fullNameCtrl = TextEditingController(text: widget.user?.fullName ?? '');
    _emailCtrl = TextEditingController(text: widget.user?.email ?? '');
    _phoneCtrl = TextEditingController(text: widget.user?.phoneNumber ?? '');
    _passwordCtrl = TextEditingController();
    _role = widget.user?.role ?? 'User';
    _isActive = widget.user?.isActive ?? true;
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _AppColors.purple50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isEdit
                              ? Icons.edit_outlined
                              : Icons.person_add_alt_1_rounded,
                          color: _AppColors.purple600,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isEdit ? 'Sửa người dùng' : 'Thêm người dùng',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: _AppColors.gray600,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Full name
                  _FormField(
                    controller: _fullNameCtrl,
                    label: 'Họ tên',
                    icon: Icons.person_outline_rounded,
                    validator: _required,
                  ),
                  const SizedBox(height: 14),
                  // Phone
                  _FormField(
                    controller: _phoneCtrl,
                    label: 'Số điện thoại',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: _required,
                  ),
                  // Create-only fields
                  if (!isEdit) ...[
                    const SizedBox(height: 14),
                    _FormField(
                      controller: _emailCtrl,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: _required,
                    ),
                    const SizedBox(height: 14),
                    // Password
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      validator: _required,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          size: 18,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 18,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0DFF0),
                            width: 0.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0DFF0),
                            width: 0.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: _AppColors.purple600,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Role dropdown
                    DropdownButtonFormField<String>(
                      value: _role,
                      decoration: InputDecoration(
                        labelText: 'Vai trò',
                        prefixIcon: const Icon(Icons.shield_outlined, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0DFF0),
                            width: 0.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0DFF0),
                            width: 0.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: _AppColors.purple600,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 14,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'User', child: Text('User')),
                        DropdownMenuItem(
                          value: 'Driver',
                          child: Text('Driver'),
                        ),
                        DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                      ],
                      onChanged: (v) => setState(() => _role = v ?? 'User'),
                    ),
                  ],
                  // Edit-only: isActive toggle
                  if (isEdit) ...[
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F7FC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE0DFF0),
                          width: 0.5,
                        ),
                      ),
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 0,
                        ),
                        title: const Text(
                          'Đang hoạt động',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        subtitle: Text(
                          _isActive
                              ? 'Tài khoản đang kích hoạt'
                              : 'Tài khoản đang bị khóa',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isActive
                                ? _AppColors.teal600
                                : _AppColors.coral600,
                          ),
                        ),
                        value: _isActive,
                        activeColor: _AppColors.teal600,
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFD0CEEA),
                              width: 0.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Hủy',
                            style: TextStyle(color: _AppColors.gray600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: _AppColors.purple600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Lưu',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    widget.onSave(
      _fullNameCtrl.text.trim(),
      _phoneCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
      _role,
      _isActive,
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0DFF0), width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0DFF0), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _AppColors.purple600, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 14,
        ),
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _AppColors.purple50,
            borderRadius: BorderRadius.circular(36),
          ),
          child: const Icon(
            Icons.people_outline_rounded,
            size: 34,
            color: _AppColors.purple600,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Không tìm thấy người dùng',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm',
          style: TextStyle(fontSize: 13, color: _AppColors.gray600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: _AppColors.coral600,
          ),
          const SizedBox(height: 12),
          Text(
            'Lỗi: $message',
            style: const TextStyle(fontSize: 14, color: _AppColors.gray600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
