// lib/features/admin/data/datasources/admin_remote_datasource.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:leafgo_app/models/admin/ride/admin_ride.dart';
import 'package:leafgo_app/models/admin/statistics/statistics_model.dart';
import 'package:leafgo_app/models/admin/userManagement/admin_user_model.dart';
import 'package:leafgo_app/models/admin/userManagement/paginated_response_model.dart';
import 'package:leafgo_app/models/admin/vehicle/vehicle_type.dart';
import 'package:leafgo_app/models/auth/request/register_request.dart';
import 'package:leafgo_app/models/auth/response/api_error.dart';
import 'dart:developer' as dev;
import '../../injection_container.dart';
import 'auth_local_datasource.dart';

abstract class AdminRemoteDataSource {
  // Users
  Future<PaginatedResponse<AdminUserModel>> getUsers({
    required String accessToken,
    int page = 1,
    int pageSize = 10,
    String? role,
    String? search,
    bool? isActive,
    bool? isOnline,
  });
  Future<AdminUserModel> createUser(
    String accessToken,
    RegisterRequest request,
  );
  Future<AdminUserModel> getUserById(String accessToken, String id);
  Future<AdminUserModel> updateUser(
    String accessToken,
    String id,
    Map<String, dynamic> updateData,
  );
  Future<void> deleteUser(String accessToken, String id);
  Future<void> toggleUserStatus(String accessToken, String id, bool isActive);

  // Rides
  Future<PaginatedResponse<AdminRideModel>> getRides({
    required String accessToken,
    int page = 1,
    int pageSize = 10,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    String? userId,
    String? driverId,
  });
  Future<AdminRideModel> getRideById(String accessToken, String id);

  // Statistics
  Future<StatisticsModel> getStatistics(String accessToken);

  // Vehicle Types
  Future<List<VehicleTypeModel>> getVehicleTypes(String accessToken);
  Future<VehicleTypeModel> createVehicleType(
    String accessToken,
    Map<String, dynamic> data,
  );
  Future<VehicleTypeModel> getVehicleTypeById(String accessToken, String id);
  Future<VehicleTypeModel> updateVehicleType(
    String accessToken,
    String id,
    Map<String, dynamic> data,
  );
  Future<void> deleteVehicleType(String accessToken, String id);
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final http.Client _client;
  final String _baseUrl;

  AdminRemoteDataSourceImpl({
    required http.Client client,
    required String baseUrl,
  }) : _client = client,
       _baseUrl = baseUrl;

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$_baseUrl/api/Admin/$path');
    if (query != null && query.isNotEmpty) {
      return uri.replace(queryParameters: query);
    }
    return uri;
  }

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  dynamic _decode(http.Response res, {List<int> expected = const [200, 201]}) {
    final body = utf8.decode(res.bodyBytes);
    if (!expected.contains(res.statusCode)) {
      ApiError? err;
      try {
        err = ApiError.fromJson(json.decode(body) as Map<String, dynamic>);
      } catch (_) {}
      throw Exception(
        err?.firstDetail ?? 'Unexpected error (${res.statusCode})',
      );
    }
    return json.decode(body);
  }

  Future<String> _getValidToken(String passedToken) async {
    final localDataSource = sl<AuthLocalDataSource>();
    final cachedUser = await localDataSource.getCachedUser();
    if (cachedUser != null) {
      if (passedToken.isEmpty || passedToken != cachedUser.accessToken) {
        return cachedUser.accessToken;
      }
    }
    return passedToken;
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final localDataSource = sl<AuthLocalDataSource>();
      final cachedUser = await localDataSource.getCachedUser();
      if (cachedUser == null || cachedUser.refreshToken.isEmpty) {
        return false;
      }

      final response = await _client.post(
        Uri.parse('$_baseUrl/api/Auth/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'refreshToken': cachedUser.refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final body = json.decode(utf8.decode(response.bodyBytes));
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'] as Map<String, dynamic>;
          final accessToken = data['accessToken'] as String;
          final refreshToken = data['refreshToken'] as String;
          final expiresAt = DateTime.parse(data['expiresAt'] as String);

          await localDataSource.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt,
          );
          return true;
        }
      }
    } catch (e) {
      dev.log('Token auto-refresh failed: $e');
    }
    return false;
  }

  Future<dynamic> _request(
    Future<http.Response> Function(String token) requestFn,
    String initialToken, {
    List<int> expected = const [200, 201],
  }) async {
    String token = await _getValidToken(initialToken);
    var res = await requestFn(token);
    
    if (res.statusCode == 401) {
      final success = await _tryRefreshToken();
      if (success) {
        final newToken = await _getValidToken('');
        if (newToken.isNotEmpty && newToken != token) {
          res = await requestFn(newToken);
        }
      }
    }
    
    return _decode(res, expected: expected);
  }

  @override
  Future<PaginatedResponse<AdminUserModel>> getUsers({
    required String accessToken,
    int page = 1,
    int pageSize = 10,
    String? role,
    String? search,
    bool? isActive,
    bool? isOnline,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (role != null) query['role'] = role;
    if (search != null) query['search'] = search;
    if (isActive != null) query['isActive'] = isActive.toString();
    if (isOnline != null) query['isOnline'] = isOnline.toString();
    final data = await _request(
      (token) => _client.get(
        _uri('users', query),
        headers: _headers(token),
      ),
      accessToken,
    );
    return PaginatedResponse.fromJson(
      data['data'] as Map<String, dynamic>,
      (item) => AdminUserModel.fromJson(item as Map<String, dynamic>),
    );
  }

  @override
  Future<AdminUserModel> createUser(
    String accessToken,
    RegisterRequest request,
  ) async {
    final data = await _request(
      (token) => _client.post(
        _uri('users'),
        headers: _headers(token),
        body: json.encode(request.toJson()),
      ),
      accessToken,
    );
    return AdminUserModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<AdminUserModel> getUserById(String accessToken, String id) async {
    final data = await _request(
      (token) => _client.get(
        _uri('users/$id'),
        headers: _headers(token),
      ),
      accessToken,
    );
    return AdminUserModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<AdminUserModel> updateUser(
    String accessToken,
    String id,
    Map<String, dynamic> updateData,
  ) async {
    final data = await _request(
      (token) => _client.put(
        _uri('users/$id'),
        headers: _headers(token),
        body: json.encode(updateData),
      ),
      accessToken,
    );
    return AdminUserModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteUser(String accessToken, String id) async {
    await _request(
      (token) => _client.delete(
        _uri('users/$id'),
        headers: _headers(token),
      ),
      accessToken,
    );
  }

  @override
  Future<void> toggleUserStatus(
    String accessToken,
    String id,
    bool isActive,
  ) async {
    await _request(
      (token) => _client.put(
        _uri('users/$id/toggle-status'),
        headers: _headers(token),
        body: json.encode({'isActive': isActive}),
      ),
      accessToken,
    );
  }

  @override
  Future<PaginatedResponse<AdminRideModel>> getRides({
    required String accessToken,
    int page = 1,
    int pageSize = 10,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    String? userId,
    String? driverId,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (status != null) query['status'] = status;
    if (fromDate != null) query['fromDate'] = fromDate.toIso8601String();
    if (toDate != null) query['toDate'] = toDate.toIso8601String();
    if (userId != null) query['userId'] = userId;
    if (driverId != null) query['driverId'] = driverId;
    final data = await _request(
      (token) => _client.get(
        _uri('rides', query),
        headers: _headers(token),
      ),
      accessToken,
    );
    return PaginatedResponse.fromJson(
      data['data'] as Map<String, dynamic>,
      (item) => AdminRideModel.fromJson(item as Map<String, dynamic>),
    );
  }

  @override
  Future<AdminRideModel> getRideById(String accessToken, String id) async {
    final data = await _request(
      (token) => _client.get(
        _uri('rides/$id'),
        headers: _headers(token),
      ),
      accessToken,
    );
    return AdminRideModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<StatisticsModel> getStatistics(String accessToken) async {
    final data = await _request(
      (token) => _client.get(
        _uri('statistics'),
        headers: _headers(token),
      ),
      accessToken,
    );
    return StatisticsModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<VehicleTypeModel>> getVehicleTypes(String accessToken) async {
    final data = await _request(
      (token) => _client.get(
        _uri('vehicle-types'),
        headers: _headers(token),
      ),
      accessToken,
    );
    return (data['data'] as List)
        .map((e) => VehicleTypeModel.fromJson(e))
        .toList();
  }

  @override
  Future<VehicleTypeModel> createVehicleType(
    String accessToken,
    Map<String, dynamic> data,
  ) async {
    final dataRes = await _request(
      (token) => _client.post(
        _uri('vehicle-types'),
        headers: _headers(token),
        body: json.encode(data),
      ),
      accessToken,
    );
    return VehicleTypeModel.fromJson(dataRes['data']);
  }

  @override
  Future<VehicleTypeModel> getVehicleTypeById(
    String accessToken,
    String id,
  ) async {
    final data = await _request(
      (token) => _client.get(
        _uri('vehicle-types/$id'),
        headers: _headers(token),
      ),
      accessToken,
    );
    return VehicleTypeModel.fromJson(data['data']);
  }

  @override
  Future<VehicleTypeModel> updateVehicleType(
    String accessToken,
    String id,
    Map<String, dynamic> data,
  ) async {
    final dataRes = await _request(
      (token) => _client.put(
        _uri('vehicle-types/$id'),
        headers: _headers(token),
        body: json.encode(data),
      ),
      accessToken,
    );
    return VehicleTypeModel.fromJson(dataRes['data']);
  }

  @override
  Future<void> deleteVehicleType(String accessToken, String id) async {
    await _request(
      (token) => _client.delete(
        _uri('vehicle-types/$id'),
        headers: _headers(token),
      ),
      accessToken,
    );
  }
}
