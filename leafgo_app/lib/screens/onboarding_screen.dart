import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../blocs/auth/auth_bloc.dart';
import '../injection_container.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _numPages = 4;

  final List<OnboardingSlideData> _slides = [
    OnboardingSlideData(
      title: 'Đặt xe dễ dàng',
      description: 'Lựa chọn điểm đến của bạn và đặt xe chỉ với một vài lượt chạm. Lộ trình của bạn sẽ được tối ưu hóa thông minh nhất.',
      icon: Icons.location_on_rounded,
      iconColor: const Color(0xFF3B82F6), // Vibrant Blue
      gradientColors: [
        const Color(0xFF1E3A8A), // Navy Blue
        const Color(0xFF0F172A), // Dark Slate
      ],
    ),
    OnboardingSlideData(
      title: 'An toàn tuyệt đối',
      description: 'An tâm di chuyển cùng đội ngũ tài xế được xác minh danh tính và hồ sơ đầy đủ. Hành trình được giám sát trực tiếp trên bản đồ.',
      icon: Icons.shield_rounded,
      iconColor: const Color(0xFF10B981), // Emerald Green
      gradientColors: [
        const Color(0xFF064E3B), // Deep Forest Green
        const Color(0xFF022C22), // Ultra Dark Green
      ],
    ),
    OnboardingSlideData(
      title: 'Giá cả hợp lý',
      description: 'Mức giá cước cạnh tranh hiển thị rõ ràng trước khi đặt chuyến. Cam kết minh bạch và không phát sinh bất kỳ phụ phí ẩn nào.',
      icon: Icons.attach_money_rounded,
      iconColor: const Color(0xFFF97316), // Orange
      gradientColors: [
        const Color(0xFF7C2D12), // Deep Orange/Rust
        const Color(0xFF18181B), // Dark Grey
      ],
    ),
    OnboardingSlideData(
      title: 'Nhanh chóng tiện lợi',
      description: 'Tìm kiếm tài xế xung quanh bạn tức thì. Hỗ trợ đa dạng các hình thức thanh toán từ tiền mặt đến ví điện tử không dùng tiền mặt.',
      icon: Icons.bolt_rounded,
      iconColor: const Color(0xFF8B5CF6), // Purple
      gradientColors: [
        const Color(0xFF4C1D95), // Deep Purple
        const Color(0xFF0F172A), // Dark Slate
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = sl<SharedPreferences>();
    await prefs.setBool('leafgo_onboarding_completed', true);

    if (!mounted) return;

    // Route based on auth state
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      if (authState.user.role == 'Admin') {
        Navigator.of(context).pushReplacementNamed('/admin-dashboard');
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _nextPage() {
    if (_currentPage < _numPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSlide = _slides[_currentPage];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: currentSlide.gradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Action Bar (Skip & Progress Tracker)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Glassmorphic Progress indicator (e.g. 1/4)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        '${_currentPage + 1} / $_numPages',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),

                    // Skip ("Bỏ qua") Button
                    AnimatedOpacity(
                      opacity: _currentPage == _numPages - 1 ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: IgnorePointer(
                        ignoring: _currentPage == _numPages - 1,
                        child: TextButton(
                          onPressed: _completeOnboarding,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withOpacity(0.8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.white.withOpacity(0.15)),
                            ),
                          ),
                          child: const Text(
                            'Bỏ qua',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Swipeable Contents
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemCount: _numPages,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return OnboardingSlideContent(
                      icon: slide.icon,
                      iconColor: slide.iconColor,
                      title: slide.title,
                      description: slide.description,
                      isActive: _currentPage == index,
                    );
                  },
                ),
              ),

              // Bottom control area (Pagination & CTA Button)
              Padding(
                padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 40.0, top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Pagination dots indicator
                    Row(
                      children: List.generate(_numPages, (index) {
                        final isActive = _currentPage == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          margin: const EdgeInsets.only(right: 8.0),
                          height: 8.0,
                          width: isActive ? 24.0 : 8.0,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4.0),
                            boxShadow: isActive ? [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.4),
                                blurRadius: 6.0,
                                spreadRadius: 1.0,
                              )
                            ] : null,
                          ),
                        );
                      }),
                    ),

                    // Next / Get Started CTA Button
                    ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: currentSlide.gradientColors[0],
                        shadowColor: Colors.black45,
                        elevation: 6,
                        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentPage == _numPages - 1 ? 'Bắt đầu' : 'Tiếp tục',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage == _numPages - 1
                                ? Icons.rocket_launch_rounded
                                : Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Slide Model Class
class OnboardingSlideData {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final List<Color> gradientColors;

  OnboardingSlideData({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.gradientColors,
  });
}

// Slide Item rendering widget with fade-in-up entrance animations
class OnboardingSlideContent extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool isActive;

  const OnboardingSlideContent({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.isActive,
  });

  @override
  State<OnboardingSlideContent> createState() => _OnboardingSlideContentState();
}

class _OnboardingSlideContentState extends State<OnboardingSlideContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.9, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutQuad),
      ),
    );

    if (widget.isActive) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant OnboardingSlideContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _animationController.forward(from: 0.0);
    } else if (!widget.isActive && oldWidget.isActive) {
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated glowing icon circle
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.iconColor.withOpacity(0.3),
                          blurRadius: 30.0,
                          spreadRadius: 2.0,
                        )
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        size: 52,
                        color: widget.iconColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Glassmorphic Content Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(28.0),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 16.0,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 15,
                            height: 1.6,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
