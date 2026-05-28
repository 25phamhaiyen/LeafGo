// ============================================================
// MODELS — lib/features/auth/data/models/auth_models.dart
// ============================================================

// ── Response wrapper ─────────────────────────────────────────


// ── User entity ───────────────────────────────────────────────


// ── Token model (refresh response) ───────────────────────────


// ── Active token info (GET /tokens) ──────────────────────────


// ── Request DTOs ──────────────────────────────────────────────



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
