// ============================================================
// LOCAL DATASOURCE — lib/features/auth/data/datasources/auth_local_datasource.dart
// ============================================================
//
// Persists user session (tokens, user info) using SharedPreferences.
// Use flutter_secure_storage in production for token storage.
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';

abstract class AuthLocalDataSource {
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearUser();
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  });
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const _keyUser = 'leafgo_user';
  static const _keyAccessToken = 'leafgo_access_token';
  static const _keyRefreshToken = 'leafgo_refresh_token';
  static const _keyExpiresAt = 'leafgo_expires_at';

  final SharedPreferences _prefs;

  AuthLocalDataSourceImpl(this._prefs);

  @override
  Future<void> saveUser(UserModel user) async {
    await _prefs.setString(_keyUser, json.encode(user.toJson()));
    await _prefs.setString(_keyAccessToken, user.accessToken);
    await _prefs.setString(_keyRefreshToken, user.refreshToken);
    await _prefs.setString(_keyExpiresAt, user.expiresAt.toIso8601String());
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final raw = _prefs.getString(_keyUser);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearUser() async {
    await _prefs.remove(_keyUser);
    await _prefs.remove(_keyAccessToken);
    await _prefs.remove(_keyRefreshToken);
    await _prefs.remove(_keyExpiresAt);
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  }) async {
    await _prefs.setString(_keyAccessToken, accessToken);
    await _prefs.setString(_keyRefreshToken, refreshToken);
    await _prefs.setString(_keyExpiresAt, expiresAt.toIso8601String());

    // Also update the cached user object with new tokens
    final raw = _prefs.getString(_keyUser);
    if (raw != null) {
      final user = UserModel.fromJson(json.decode(raw) as Map<String, dynamic>);
      final updated = UserModel(
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        role: user.role,
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
        isOnline: user.isOnline,
      );
      await _prefs.setString(_keyUser, json.encode(updated.toJson()));
    }
  }
}
