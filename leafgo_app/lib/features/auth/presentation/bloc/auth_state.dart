// lib/features/auth/presentation/bloc/auth_state.dart

import 'package:leafgo_app/features/auth/data/models/auth_models.dart';

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
