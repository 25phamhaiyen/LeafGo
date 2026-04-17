// ============================================================
// MODELS — lib/features/auth/data/models/auth_models.dart
// ============================================================

// ── Response wrapper ─────────────────────────────────────────
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final DateTime timestamp;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    required this.timestamp,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class ApiError {
  final String error;
  final Map<String, String>? details;
  final DateTime timestamp;

  const ApiError({required this.error, this.details, required this.timestamp});

  factory ApiError.fromJson(Map<String, dynamic> json) {
    final raw = json['details'] as Map<String, dynamic>?;
    return ApiError(
      error: json['error'] as String,
      details: raw?.map((k, v) => MapEntry(k, v.toString())),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  String get firstDetail => details?.values.firstOrNull ?? error;
}

// ── User entity ───────────────────────────────────────────────
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final bool isOnline;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.isOnline,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      role: json['role'] as String,
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      isOnline: json['isOnline'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'fullName': fullName,
    'role': role,
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAt': expiresAt.toIso8601String(),
    'isOnline': isOnline,
  };

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

// ── Token model (refresh response) ───────────────────────────
class TokenModel {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  const TokenModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}

// ── Active token info (GET /tokens) ──────────────────────────
class TokenInfoModel {
  final String id;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String createdByIp;
  final bool isActive;

  const TokenInfoModel({
    required this.id,
    required this.createdAt,
    required this.expiresAt,
    required this.createdByIp,
    required this.isActive,
  });

  factory TokenInfoModel.fromJson(Map<String, dynamic> json) {
    return TokenInfoModel(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      createdByIp: json['createdByIp'] as String,
      isActive: json['isActive'] as bool,
    );
  }
}

// ── Request DTOs ──────────────────────────────────────────────
class RegisterRequest {
  final String email;
  final String password;
  final String fullName;
  final String phoneNumber;
  final String role;

  const RegisterRequest({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phoneNumber,
    this.role = 'User',
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'fullName': fullName,
    'phoneNumber': phoneNumber,
    'role': role,
  };
}

class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class RefreshTokenRequest {
  final String refreshToken;

  const RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() => {'refreshToken': refreshToken};
}

class RevokeTokenRequest {
  final String refreshToken;

  const RevokeTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() => {'refreshToken': refreshToken};
}

class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;

  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
    'currentPassword': currentPassword,
    'newPassword': newPassword,
  };
}

class ForgotPasswordRequest {
  final String email;

  const ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}

class ResetPasswordRequest {
  final String token;
  final String newPassword;

  const ResetPasswordRequest({required this.token, required this.newPassword});

  Map<String, dynamic> toJson() => {'token': token, 'newPassword': newPassword};
}
