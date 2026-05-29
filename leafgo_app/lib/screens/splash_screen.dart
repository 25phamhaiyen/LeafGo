import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../blocs/auth/auth_bloc.dart';
import '../injection_container.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _dotsController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();

    // 1. Entry Controller (Scale & Fade for Logo) - 1500ms
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.elasticOut,
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // 2. Rotation Controller (Continuous Spin) - 8 seconds loop
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // 3. Pulse Controller (Background Blur Circles Pulse) - 4 seconds reverse loop
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // 4. Loading Dots Controller (Bouncing dots) - 1200ms loop
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Start entry animations
    _entryController.forward();

    // Start timer for screen transition (2.5 seconds minimum)
    _startTimer();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  Future<void> _startTimer() async {
    final navigator = Navigator.of(context);
    final authBloc = context.read<AuthBloc>();

    // 2.5 seconds minimum duration
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    // Check if onboarding is completed from SharedPreferences
    final prefs = sl<SharedPreferences>();
    final bool onboardingCompleted = prefs.getBool('leafgo_onboarding_completed') ?? false;

    // Read the current state of AuthBloc
    final authState = authBloc.state;

    if (!onboardingCompleted) {
      // Go to onboarding
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } else {
      // Route based on auth state
      if (authState is AuthAuthenticated) {
        if (authState.user.role == 'Admin') {
          navigator.pushReplacementNamed('/admin-dashboard');
        } else {
          navigator.pushReplacementNamed('/home');
        }
      } else if (authState is AuthUnauthenticated) {
        navigator.pushReplacementNamed('/login');
      } else {
        // Fallback or wait for state if still loading
        _waitForAuthState();
      }
    }
  }

  void _waitForAuthState() {
    final navigator = Navigator.of(context);
    final authBloc = context.read<AuthBloc>();

    // Set up a listener loop or direct stream subscription to wait for auth state
    StreamSubscription? subscription;
    subscription = authBloc.stream.listen((state) {
      if (state is AuthAuthenticated || state is AuthUnauthenticated) {
        subscription?.cancel();
        if (!mounted) return;
        final prefs = sl<SharedPreferences>();
        final bool onboardingCompleted = prefs.getBool('leafgo_onboarding_completed') ?? false;
        
        if (!onboardingCompleted) {
          navigator.pushReplacement(
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        } else {
          if (state is AuthAuthenticated) {
            if (state.user.role == 'Admin') {
              navigator.pushReplacementNamed('/admin-dashboard');
            } else {
              navigator.pushReplacementNamed('/home');
            }
          } else {
            navigator.pushReplacementNamed('/login');
          }
        }
      }
    });

    // In case the state was already updated but missed before listener set up, double check
    final state = authBloc.state;
    if (state is AuthAuthenticated || state is AuthUnauthenticated) {
      subscription.cancel();
      final prefs = sl<SharedPreferences>();
      final bool onboardingCompleted = prefs.getBool('leafgo_onboarding_completed') ?? false;
      if (!onboardingCompleted) {
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      } else {
        if (state is AuthAuthenticated) {
          if (state.user.role == 'Admin') {
            navigator.pushReplacementNamed('/admin-dashboard');
          } else {
            navigator.pushReplacementNamed('/home');
          }
        } else {
          navigator.pushReplacementNamed('/login');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Beautiful Premium Green Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF064E3B), // Deep Forest Green
                  Color(0xFF047857), // Emerald Green
                  Color(0xFF10B981), // Leaf Mint Green
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // 2. Background pulsing blur circles
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulse = _pulseController.value;
              return Stack(
                children: [
                  // Top-left soft glow
                  Positioned(
                    top: -100 + (pulse * 20),
                    left: -100 + (pulse * 30),
                    child: Container(
                      width: 300 + (pulse * 50),
                      height: 300 + (pulse * 50),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34D399).withOpacity(0.08 + (pulse * 0.04)),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Bottom-right soft glow
                  Positioned(
                    bottom: -150 - (pulse * 30),
                    right: -100 - (pulse * 20),
                    child: Container(
                      width: 400 + (pulse * 60),
                      height: 400 + (pulse * 60),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withOpacity(0.1 + (pulse * 0.05)),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Center glow behind logo
                  Positioned(
                    top: MediaQuery.of(context).size.height / 2 - 200,
                    left: MediaQuery.of(context).size.width / 2 - 200,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6EE7B7).withOpacity(0.04 + (pulse * 0.03)),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Apply blur to everything behind this BackdropFilter
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(color: Colors.transparent),
            ),
          ),

          // 3. Central logo & rotating orbits stack
          Center(
            child: SizedBox(
              width: 320,
              height: 320,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 3 Orbits rotating around the logo
                  AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      final val = _rotationController.value;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Orbit 1: Inner (160px diameter)
                          Transform.rotate(
                            angle: val * 2 * math.pi, // Clockwise
                            child: const OrbitCircle(
                              radius: 80,
                              dashPattern: [4, 6],
                              dotColor: Colors.white70,
                              dotAngle: 0.5,
                            ),
                          ),
                          // Orbit 2: Middle (210px diameter)
                          Transform.rotate(
                            angle: -val * 2 * math.pi, // Counter-Clockwise
                            child: const OrbitCircle(
                              radius: 105,
                              dashPattern: [1, 0], // Solid line
                              strokeWidth: 0.8,
                              opacity: 0.25,
                              dotColor: Colors.white,
                              dotAngle: 2.1,
                            ),
                          ),
                          // Orbit 3: Outer (260px diameter)
                          Transform.rotate(
                            angle: val * 1.5 * math.pi, // Slow clockwise
                            child: const OrbitCircle(
                              radius: 130,
                              dashPattern: [12, 12],
                              dotColor: Colors.white,
                              dotAngle: 4.2,
                              showTwoDots: true,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // Central Logo Container with entry scale-bounce and rotation
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoOpacity,
                      child: AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, child) {
                          // Subtle idle slow spin for the logo
                          final angle = _rotationController.value * 0.25 * math.pi;
                          return Transform.rotate(
                            angle: angle,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 25,
                                spreadRadius: 2,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white,
                                  Colors.grey.shade50,
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.eco_rounded,
                              size: 56,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Logo Name & Loading indicator and Version display
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Title (Fade-in with logo entry)
                  FadeTransition(
                    opacity: _logoOpacity,
                    child: const Text(
                      'Leaf Go',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // App Subtitle
                  FadeTransition(
                    opacity: _logoOpacity,
                    child: Text(
                      'Di chuyển xanh - Hành trình xanh',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Loading Indicator: 3 Jumping Dots
                  BouncingDotsIndicator(controller: _dotsController),

                  const SizedBox(height: 48),

                  // Version Display
                  Text(
                    'Phiên bản 1.0.0',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper Widget: Concentric orbit circles around logo
class OrbitCircle extends StatelessWidget {
  final double radius;
  final List<int> dashPattern;
  final double strokeWidth;
  final double opacity;
  final Color dotColor;
  final double dotAngle;
  final bool showTwoDots;

  const OrbitCircle({
    super.key,
    required this.radius,
    this.dashPattern = const [1, 0],
    this.strokeWidth = 1.0,
    this.opacity = 0.35,
    required this.dotColor,
    required this.dotAngle,
    this.showTwoDots = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(radius * 2, radius * 2),
      painter: _OrbitPainter(
        radius: radius,
        dashPattern: dashPattern,
        strokeWidth: strokeWidth,
        opacity: opacity,
        dotColor: dotColor,
        dotAngle: dotAngle,
        showTwoDots: showTwoDots,
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  final double radius;
  final List<int> dashPattern;
  final double strokeWidth;
  final double opacity;
  final Color dotColor;
  final double dotAngle;
  final bool showTwoDots;

  _OrbitPainter({
    required this.radius,
    required this.dashPattern,
    required this.strokeWidth,
    required this.opacity,
    required this.dotColor,
    required this.dotAngle,
    required this.showTwoDots,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final isDashed = dashPattern.length > 1 && (dashPattern[0] != 1 || dashPattern[1] != 0);

    if (!isDashed) {
      canvas.drawCircle(center, radius, paint);
    } else {
      // Draw dashed circle
      const double doublePi = 2 * math.pi;
      final double angleStep = doublePi / 360.0;
      
      bool draw = true;
      double currentLength = 0;
      double activeLength = dashPattern[0].toDouble();
      double inactiveLength = dashPattern[1].toDouble();

      Path path = Path();
      
      for (double angle = 0; angle < doublePi; angle += angleStep) {
        final x = center.dx + radius * math.cos(angle);
        final y = center.dy + radius * math.sin(angle);
        
        if (draw) {
          if (angle == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        } else {
          path.moveTo(x, y);
        }

        currentLength += 1;
        if (draw && currentLength >= activeLength) {
          draw = false;
          currentLength = 0;
        } else if (!draw && currentLength >= inactiveLength) {
          draw = true;
          currentLength = 0;
        }
      }
      canvas.drawPath(path, paint);
    }

    // Draw orbiting dot(s) (little light dot representing orbit movement)
    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;
    
    final dotShadowPaint = Paint()
      ..color = dotColor.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
      ..style = PaintingStyle.fill;

    // Dot 1
    final dx1 = center.dx + radius * math.cos(dotAngle);
    final dy1 = center.dy + radius * math.sin(dotAngle);
    canvas.drawCircle(Offset(dx1, dy1), 6, dotShadowPaint);
    canvas.drawCircle(Offset(dx1, dy1), 3.5, dotPaint);

    // Dot 2 (optional)
    if (showTwoDots) {
      final dotAngle2 = dotAngle + math.pi; // opposite side
      final dx2 = center.dx + radius * math.cos(dotAngle2);
      final dy2 = center.dy + radius * math.sin(dotAngle2);
      canvas.drawCircle(Offset(dx2, dy2), 6, dotShadowPaint);
      canvas.drawCircle(Offset(dx2, dy2), 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.dotAngle != dotAngle ||
        oldDelegate.opacity != opacity ||
        oldDelegate.showTwoDots != showTwoDots;
  }
}

// Loading indicator widget with 3 bouncing dots
class BouncingDotsIndicator extends StatelessWidget {
  final AnimationController controller;

  const BouncingDotsIndicator({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            // Stagger each dot's bouncing movement using Intervals
            final double start = index * 0.2;
            final double end = start + 0.6;
            
            double value = 0.0;
            if (controller.value >= start && controller.value <= end) {
              // Map interval [start, end] to standard 0-1 bounce curve
              final double relativeVal = (controller.value - start) / 0.6;
              // Sine wave for smooth bounce up and down: sin(x * pi) goes 0 -> 1 -> 0
              value = math.sin(relativeVal * math.pi);
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Transform.translate(
                offset: Offset(0, -value * 12),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4 + (value * 0.6)),
                    shape: BoxShape.circle,
                    boxShadow: value > 0.5 ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ] : null,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
