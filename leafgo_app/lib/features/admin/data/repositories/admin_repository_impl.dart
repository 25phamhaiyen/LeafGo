// lib/features/admin/data/repositories/admin_repository_impl.dart

import '../../../auth/data/models/auth_models.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';
import '../models/admin_models.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remote;

  AdminRepositoryImpl({required this.remote});

  @override
  Future<PaginatedResponse<AdminUserModel>> getUsers({
    required String accessToken,
    int page = 1,
    int pageSize = 10,
    String? role,
    String? search,
    bool? isActive,
    bool? isOnline,
  }) {
    return remote.getUsers(
      accessToken: accessToken,
      page: page,
      pageSize: pageSize,
      role: role,
      search: search,
      isActive: isActive,
      isOnline: isOnline,
    );
  }

  @override
  Future<AdminUserModel> createUser(String accessToken, RegisterRequest request) {
    return remote.createUser(accessToken, request);
  }

  @override
  Future<AdminUserModel> getUserById(String accessToken, String id) {
    return remote.getUserById(accessToken, id);
  }

  @override
  Future<AdminUserModel> updateUser(String accessToken, String id, Map<String, dynamic> updateData) {
    return remote.updateUser(accessToken, id, updateData);
  }

  @override
  Future<void> deleteUser(String accessToken, String id) {
    return remote.deleteUser(accessToken, id);
  }

  @override
  Future<void> toggleUserStatus(String accessToken, String id, bool isActive) {
    return remote.toggleUserStatus(accessToken, id, isActive);
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
  }) {
    return remote.getRides(
      accessToken: accessToken,
      page: page,
      pageSize: pageSize,
      status: status,
      fromDate: fromDate,
      toDate: toDate,
      userId: userId,
      driverId: driverId,
    );
  }

  @override
  Future<AdminRideModel> getRideById(String accessToken, String id) {
    return remote.getRideById(accessToken, id);
  }

  @override
  Future<StatisticsModel> getStatistics(String accessToken) {
    return remote.getStatistics(accessToken);
  }

  @override
  Future<List<VehicleTypeModel>> getVehicleTypes(String accessToken) {
    return remote.getVehicleTypes(accessToken);
  }

  @override
  Future<VehicleTypeModel> createVehicleType(String accessToken, Map<String, dynamic> data) {
    return remote.createVehicleType(accessToken, data);
  }

  @override
  Future<VehicleTypeModel> getVehicleTypeById(String accessToken, String id) {
    return remote.getVehicleTypeById(accessToken, id);
  }

  @override
  Future<VehicleTypeModel> updateVehicleType(String accessToken, String id, Map<String, dynamic> data) {
    return remote.updateVehicleType(accessToken, id, data);
  }

  @override
  Future<void> deleteVehicleType(String accessToken, String id) {
    return remote.deleteVehicleType(accessToken, id);
  }
}
