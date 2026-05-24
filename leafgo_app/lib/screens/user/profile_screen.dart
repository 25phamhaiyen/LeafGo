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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản'), centerTitle: true),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state.isLoading && state.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = state.profile;
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Không thể tải thông tin hồ sơ'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<UserBloc>().add(UserFetchProfile()),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    final currentAvatarUrl = user.avatar;
                    final action = await showModalBottomSheet<_AvatarAction>(
                      context: context,
                      builder: (sheetContext) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (currentAvatarUrl != null)
                            ListTile(
                              leading: const Icon(Icons.remove_red_eye),
                              title: const Text('Xem ảnh đại diện'),
                              onTap: () => Navigator.pop(
                                sheetContext,
                                _AvatarAction.view,
                              ),
                            ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Chọn ảnh từ thư viện'),
                            onTap: () => Navigator.pop(
                              sheetContext,
                              _AvatarAction.gallery,
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text('Chụp ảnh mới'),
                            onTap: () => Navigator.pop(
                              sheetContext,
                              _AvatarAction.camera,
                            ),
                          ),
                        ],
                      ),
                    );

                    if (!mounted) return;

                    final userBloc = super.context.read<UserBloc>();

                    if (action == _AvatarAction.view &&
                        currentAvatarUrl != null) {
                      final avatarUrl = normalizeAvatarUrl(currentAvatarUrl);
                      if (avatarUrl != null) {
                        _showAvatarPreview(super.context, avatarUrl);
                      }
                      return;
                    }

                    ImageSource? source;
                    if (action == _AvatarAction.gallery) {
                      source = ImageSource.gallery;
                    } else if (action == _AvatarAction.camera) {
                      source = ImageSource.camera;
                    }

                    if (source != null) {
                      final pickedFile = await ImagePicker().pickImage(
                        source: source,
                        imageQuality: 80,
                      );
                      if (pickedFile != null) {
                        userBloc.add(UserUploadAvatar(pickedFile));
                      }
                    }
                  },
                  child: Stack(
                    children: [
                      buildAvatarCircle(
                        user.avatar,
                        radius: 50,
                        backgroundColor: const Color(0xFFE6F7F0),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      if (state.isLoading)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.25),
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
                const SizedBox(height: 16),
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(user.email, style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 32),

                _buildProfileItem(
                  Icons.phone_outlined,
                  'Số điện thoại',
                  user.phoneNumber,
                ),
                _buildProfileItem(
                  Icons.badge_outlined,
                  'Vai trò',
                  user.role == 'User' ? 'Người dùng' : 'Tài xế',
                ),
                _buildProfileItem(
                  Icons.calendar_today_outlined,
                  'Thành viên từ',
                  user.createdAt != null
                      ? DateFormat('dd/MM/yyyy').format(user.createdAt!)
                      : 'N/A',
                ),

                if (user.role == 'Driver') ...[
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () {
                      final driverBloc = context.read<DriverBloc>();
                      final bookingBloc = context.read<BookingBloc>();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => MultiBlocProvider(
                            providers: [
                              BlocProvider.value(value: driverBloc),
                              BlocProvider.value(value: bookingBloc),
                            ],
                            child: const DriverVehicleScreen(),
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F7F0),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.directions_car,
                            color: Color(0xFF10B981),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Thông tin phương tiện',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Xem và chỉnh sửa đăng ký xe của bạn',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF10B981),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 48),

                ElevatedButton.icon(
                  onPressed: () {
                    // Using context.read<AuthBloc>() here because logout is an Auth concern
                    context.read<AuthBloc>().add(AuthLogoutRequested());
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF10B981)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
}
