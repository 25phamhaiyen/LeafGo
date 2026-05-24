// lib/features/admin/presentation/bloc/admin_state.dart

import '../../models/admin_models.dart';

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
