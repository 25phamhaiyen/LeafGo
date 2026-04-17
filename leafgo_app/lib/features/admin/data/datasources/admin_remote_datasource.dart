// lib/features/admin/data/datasources/admin_remote_datasource.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../auth/data/models/auth_models.dart';
import '../models/admin_models.dart';

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
  Future<AdminUserModel> createUser(String accessToken, RegisterRequest request);
  Future<AdminUserModel> getUserById(String accessToken, String id);
  Future<AdminUserModel> updateUser(String accessToken, String id, Map<String, dynamic> updateData);
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
  Future<VehicleTypeModel> createVehicleType(String accessToken, Map<String, dynamic> data);
  Future<VehicleTypeModel> getVehicleTypeById(String accessToken, String id);
  Future<VehicleTypeModel> updateVehicleType(String accessToken, String id, Map<String, dynamic> data);
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
      throw Exception(err?.firstDetail ?? 'Unexpected error (${res.statusCode})');
    }
    return json.decode(body);
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
    final query = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (role != null) 'role': role,
      if (search != null) 'search': search,
      if (isActive != null) 'isActive': isActive.toString(),
      if (isOnline != null) 'isOnline': isOnline.toString(),
    };
    final res = await _client.get(_uri('users', query), headers: _headers(accessToken));
    final data = _decode(res);
    return PaginatedResponse.fromJson(
      data['data'] as Map<String, dynamic>,
      (item) => AdminUserModel.fromJson(item as Map<String, dynamic>),
    );
  }

  @override
  Future<AdminUserModel> createUser(String accessToken, RegisterRequest request) async {
    final res = await _client.post(
      _uri('users'),
      headers: _headers(accessToken),
      body: json.encode(request.toJson()),
    );
    final data = _decode(res, expected: [201]);
    return AdminUserModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<AdminUserModel> getUserById(String accessToken, String id) async {
    final res = await _client.get(_uri('users/$id'), headers: _headers(accessToken));
    final data = _decode(res);
    return AdminUserModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<AdminUserModel> updateUser(String accessToken, String id, Map<String, dynamic> updateData) async {
    final res = await _client.put(
      _uri('users/$id'),
      headers: _headers(accessToken),
      body: json.encode(updateData),
    );
    final data = _decode(res);
    return AdminUserModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteUser(String accessToken, String id) async {
    final res = await _client.delete(_uri('users/$id'), headers: _headers(accessToken));
    _decode(res);
  }

  @override
  Future<void> toggleUserStatus(String accessToken, String id, bool isActive) async {
    final res = await _client.put(
      _uri('users/$id/toggle-status'),
      headers: _headers(accessToken),
      body: json.encode({'isActive': isActive}),
    );
    _decode(res);
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
    final query = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (status != null) 'status': status,
      if (fromDate != null) 'fromDate': fromDate.toIso8601String(),
      if (toDate != null) 'toDate': toDate.toIso8601String(),
      if (userId != null) 'userId': userId,
      if (driverId != null) 'driverId': driverId,
    };
    final res = await _client.get(_uri('rides', query), headers: _headers(accessToken));
    final data = _decode(res);
    return PaginatedResponse.fromJson(
      data['data'] as Map<String, dynamic>,
      (item) => AdminRideModel.fromJson(item as Map<String, dynamic>),
    );
  }

  @override
  Future<AdminRideModel> getRideById(String accessToken, String id) async {
    final res = await _client.get(_uri('rides/$id'), headers: _headers(accessToken));
    final data = _decode(res);
    return AdminRideModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<StatisticsModel> getStatistics(String accessToken) async {
    final res = await _client.get(_uri('statistics'), headers: _headers(accessToken));
    final data = _decode(res);
    return StatisticsModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<VehicleTypeModel>> getVehicleTypes(String accessToken) async {
    final res = await _client.get(_uri('vehicle-types'), headers: _headers(accessToken));
    final data = _decode(res);
    return (data['data'] as List).map((e) => VehicleTypeModel.fromJson(e)).toList();
  }

  @override
  Future<VehicleTypeModel> createVehicleType(String accessToken, Map<String, dynamic> data) async {
    final res = await _client.post(_uri('vehicle-types'), headers: _headers(accessToken), body: json.encode(data));
    final dataRes = _decode(res, expected: [201]);
    return VehicleTypeModel.fromJson(dataRes['data']);
  }

  @override
  Future<VehicleTypeModel> getVehicleTypeById(String accessToken, String id) async {
    final res = await _client.get(_uri('vehicle-types/$id'), headers: _headers(accessToken));
    final data = _decode(res);
    return VehicleTypeModel.fromJson(data['data']);
  }

  @override
  Future<VehicleTypeModel> updateVehicleType(String accessToken, String id, Map<String, dynamic> data) async {
    final res = await _client.put(_uri('vehicle-types/$id'), headers: _headers(accessToken), body: json.encode(data));
    final dataRes = _decode(res);
    return VehicleTypeModel.fromJson(dataRes['data']);
  }

  @override
  Future<void> deleteVehicleType(String accessToken, String id) async {
    final res = await _client.delete(_uri('vehicle-types/$id'), headers: _headers(accessToken));
    _decode(res);
  }
}
