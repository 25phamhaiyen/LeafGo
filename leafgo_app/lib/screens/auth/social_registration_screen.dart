import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';

class SocialRegistrationScreen extends StatefulWidget {
  final String provider;
  final String token;
  final String email;
  final String fullName;
  final String? avatarUrl;

  const SocialRegistrationScreen({
    super.key,
    required this.provider,
    required this.token,
    required this.email,
    required this.fullName,
    this.avatarUrl,
  });

  @override
  State<SocialRegistrationScreen> createState() => _SocialRegistrationScreenState();
}

class _SocialRegistrationScreenState extends State<SocialRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  String _selectedRole = 'User';

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthCompleteSocialRegistration(
        provider: widget.provider,
        token: widget.token,
        role: _selectedRole,
        phoneNumber: _phoneCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF10B981);

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            if (state.user.role == 'Admin') {
              Navigator.of(context).pushReplacementNamed('/admin-dashboard');
            } else {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          return SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white,
                        backgroundImage: widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
                            ? NetworkImage(widget.avatarUrl!)
                            : null,
                        child: widget.avatarUrl == null || widget.avatarUrl!.isEmpty
                            ? Icon(Icons.person, size: 45, color: primaryColor)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.fullName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                // Form
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Hoàn tất đăng ký',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Vui lòng chọn vai trò và nhập số điện thoại',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Role selector
                          Text(
                            'Bạn là:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _roleCard(
                                  label: 'Hành khách',
                                  icon: Icons.person_outline,
                                  value: 'User',
                                  primaryColor: primaryColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _roleCard(
                                  label: 'Tài xế',
                                  icon: Icons.directions_car_outlined,
                                  value: 'Driver',
                                  primaryColor: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Phone input
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Số điện thoại',
                              prefixIcon: const Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: primaryColor, width: 2),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Vui lòng nhập số điện thoại';
                              }
                              final vnPhoneRegex = RegExp(r'^(0|\+84)[0-9]{9,10}$');
                              if (!vnPhoneRegex.hasMatch(val.trim())) {
                                return 'Số điện thoại không hợp lệ';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Submit button
                          ElevatedButton(
                            onPressed: loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Hoàn tất đăng ký',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _roleCard({
    required String label,
    required IconData icon,
    required String value,
    required Color primaryColor,
  }) {
    final isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.05) : Colors.white,
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? primaryColor : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
