// lib/features/admin/presentation/bloc/admin_state.dart

import 'package:leafgo_app/models/admin/ride/admin_ride.dart';
import 'package:leafgo_app/models/admin/statistics/statistics_model.dart';
import 'package:leafgo_app/models/admin/userManagement/admin_user_model.dart';
import 'package:leafgo_app/models/admin/userManagement/paginated_response_model.dart';
import 'package:leafgo_app/models/admin/vehicle/vehicle_type.dart';

abstract class AdminState {}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminActionSuccess extends AdminState {
  final String message;
  AdminActionSuccess(this.message);
}

class AdminDashboardLoaded extends AdminState {
  final StatisticsModel stats;
  AdminDashboardLoaded(this.stats);
}

class AdminUsersLoaded extends AdminState {
  final PaginatedResponse<AdminUserModel> users;
  AdminUsersLoaded(this.users);
}

class AdminRidesLoaded extends AdminState {
  final PaginatedResponse<AdminRideModel> rides;
  AdminRidesLoaded(this.rides);
}

class AdminVehicleTypesLoaded extends AdminState {
  final List<VehicleTypeModel> vehicleTypes;
  AdminVehicleTypesLoaded(this.vehicleTypes);
}

class AdminFailure extends AdminState {
  final String message;
  AdminFailure(this.message);
}
