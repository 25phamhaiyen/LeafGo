// lib/features/auth/presentation/bloc/auth_event.dart

abstract class AuthEvent {}

class AuthCheckCachedUser extends AuthEvent {}

class AuthRequestRegistrationOtpRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String phoneNumber;
  final String role; // Added role field

  AuthRequestRegistrationOtpRequested({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
  });
}

class AuthVerifyRegistrationOtpRequested extends AuthEvent {
  final String email;
  final String otpCode;

  AuthVerifyRegistrationOtpRequested({
    required this.email,
    required this.otpCode,
  });
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  AuthLoginRequested({required this.email, required this.password});
}

class AuthLogoutRequested extends AuthEvent {}

class AuthChangePasswordRequested extends AuthEvent {
  final String currentPassword;
  final String newPassword;

  AuthChangePasswordRequested({
    required this.currentPassword,
    required this.newPassword,
  });
}

class AuthForgotPasswordRequested extends AuthEvent {
  final String email;
  AuthForgotPasswordRequested(this.email);
}

class AuthResetPasswordRequested extends AuthEvent {
  final String email;
  final String token;
  final String newPassword;

  AuthResetPasswordRequested({required this.email, required this.token, required this.newPassword});
}

class AuthRefreshTokenRequested extends AuthEvent {
  final String refreshToken;
  AuthRefreshTokenRequested(this.refreshToken);
}

class AuthSocialLoginRequested extends AuthEvent {
  final String provider; // "Google" or "Facebook"
  AuthSocialLoginRequested(this.provider);
}

class AuthCompleteSocialRegistration extends AuthEvent {
  final String provider;
  final String token;
  final String role;
  final String phoneNumber;

  AuthCompleteSocialRegistration({
    required this.provider,
    required this.token,
    required this.role,
    required this.phoneNumber,
  });
}
