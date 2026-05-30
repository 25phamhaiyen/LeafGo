import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:leafgo_app/firebase_options.dart';
import 'injection_container.dart';
import 'blocs/auth/auth_bloc.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/main_screen.dart';
import 'screens/admin/admin_main_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';

import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('vi_VN', null);
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
          fontFamily:
              'Inter', // Assuming Inter is available or fallback to default
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (ctx) => const LoginScreen(),
          '/register': (ctx) => const RegisterScreen(),
          '/forgot-password': (ctx) => const ForgotPasswordScreen(),
          '/home': (ctx) => const MainScreen(),
          '/admin-dashboard': (ctx) => const AdminMainScreen(),
          '/onboarding': (ctx) => const OnboardingScreen(),
        },
      ),
    );
  }
}
