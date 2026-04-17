// lib/features/auth/presentation/bloc/auth_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leafgo_app/features/auth/domain/usecases/auth_usecases.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RegisterUseCase _register;
  final LoginUseCase _login;
  final LogoutUseCase _logout;
  final GetCachedUserUseCase _getCachedUser;
  final RefreshTokenUseCase _refreshToken;
  final ChangePasswordUseCase _changePassword;
  final ForgotPasswordUseCase _forgotPassword;
  final ResetPasswordUseCase _resetPassword;

  AuthBloc({
    required RegisterUseCase register,
    required LoginUseCase login,
    required LogoutUseCase logout,
    required GetCachedUserUseCase getCachedUser,
    required RefreshTokenUseCase refreshToken,
    required ChangePasswordUseCase changePassword,
    required ForgotPasswordUseCase forgotPassword,
    required ResetPasswordUseCase resetPassword,
  }) : _register = register,
       _login = login,
       _logout = logout,
       _getCachedUser = getCachedUser,
       _refreshToken = refreshToken,
       _changePassword = changePassword,
       _forgotPassword = forgotPassword,
       _resetPassword = resetPassword,
       super(AuthInitial()) {
    on<AuthCheckCachedUser>(_onCheckCachedUser);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLoginRequested>(_onLogin);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthChangePasswordRequested>(_onChangePassword);
    on<AuthForgotPasswordRequested>(_onForgotPassword);
    on<AuthResetPasswordRequested>(_onResetPassword);
    on<AuthRefreshTokenRequested>(_onRefreshToken);
  }

  // ── Handlers ─────────────────────────────────────────────────

  Future<void> _onCheckCachedUser(
    AuthCheckCachedUser event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _getCachedUser();
    if (result.isSuccess && result.data != null) {
      final user = result.data!;
      if (!user.isExpired) {
        emit(AuthAuthenticated(user));
      } else {
        // Try auto-refresh
        final refresh = await _refreshToken(user.refreshToken);
        if (refresh.isSuccess) {
          // Re-fetch from cache after token update
          final updated = await _getCachedUser();
          if (updated.isSuccess && updated.data != null) {
            emit(AuthAuthenticated(updated.data!));
          } else {
            emit(AuthUnauthenticated());
          }
        } else {
          emit(AuthUnauthenticated());
        }
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _register(
      email: event.email,
      password: event.password,
      fullName: event.fullName,
      phoneNumber: event.phoneNumber,
      role: event.role, // Passed role from event
    );
    if (result.isSuccess) {
      emit(AuthAuthenticated(result.data!));
    } else {
      emit(AuthFailure(result.failure!.message));
    }
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _login(email: event.email, password: event.password);
    if (result.isSuccess) {
      emit(AuthAuthenticated(result.data!));
    } else {
      emit(AuthFailure(result.failure!.message));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await _logout();
    emit(AuthUnauthenticated());
  }

  Future<void> _onChangePassword(
    AuthChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _changePassword(
      currentPassword: event.currentPassword,
      newPassword: event.newPassword,
    );
    if (result.isSuccess) {
      emit(AuthOperationSuccess('Password changed successfully'));
    } else {
      emit(AuthFailure(result.failure!.message));
    }
  }

  Future<void> _onForgotPassword(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _forgotPassword(event.email);
    if (result.isSuccess) {
      emit(AuthOperationSuccess('Reset email sent. Check your inbox.'));
    } else {
      emit(AuthFailure(result.failure!.message));
    }
  }

  Future<void> _onResetPassword(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _resetPassword(
      token: event.token,
      newPassword: event.newPassword,
    );
    if (result.isSuccess) {
      emit(AuthOperationSuccess('Password reset! You can now log in.'));
    } else {
      emit(AuthFailure(result.failure!.message));
    }
  }

  Future<void> _onRefreshToken(
    AuthRefreshTokenRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _refreshToken(event.refreshToken);
    if (result.isFailure) {
      emit(AuthUnauthenticated());
    }
    // On success: tokens updated silently in local storage; stay Authenticated
  }
}
