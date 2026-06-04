// lib/features/auth/presentation/bloc/auth_state.dart

import 'package:leafgo_app/models/auth/userEntity/user_models.dart';

abstract class AuthState {}

// Initial — not yet checked storage
class AuthInitial extends AuthState {}

// Checking local cache / generic operation in progress
class AuthLoading extends AuthState {}

// Logged in with a valid user
class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated(this.user);
}

// Not logged in
class AuthUnauthenticated extends AuthState {}

// Operation succeeded (e.g. password changed, forgot-password email sent)
class AuthOperationSuccess extends AuthState {
  final String message;
  AuthOperationSuccess(this.message);
}

// Any failure
class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}

// Social login: new user needs to complete registration (choose role + phone)
class AuthSocialNewUser extends AuthState {
  final String provider;
  final String token;
  final String email;
  final String fullName;
  final String? avatarUrl;

  AuthSocialNewUser({
    required this.provider,
    required this.token,
    required this.email,
    required this.fullName,
    this.avatarUrl,
  });
}
