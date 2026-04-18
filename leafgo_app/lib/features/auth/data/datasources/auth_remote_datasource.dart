// ============================================================
// DATASOURCE — lib/features/auth/data/datasources/auth_remote_datasource.dart
// ============================================================
//
// Handles raw HTTP communication with /api/Auth/* endpoints.
// Throws AuthException on non-2xx responses.
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_models.dart';

// ── Custom exception ──────────────────────────────────────────
class AuthException implements Exception {
  final String message;
  final int? statusCode;
  final ApiError? apiError;

  const AuthException(this.message, {this.statusCode, this.apiError});

  @override
  String toString() => 'AuthException: $message';
}

// ── Contract (for DI / mocking) ──────────────────────────────
abstract class AuthRemoteDataSource {
  Future<UserModel> register(RegisterRequest request);
  Future<UserModel> login(LoginRequest request);
  Future<TokenModel> refreshToken(RefreshTokenRequest request);
  Future<void> revokeToken(RevokeTokenRequest request);
  Future<void> revokeAllTokens(String accessToken);
  Future<List<TokenInfoModel>> getActiveTokens(String accessToken);
  Future<void> changePassword(
    ChangePasswordRequest request,
    String accessToken,
  );
  Future<void> forgotPassword(ForgotPasswordRequest request);
  Future<void> resetPassword(ResetPasswordRequest request);
}

// ── Implementation ────────────────────────────────────────────
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client _client;
  final String _baseUrl;

  // Base URL example: 'http://localhost:8000'  (via Nginx on port 8000)
  // or 'http://10.0.2.2:8080' for Android emulator direct to API
  AuthRemoteDataSourceImpl({
    required http.Client client,
    required String baseUrl,
  }) : _client = client,
       _baseUrl = baseUrl;

  // ── Shared helpers ──────────────────────────────────────────
  Uri _uri(String path) => Uri.parse('$_baseUrl/api/Auth/$path');

  Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Map<String, String> _bearerHeaders(String token) => {
    ..._jsonHeaders,
    'Authorization': 'Bearer $token',
  };

  /// Decodes body → throws [AuthException] if status not in [expected].
  dynamic _decode(http.Response res, {List<int> expected = const [200, 201]}) {
    final body = utf8.decode(res.bodyBytes);
    if (!expected.contains(res.statusCode)) {
      ApiError? err;
      try {
        err = ApiError.fromJson(json.decode(body) as Map<String, dynamic>);
      } catch (_) {}
      throw AuthException(
        err?.firstDetail ?? 'Unexpected error (${res.statusCode})',
        statusCode: res.statusCode,
        apiError: err,
      );
    }
    return json.decode(body);
  }

  // ── Endpoints ───────────────────────────────────────────────

  /// POST /api/Auth/register → 201 Created
  @override
  Future<UserModel> register(RegisterRequest request) async {
    final res = await _client.post(
      _uri('register'),
      headers: _jsonHeaders,
      body: json.encode(request.toJson()),
    );
    final data = _decode(res, expected: [201]);
    return UserModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// POST /api/Auth/login → 200 OK
  @override
  Future<UserModel> login(LoginRequest request) async {
    final res = await _client.post(
      _uri('login'),
      headers: _jsonHeaders,
      body: json.encode(request.toJson()),
    );
    final data = _decode(res);
    return UserModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// POST /api/Auth/refresh-token → 200 OK
  @override
  Future<TokenModel> refreshToken(RefreshTokenRequest request) async {
    final res = await _client.post(
      _uri('refresh-token'),
      headers: _jsonHeaders,
      body: json.encode(request.toJson()),
    );
    final data = _decode(res);
    return TokenModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// POST /api/Auth/revoke-token → 200 OK  (no auth needed per spec)
  @override
  Future<void> revokeToken(RevokeTokenRequest request) async {
    final res = await _client.post(
      _uri('revoke-token'),
      headers: _jsonHeaders,
      body: json.encode(request.toJson()),
    );
    _decode(res);
  }

  /// POST /api/Auth/revoke-all-tokens → 200 OK  (requires Bearer token)
  @override
  Future<void> revokeAllTokens(String accessToken) async {
    final res = await _client.post(
      _uri('revoke-all-tokens'),
      headers: _bearerHeaders(accessToken),
    );
    _decode(res);
  }

  /// GET /api/Auth/tokens → 200 OK  (requires Bearer token)
  @override
  Future<List<TokenInfoModel>> getActiveTokens(String accessToken) async {
    final res = await _client.get(
      _uri('tokens'),
      headers: _bearerHeaders(accessToken),
    );
    final data = _decode(res);
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => TokenInfoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/Auth/change-password → 200 OK  (requires Bearer token)
  @override
  Future<void> changePassword(
    ChangePasswordRequest request,
    String accessToken,
  ) async {
    final res = await _client.post(
      _uri('change-password'),
      headers: _bearerHeaders(accessToken),
      body: json.encode(request.toJson()),
    );
    _decode(res);
  }

  /// POST /api/Auth/forgot-password → 200 OK
  @override
  Future<void> forgotPassword(ForgotPasswordRequest request) async {
    final res = await _client.post(
      _uri('forgot-password'),
      headers: _jsonHeaders,
      body: json.encode(request.toJson()),
    );
    _decode(res);
  }

  /// POST /api/Auth/reset-password → 200 OK
  @override
  Future<void> resetPassword(ResetPasswordRequest request) async {
    final res = await _client.post(
      _uri('reset-password'),
      headers: _jsonHeaders,
      body: json.encode(request.toJson()),
    );
    _decode(res);
  }
}
