// lib/features/auth/presentation/bloc/auth_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leafgo_app/services/usecases/auth_usecases.dart';
import 'package:leafgo_app/services/social_auth_service.dart';
import 'package:leafgo_app/models/auth/userEntity/user_models.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RequestRegistrationOtpUseCase _requestRegistrationOtp;
  final RegisterUseCase _register;
  final LoginUseCase _login;
  final LogoutUseCase _logout;
  final GetCachedUserUseCase _getCachedUser;
  final RefreshTokenUseCase _refreshToken;
  final ChangePasswordUseCase _changePassword;
  final ForgotPasswordUseCase _forgotPassword;
  final ResetPasswordUseCase _resetPassword;
  final SocialLoginUseCase _socialLogin;
  final CompleteSocialRegistrationUseCase _completeSocialRegistration;
  final SocialAuthService _socialAuthService;

  AuthBloc({
    required RequestRegistrationOtpUseCase requestRegistrationOtp,
    required RegisterUseCase register,
    required LoginUseCase login,
    required LogoutUseCase logout,
    required GetCachedUserUseCase getCachedUser,
    required RefreshTokenUseCase refreshToken,
    required ChangePasswordUseCase changePassword,
    required ForgotPasswordUseCase forgotPassword,
    required ResetPasswordUseCase resetPassword,
    required SocialLoginUseCase socialLogin,
    required CompleteSocialRegistrationUseCase completeSocialRegistration,
    required SocialAuthService socialAuthService,
  }) : _requestRegistrationOtp = requestRegistrationOtp,
       _register = register,
       _login = login,
       _logout = logout,
       _getCachedUser = getCachedUser,
       _refreshToken = refreshToken,
       _changePassword = changePassword,
       _forgotPassword = forgotPassword,
       _resetPassword = resetPassword,
       _socialLogin = socialLogin,
       _completeSocialRegistration = completeSocialRegistration,
       _socialAuthService = socialAuthService,
       super(AuthInitial()) {
    on<AuthCheckCachedUser>(_onCheckCachedUser);
    on<AuthRequestRegistrationOtpRequested>(_onRequestRegistrationOtp);
    on<AuthVerifyRegistrationOtpRequested>(_onVerifyRegistrationOtp);
    on<AuthLoginRequested>(_onLogin);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthChangePasswordRequested>(_onChangePassword);
    on<AuthForgotPasswordRequested>(_onForgotPassword);
    on<AuthResetPasswordRequested>(_onResetPassword);
    on<AuthRefreshTokenRequested>(_onRefreshToken);
    on<AuthSocialLoginRequested>(_onSocialLogin);
    on<AuthCompleteSocialRegistration>(_onCompleteSocialRegistration);
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

  Future<void> _onRequestRegistrationOtp(
    AuthRequestRegistrationOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _requestRegistrationOtp(
      email: event.email,
      password: event.password,
      fullName: event.fullName,
      phoneNumber: event.phoneNumber,
      role: event.role, // Passed role from event
    );
    if (result.isSuccess) {
      emit(AuthOperationSuccess('OTP sent to email. Please verify.'));
    } else {
      emit(AuthFailure(result.failure!.message));
    }
  }

  Future<void> _onVerifyRegistrationOtp(
    AuthVerifyRegistrationOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _register(
      email: event.email,
      otpCode: event.otpCode,
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
      email: event.email,
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

  Future<void> _onSocialLogin(
    AuthSocialLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Step 1: Get token from social provider
      String? token;
      if (event.provider == 'Google') {
        token = await _socialAuthService.signInWithGoogle(
          serverClientId: '321072041438-tfpfjq0166mvuqmqq9859vgf0tic5dag.apps.googleusercontent.com',
        );
      } else if (event.provider == 'Facebook') {
        token = await _socialAuthService.signInWithFacebook();
      }

      if (token == null) {
        emit(AuthUnauthenticated()); // User cancelled
        return;
      }

      // Step 2: Send token to backend
      final result = await _socialLogin(provider: event.provider, token: token);
      if (result.isFailure) {
        emit(AuthFailure(result.failure!.message));
        return;
      }

      final data = result.data!;
      if (data['isNewUser'] == true) {
        // New user — need to complete registration
        emit(AuthSocialNewUser(
          provider: event.provider,
          token: token,
          email: data['email'] as String? ?? '',
          fullName: data['fullName'] as String? ?? '',
          avatarUrl: data['avatarUrl'] as String?,
        ));
      } else {
        // Existing user — already authenticated (saved in repository)
        final user = UserModel.fromJson(data['authData'] as Map<String, dynamic>);
        emit(AuthAuthenticated(user));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onCompleteSocialRegistration(
    AuthCompleteSocialRegistration event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _completeSocialRegistration(
      provider: event.provider,
      token: event.token,
      role: event.role,
      phoneNumber: event.phoneNumber,
    );
    if (result.isSuccess) {
      emit(AuthAuthenticated(result.data!));
    } else {
      emit(AuthFailure(result.failure!.message));
    }
  }
}
