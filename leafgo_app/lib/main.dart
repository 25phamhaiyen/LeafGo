import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'injection_container.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_screen.dart';
import 'features/auth/presentation/pages/register_screen.dart';
import 'features/auth/presentation/pages/forgot_password_screen.dart';
import 'features/user/presentation/pages/main_screen.dart';
import 'features/admin/presentation/pages/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDI();
  runApp(const LeafGoApp());
}


class LeafGoApp extends StatelessWidget {
  const LeafGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>()..add(AuthCheckCachedUser()),
      child: MaterialApp(
        title: 'LeafGo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF10B981),
          useMaterial3: true,
          fontFamily: 'Inter', // Assuming Inter is available or fallback to default
        ),
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              if (state.user.role == 'Admin') {
                return const AdminDashboardScreen();
              }
              return const MainScreen();
            }
            if (state is AuthUnauthenticated) return const LoginScreen();
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        ),
        routes: {
          '/login': (ctx) => const LoginScreen(),
          '/register': (ctx) => const RegisterScreen(),
          '/forgot-password': (ctx) => const ForgotPasswordScreen(),
          '/home': (ctx) => const MainScreen(),
        },
      ),
    );
  }
}

