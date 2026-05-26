import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/user/user_bloc.dart';
import 'package:leafgo_app/core/utils/avatar_utils.dart';
import 'package:leafgo_app/blocs/booking/booking_bloc.dart';
import 'package:leafgo_app/blocs/driver/driver_bloc.dart';
import 'package:leafgo_app/screens/driver/driver_vehicle_screen.dart';

enum _AvatarAction { view, gallery, camera }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _green900 = Color(0xFF0a3d2e);
  static const _green700 = Color(0xFF0f6e56);
  static const _green500 = Color(0xFF10B981);
  static const _green400 = Color(0xFF34d399);
  static const _green50 = Color(0xFFe8f8f1);

  // ─── avatar tap handler (giữ nguyên logic gốc) ───────────────────────────
  Future<void> _onAvatarTap(
    BuildContext context,
    String? currentAvatarUrl,
  ) async {
    final action = await showModalBottomSheet<_AvatarAction>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (currentAvatarUrl != null)
              ListTile(
                leading: const Icon(Icons.remove_red_eye_outlined),
                title: const Text('Xem ảnh đại diện'),
                onTap: () => Navigator.pop(sheetContext, _AvatarAction.view),
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn ảnh từ thư viện'),
              onTap: () => Navigator.pop(sheetContext, _AvatarAction.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Chụp ảnh mới'),
              onTap: () => Navigator.pop(sheetContext, _AvatarAction.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!mounted) return;

    final userBloc = super.context.read<UserBloc>();

    if (action == _AvatarAction.view && currentAvatarUrl != null) {
      final avatarUrl = normalizeAvatarUrl(currentAvatarUrl);
      if (avatarUrl != null) _showAvatarPreview(super.context, avatarUrl);
      return;
    }

    ImageSource? source;
    if (action == _AvatarAction.gallery) source = ImageSource.gallery;
    if (action == _AvatarAction.camera) source = ImageSource.camera;

    if (source != null) {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null) userBloc.add(UserUploadAvatar(pickedFile));
    }
  }

  void _showAvatarPreview(BuildContext context, String avatarUrl) {
    final normalizedUrl = normalizeAvatarUrl(avatarUrl);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
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
                  errorBuilder: (_, __, ___) => const SizedBox(
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

  // ─── build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          // loading state
          if (state.isLoading && state.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = state.profile;

          // error / no profile state
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_off_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text('Không thể tải thông tin hồ sơ'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<UserBloc>().add(UserFetchProfile()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green500,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final isDriver = user.role == 'Driver';
          final initials = _getInitials(user.fullName);

          return CustomScrollView(
            slivers: [
              // ── Hero header ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _HeroHeader(
                  user: user,
                  initials: initials,
                  isDriver: isDriver,
                  isLoading: state.isLoading,
                  green900: _green900,
                  green500: _green500,
                  green400: _green400,
                  onAvatarTap: () => _onAvatarTap(context, user.avatar),
                ),
              ),

              // ── Body ─────────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Thông tin cá nhân
                    _sectionLabel('Thông tin cá nhân'),
                    _InfoCard(
                      children: [
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          iconBg: _green50,
                          iconColor: _green700,
                          label: 'Số điện thoại',
                          value: user.phoneNumber,
                        ),
                        _InfoRow(
                          icon: Icons.email_outlined,
                          iconBg: _green50,
                          iconColor: _green700,
                          label: 'Email',
                          value: user.email,
                        ),
                        _InfoRow(
                          icon: Icons.badge_outlined,
                          iconBg: _green50,
                          iconColor: _green700,
                          label: 'Vai trò',
                          value: isDriver ? 'Tài xế' : 'Người dùng',
                        ),
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          iconBg: _green50,
                          iconColor: _green700,
                          label: 'Thành viên từ',
                          value: user.createdAt != null
                              ? DateFormat('dd/MM/yyyy').format(user.createdAt!)
                              : 'N/A',
                          isLast: true,
                        ),
                      ],
                    ),

                    // Phương tiện — chỉ hiện với Driver
                    if (isDriver) ...[
                      _sectionLabel('Phương tiện'),
                      _VehicleCard(
                        green50: _green50,
                        green500: _green500,
                        green700: _green700,
                        onTap: () {
                          final driverBloc = context.read<DriverBloc>();
                          final bookingBloc = context.read<BookingBloc>();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MultiBlocProvider(
                                providers: [
                                  BlocProvider.value(value: driverBloc),
                                  BlocProvider.value(value: bookingBloc),
                                ],
                                child: const DriverVehicleScreen(),
                              ),
                            ),
                          );
                        },
                      ),
                    ],

                    // Khác
                    _sectionLabel('Khác'),
                    _InfoCard(
                      children: [
                        _InfoRow(
                          icon: Icons.notifications_outlined,
                          iconBg: const Color(0xFFFFF3E0),
                          iconColor: const Color(0xFFB45309),
                          label: 'Thông báo',
                          value: 'Cài đặt thông báo',
                          trailing: const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ),
                        _InfoRow(
                          icon: Icons.lock_outline,
                          iconBg: const Color(0xFFF0F4FF),
                          iconColor: const Color(0xFF185FA5),
                          label: 'Bảo mật',
                          value: 'Đổi mật khẩu',
                          trailing: const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ),
                        _InfoRow(
                          icon: Icons.help_outline,
                          iconBg: const Color(0xFFF5F0FF),
                          iconColor: const Color(0xFF534AB7),
                          label: 'Hỗ trợ',
                          value: 'Trung tâm trợ giúp',
                          trailing: const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Colors.grey,
                          ),
                          isLast: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Logout
                    _LogoutButton(
                      onTap: () {
                        context.read<AuthBloc>().add(AuthLogoutRequested());
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/login', (route) => false);
                      },
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade500,
        letterSpacing: 0.8,
      ),
    ),
  );

  String _getInitials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Header
// ─────────────────────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final dynamic user;
  final String initials;
  final bool isDriver;
  final bool isLoading;
  final Color green900;
  final Color green500;
  final Color green400;
  final VoidCallback onAvatarTap;

  const _HeroHeader({
    required this.user,
    required this.initials,
    required this.isDriver,
    required this.isLoading,
    required this.green900,
    required this.green500,
    required this.green400,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background
        Container(
          color: green900,
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20,
            left: 24,
            right: 24,
            bottom: 60,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // top bar label
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tài khoản',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Decorative dots
                  Row(
                    children: List.generate(
                      3,
                      (i) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(left: 5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == 0
                              ? Colors.white.withOpacity(0.7)
                              : Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Avatar + name row
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: onAvatarTap,
                    child: Stack(
                      children: [
                        Container(
                          width: 86,
                          height: 86,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 2.5,
                            ),
                          ),
                          child: ClipOval(
                            child: user.avatar != null
                                ? Image.network(
                                    normalizeAvatarUrl(user.avatar) ?? '',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _AvatarPlaceholder(initials: initials),
                                  )
                                : _AvatarPlaceholder(initials: initials),
                          ),
                        ),
                        // Online dot
                        if (user.isOnline == true)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                color: green400,
                                shape: BoxShape.circle,
                                border: Border.all(color: green900, width: 2),
                              ),
                            ),
                          ),
                        // Camera button
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: green500,
                              shape: BoxShape.circle,
                              border: Border.all(color: green900, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                        ),
                        // Loading overlay
                        if (isLoading)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.25),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Name + badges
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _HeroBadge(
                              icon: isDriver
                                  ? Icons.drive_eta_outlined
                                  : Icons.person_outline,
                              label: isDriver ? 'Tài xế' : 'Người dùng',
                              borderColor: green400.withOpacity(0.4),
                              bgColor: green400.withOpacity(0.12),
                              textColor: const Color(0xFF6EE7B7),
                            ),
                            if (user.isActive == true)
                              _HeroBadge(
                                icon: Icons.check_circle_outline,
                                label: 'Đang hoạt động',
                                borderColor: Colors.transparent,
                                bgColor: green500.withOpacity(0.25),
                                textColor: const Color(0xFF6EE7B7),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Arc bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 30,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(
                top: Radius.elliptical(200, 30),
              ),
            ),
          ),
        ),

        // Leaf decoration
        Positioned(
          bottom: 30,
          right: -10,
          child: Icon(
            Icons.eco_outlined,
            size: 90,
            color: Colors.white.withOpacity(0.06),
          ),
        ),
      ],
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  final String initials;
  const _AvatarPlaceholder({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1a6b4a),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Color(0xFFa8e6c8),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color borderColor;
  final Color bgColor;
  final Color textColor;

  const _HeroBadge({
    required this.icon,
    required this.label,
    required this.borderColor,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Card + Row
// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final Widget? trailing;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    this.trailing,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vehicle Card (Driver only)
// ─────────────────────────────────────────────────────────────────────────────

class _VehicleCard extends StatelessWidget {
  final Color green50;
  final Color green500;
  final Color green700;
  final VoidCallback onTap;

  const _VehicleCard({
    required this.green50,
    required this.green500,
    required this.green700,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // left accent bar
            Container(
              width: 3,
              height: 44,
              decoration: BoxDecoration(
                color: green500,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: green50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.directions_car_outlined,
                color: green700,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin phương tiện',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Xem và chỉnh sửa đăng ký xe của bạn',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: green500),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logout Button
// ─────────────────────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.red.shade400, size: 20),
            const SizedBox(width: 10),
            Text(
              'Đăng xuất',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
