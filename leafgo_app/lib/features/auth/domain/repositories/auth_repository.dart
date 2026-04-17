// ============================================================
// REPOSITORY — lib/features/auth/domain/repositories/auth_repository.dart
// ============================================================
//
// Uses Either<Failure, T> pattern (dartz package).
// Wraps DataSource calls; handles exceptions → Failure.
// ─────────────────────────────────────────────────────────────
import 'dart:io';
import 'package:leafgo_app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:leafgo_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:leafgo_app/features/auth/data/models/auth_models.dart';
// ── Failure types ─────────────────────────────────────────────
// lib/core/error/failures.dart  (shared across features)

abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(String message, {this.statusCode}) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure() : super('No internet connection');
}

// ── Repository contract ───────────────────────────────────────
// lib/features/auth/domain/repositories/auth_repository.dart




// Simple Result type (if you don't want dartz dependency)
// Use dartz Either<Failure, T> in larger projects.
class Result<T> {
  final T? data;
  final Failure? failure;

  const Result._({this.data, this.failure});

  factory Result.success(T data) => Result._(data: data);
  factory Result.error(Failure failure) => Result._(failure: failure);

  bool get isSuccess => failure == null;
  bool get isFailure => failure != null;
}

abstract class AuthRepository {
  Future<Result<UserModel>> register(RegisterRequest request);
  Future<Result<UserModel>> login(LoginRequest request);
  Future<Result<UserModel?>> getCachedUser();
  Future<Result<TokenModel>> refreshToken(String refreshToken);
  Future<Result<void>> revokeToken(String refreshToken);
  Future<Result<void>> revokeAllTokens();
  Future<Result<List<TokenInfoModel>>> getActiveTokens();
  Future<Result<void>> changePassword(ChangePasswordRequest request);
  Future<Result<void>> forgotPassword(String email);
  Future<Result<void>> resetPassword(ResetPasswordRequest request);
  Future<Result<void>> logout();
}

// ── Implementation ────────────────────────────────────────────
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  // Current user cached in memory for quick token access
  UserModel? _currentUser;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  // Helper: get stored access token
  String? get _accessToken => _currentUser?.accessToken;

  Result<T> _handleException<T>(Object e) {
    if (e is AuthException) {
      return Result.error(ServerFailure(e.message, statusCode: e.statusCode));
    }
    if (e is SocketException) {
      return Result.error(const NetworkFailure());
    }
    return Result.error(ServerFailure(e.toString()));
  }

  @override
  Future<Result<UserModel>> register(RegisterRequest request) async {
    try {
      final user = await _remote.register(request);
      await _local.saveUser(user);
      _currentUser = user;
      return Result.success(user);
    } catch (e) {
      return _handleException(e);
    }
  }

  @override
  Future<Result<UserModel>> login(LoginRequest request) async {
    try {
      final user = await _remote.login(request);
      await _local.saveUser(user);
      _currentUser = user;
      return Result.success(user);
    } catch (e) {
      return _handleException(e);
    }
  }

  @override
  Future<Result<UserModel?>> getCachedUser() async {
    try {
      final user = await _local.getCachedUser();
      _currentUser = user;
      return Result.success(user);
    } catch (e) {
      return Result.error(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<TokenModel>> refreshToken(String refreshToken) async {
    try {
      final token = await _remote.refreshToken(
        RefreshTokenRequest(refreshToken: refreshToken),
      );
      await _local.saveTokens(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
        expiresAt: token.expiresAt,
      );
      return Result.success(token);
    } catch (e) {
      return _handleException(e);
    }
  }

  @override
  Future<Result<void>> revokeToken(String refreshToken) async {
    try {
      await _remote.revokeToken(RevokeTokenRequest(refreshToken: refreshToken));
      return Result.success(null);
    } catch (e) {
      return _handleException(e);
    }
  }

  @override
  Future<Result<void>> revokeAllTokens() async {
    try {
      final token = _accessToken;
      if (token == null) return Result.error(const ServerFailure('Not authenticated'));
      await _remote.revokeAllTokens(token);
      return Result.success(null);
    } catch (e) {
      return _handleException(e);
    }
  }

  @override
  Future<Result<List<TokenInfoModel>>> getActiveTokens() async {
    try {
      final token = _accessToken;
      if (token == null) return Result.error(const ServerFailure('Not authenticated'));
      final tokens = await _remote.getActiveTokens(token);
      return Result.success(tokens);
    } catch (e) {
      return _handleException(e);
    }
  }

  @override
  Future<Result<void>> changePassword(ChangePasswordRequest request) async {
    try {
      final token = _accessToken;
      if (token == null) return Result.error(const ServerFailure('Not authenticated'));
      await _remote.changePassword(request, token);
      return Result.success(null);
    } catch (e) {
      return _handleException(e);
    }
  }

  @override
  Future<Result<void>> forgotPassword(String email) async {
    try {
      await _remote.forgotPassword(ForgotPasswordRequest(email: email));
      return Result.success(null);
    } catch (e) {
      return _handleException(e);
    }
  }

  @override
  Future<Result<void>> resetPassword(ResetPasswordRequest request) async {
    try {
      await _remote.resetPassword(request);
      return Result.success(null);
    } catch (e) {
      return _handleException(e);
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      // Revoke current refresh token before clearing local storage
      final user = await _local.getCachedUser();
      if (user != null) {
        await _remote
            .revokeToken(RevokeTokenRequest(refreshToken: user.refreshToken))
            .catchError((_) {}); // Silent fail — clear local anyway
      }
      await _local.clearUser();
      _currentUser = null;
      return Result.success(null);
    } catch (e) {
      return Result.error(CacheFailure(e.toString()));
    }
  }
}