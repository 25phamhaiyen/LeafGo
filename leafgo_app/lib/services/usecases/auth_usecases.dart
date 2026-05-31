// ============================================================
// USE CASES — lib/features/auth/domain/usecases/
// ============================================================
//
// Each use case = single callable class with a __call__ method.
// BLoC calls use cases; use cases call repository.
// ─────────────────────────────────────────────────────────────

// ── 1. Register ───────────────────────────────────────────────
import 'package:leafgo_app/models/auth/request/change_password_request.dart';
import 'package:leafgo_app/models/auth/request/login_request.dart';
import 'package:leafgo_app/models/auth/request/register_request.dart';
import 'package:leafgo_app/models/auth/request/reset_password_request.dart';
import 'package:leafgo_app/models/auth/request/verify_registration_otp_request.dart';
import 'package:leafgo_app/models/auth/token/token_info_models.dart';
import 'package:leafgo_app/models/auth/token/token_model.dart';
import 'package:leafgo_app/models/auth/userEntity/user_models.dart';
import 'package:leafgo_app/services/repositories/auth_repository.dart';

class RequestRegistrationOtpUseCase {
  final AuthRepository _repo;
  RequestRegistrationOtpUseCase(this._repo);

  Future<Result<void>> call({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    String role = 'User',
  }) {
    return _repo.requestRegistrationOtp(
      RegisterRequest(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        role: role,
      ),
    );
  }
}

class RegisterUseCase {
  final AuthRepository _repo;
  RegisterUseCase(this._repo);

  Future<Result<UserModel>> call({
    required String email,
    required String otpCode,
  }) {
    return _repo.register(
      VerifyRegistrationOtpRequest(
        email: email,
        otpCode: otpCode,
      ),
    );
  }
}

// ── 2. Login ──────────────────────────────────────────────────
class LoginUseCase {
  final AuthRepository _repo;
  LoginUseCase(this._repo);

  Future<Result<UserModel>> call({
    required String email,
    required String password,
  }) {
    return _repo.login(LoginRequest(email: email, password: password));
  }
}

// ── 3. Get Cached User (auto-login) ──────────────────────────
class GetCachedUserUseCase {
  final AuthRepository _repo;
  GetCachedUserUseCase(this._repo);

  Future<Result<UserModel?>> call() => _repo.getCachedUser();
}

// ── 4. Refresh Token ─────────────────────────────────────────
class RefreshTokenUseCase {
  final AuthRepository _repo;
  RefreshTokenUseCase(this._repo);

  Future<Result<TokenModel>> call(String refreshToken) {
    return _repo.refreshToken(refreshToken);
  }
}

// ── 5. Logout ─────────────────────────────────────────────────
class LogoutUseCase {
  final AuthRepository _repo;
  LogoutUseCase(this._repo);

  Future<Result<void>> call() => _repo.logout();
}

// ── 6. Revoke All Tokens ──────────────────────────────────────
class RevokeAllTokensUseCase {
  final AuthRepository _repo;
  RevokeAllTokensUseCase(this._repo);

  Future<Result<void>> call() => _repo.revokeAllTokens();
}

// ── 7. Get Active Sessions ────────────────────────────────────
class GetActiveTokensUseCase {
  final AuthRepository _repo;
  GetActiveTokensUseCase(this._repo);

  Future<Result<List<TokenInfoModel>>> call() => _repo.getActiveTokens();
}

// ── 8. Change Password ────────────────────────────────────────
class ChangePasswordUseCase {
  final AuthRepository _repo;
  ChangePasswordUseCase(this._repo);

  Future<Result<void>> call({
    required String currentPassword,
    required String newPassword,
  }) {
    return _repo.changePassword(
      ChangePasswordRequest(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );
  }
}

// ── 9. Forgot Password ────────────────────────────────────────
class ForgotPasswordUseCase {
  final AuthRepository _repo;
  ForgotPasswordUseCase(this._repo);

  Future<Result<void>> call(String email) => _repo.forgotPassword(email);
}

// ── 10. Reset Password ───────────────────────────────────────
class ResetPasswordUseCase {
  final AuthRepository _repo;
  ResetPasswordUseCase(this._repo);

  Future<Result<void>> call({
    required String email,
    required String token,
    required String newPassword,
  }) {
    return _repo.resetPassword(
      ResetPasswordRequest(email: email, token: token, newPassword: newPassword),
    );
  }
}
