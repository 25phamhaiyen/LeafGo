// ============================================================
// DEPENDENCY INJECTION — lib/injection_container.dart
// ============================================================
// Using get_it for service locator pattern.
// Call setupDI() before runApp().
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:leafgo_app/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:leafgo_app/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:leafgo_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:leafgo_app/features/auth/domain/usecases/auth_usecases.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Features → Auth
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/domain/repositories/auth_repository.dart';

import 'features/auth/presentation/bloc/auth_bloc.dart';

import 'features/admin/presentation/bloc/admin_bloc.dart';
import 'features/auth/presentation/bloc/user_bloc.dart';

// Features → Booking
import 'features/booking/data/datasources/booking_remote_datasource.dart';
import 'features/booking/domain/repositories/booking_repository.dart';

// Features → User Profile & History
import 'features/auth/data/datasources/user_remote_datasource.dart';
import 'features/auth/domain/repositories/user_repository.dart';

// Features → Driver
import 'features/driver/data/datasources/driver_remote_datasource.dart';
import 'features/driver/domain/repositories/driver_repository.dart';
import 'features/driver/presentation/bloc/driver_bloc.dart';

import 'features/booking/presentation/bloc/booking_bloc.dart';

// Core → Services
import 'core/services/location_service.dart';
import 'core/services/signalr_service.dart';

final sl = GetIt.instance;

Future<void> setupDI() async {
  // ── External dependencies ─────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton<http.Client>(() => http.Client());

  // ── DataSources ───────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      client: sl<http.Client>(),
      baseUrl: kIsWeb
          ? 'http://127.0.0.1:8000'
          : (defaultTargetPlatform == TargetPlatform.android
              ? 'http://10.0.2.2:8000'
              : 'http://127.0.0.1:8000'),
    ),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl<SharedPreferences>()),
  );

  // ── Repository ────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remote: sl<AuthRemoteDataSource>(),
      local: sl<AuthLocalDataSource>(),
    ),
  );

  sl.registerLazySingleton<AdminRemoteDataSource>(
    () => AdminRemoteDataSourceImpl(
      client: sl<http.Client>(),
      baseUrl: kIsWeb
          ? 'http://127.0.0.1:8000'
          : (defaultTargetPlatform == TargetPlatform.android
              ? 'http://10.0.2.2:8000'
              : 'http://127.0.0.1:8000'),
    ),
  );

  sl.registerLazySingleton<AdminRepository>(
    () => AdminRepositoryImpl(remote: sl<AdminRemoteDataSource>()),
  );

  // ── Use Cases ─────────────────────────────────────────────
  sl
    ..registerLazySingleton(() => RegisterUseCase(sl()))
    ..registerLazySingleton(() => LoginUseCase(sl()))
    ..registerLazySingleton(() => LogoutUseCase(sl()))
    ..registerLazySingleton(() => GetCachedUserUseCase(sl()))
    ..registerLazySingleton(() => RefreshTokenUseCase(sl()))
    ..registerLazySingleton(() => ChangePasswordUseCase(sl()))
    ..registerLazySingleton(() => ForgotPasswordUseCase(sl()))
    ..registerLazySingleton(() => ResetPasswordUseCase(sl()));

  // ── BLoC (factory → new instance per page) ───────────────
  sl.registerFactory(
    () => AuthBloc(
      register: sl(),
      login: sl(),
      logout: sl(),
      getCachedUser: sl(),
      refreshToken: sl(),
      changePassword: sl(),
      forgotPassword: sl(),
      resetPassword: sl(),
    ),
  );

  sl.registerFactory(() => AdminBloc(repository: sl()));

  // ── Booking Feature ────────────────────────────────────────
  sl.registerLazySingleton<LocationService>(() => LocationService());
  sl.registerLazySingleton<SignalRService>(
    () => SignalRService(
      baseUrl: kIsWeb
          ? 'http://127.0.0.1:8000'
          : (defaultTargetPlatform == TargetPlatform.android
              ? 'http://10.0.2.2:8000'
              : 'http://127.0.0.1:8000'),
    ),
  );

  sl.registerLazySingleton<BookingRemoteDataSource>(
    () => BookingRemoteDataSourceImpl(
      client: sl<http.Client>(),
      baseUrl: kIsWeb
          ? 'http://127.0.0.1:8000'
          : (defaultTargetPlatform == TargetPlatform.android
              ? 'http://10.0.2.2:8000'
              : 'http://127.0.0.1:8000'),
    ),
  );

  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(remote: sl<BookingRemoteDataSource>()),
  );

  // ── User Profile Feature ───────────────────────────────────
  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(
      client: sl<http.Client>(),
      baseUrl: kIsWeb
          ? 'http://127.0.0.1:8000'
          : (defaultTargetPlatform == TargetPlatform.android
              ? 'http://10.0.2.2:8000'
              : 'http://127.0.0.1:8000'),
    ),
  );

  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(remote: sl<UserRemoteDataSource>()),
  );

  sl.registerFactory(
    () => UserBloc(
      repository: sl(),
      authLocalDataSource: sl(),
    ),
  );

  sl.registerFactory(
    () => BookingBloc(
      repository: sl(),
      locationService: sl(),
      signalRService: sl(),
      authLocalDataSource: sl(),
    ),
  );

  // ── Driver Feature ─────────────────────────────────────────
  sl.registerLazySingleton<DriverRemoteDataSource>(
    () => DriverRemoteDataSourceImpl(
      client: sl<http.Client>(),
      baseUrl: kIsWeb
          ? 'http://127.0.0.1:8000'
          : (defaultTargetPlatform == TargetPlatform.android
              ? 'http://10.0.2.2:8000'
              : 'http://127.0.0.1:8000'),
    ),
  );

  sl.registerLazySingleton<DriverRepository>(
    () => DriverRepositoryImpl(remote: sl<DriverRemoteDataSource>()),
  );

  sl.registerFactory(
    () => DriverBloc(
      repository: sl(),
      locationService: sl(),
      signalRService: sl(),
      authLocalDataSource: sl(),
    ),
  );
}


// ============================================================
// pubspec.yaml — add these dependencies
// ============================================================
/*
dependencies:
  flutter:
    sdk: flutter
  
  # State management
  flutter_bloc: ^8.1.4
  
  # HTTP
  http: ^1.2.1
  
  # Local storage
  shared_preferences: ^2.2.3
  # Production alternative for tokens:
  # flutter_secure_storage: ^9.2.2

  # Dependency injection
  get_it: ^7.7.0
  
  # (Optional) Functional programming — Either type
  # dartz: ^0.10.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  build_runner: ^2.4.9
*/


// ============================================================
// main.dart — wiring it together
// ============================================================
/*
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'injection_container.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/screens/auth_screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDI();
  runApp(const LeafGoApp());
}

class LeafGoApp extends StatelessWidget {
  const LeafGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LeafGo',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2D7A4F),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (_) => sl<AuthBloc>()..add(AuthCheckCachedUser()),
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) return const HomeScreen();
            if (state is AuthUnauthenticated) return const LoginScreen();
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ),
      routes: {
        '/login': (ctx) => BlocProvider.value(
              value: sl<AuthBloc>(),
              child: const LoginScreen(),
            ),
        '/register': (ctx) => BlocProvider.value(
              value: sl<AuthBloc>(),
              child: const RegisterScreen(),
            ),
        '/forgot-password': (ctx) => BlocProvider.value(
              value: sl<AuthBloc>(),
              child: const ForgotPasswordScreen(),
            ),
      },
    );
  }
}
*/