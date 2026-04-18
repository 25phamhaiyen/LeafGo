// lib/features/admin/presentation/bloc/admin_event.dart

abstract class AdminEvent {}

class AdminFetchDashboardData extends AdminEvent {
  final String accessToken;
  AdminFetchDashboardData(this.accessToken);
}

class AdminFetchUsers extends AdminEvent {
  final String accessToken;
  final int page;
  final String? role;
  final String? search;
  AdminFetchUsers({required this.accessToken, this.page = 1, this.role, this.search});
}

class AdminFetchRides extends AdminEvent {
  final String accessToken;
  final int page;
  AdminFetchRides({required this.accessToken, this.page = 1});
}

class AdminFetchVehicleTypes extends AdminEvent {
  final String accessToken;
  AdminFetchVehicleTypes(this.accessToken);
}
