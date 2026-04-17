// lib/features/admin/domain/repositories/admin_repository.dart

import '../../../auth/data/models/auth_models.dart';
import '../../data/models/admin_models.dart';

abstract class AdminRepository {
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

  Future<StatisticsModel> getStatistics(String accessToken);

  Future<List<VehicleTypeModel>> getVehicleTypes(String accessToken);
  Future<VehicleTypeModel> createVehicleType(String accessToken, Map<String, dynamic> data);
  Future<VehicleTypeModel> getVehicleTypeById(String accessToken, String id);
  Future<VehicleTypeModel> updateVehicleType(String accessToken, String id, Map<String, dynamic> data);
  Future<void> deleteVehicleType(String accessToken, String id);
}
