// lib/features/admin/presentation/bloc/admin_event.dart
import 'package:leafgo_app/models/admin/statistics/statistics_model.dart';

abstract class AdminEvent {}

class AdminFetchDashboardData extends AdminEvent {
  final String accessToken;
  AdminFetchDashboardData(this.accessToken);
}

class AdminGenerateAiInsight extends AdminEvent {
  final StatisticsModel stats;
  AdminGenerateAiInsight(this.stats);
}

class AdminFetchUsers extends AdminEvent {
  final String accessToken;
  final int page;
  final int pageSize;
  final String? role;
  final String? search;
  final bool? isActive;
  final bool? isOnline;

  AdminFetchUsers({
    required this.accessToken,
    this.page = 1,
    this.pageSize = 10,
    this.role,
    this.search,
    this.isActive,
    this.isOnline,
  });
}

class AdminCreateUser extends AdminEvent {
  final String accessToken;
  final String email;
  final String password;
  final String fullName;
  final String phoneNumber;
  final String role;

  AdminCreateUser({
    required this.accessToken,
    required this.email,
    required this.password,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
  });
}

class AdminUpdateUser extends AdminEvent {
  final String accessToken;
  final String id;
  final String fullName;
  final String phoneNumber;
  final bool isActive;

  AdminUpdateUser({
    required this.accessToken,
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.isActive,
  });
}

class AdminDeleteUser extends AdminEvent {
  final String accessToken;
  final String id;

  AdminDeleteUser({required this.accessToken, required this.id});
}

class AdminToggleUserStatus extends AdminEvent {
  final String accessToken;
  final String id;
  final bool isActive;

  AdminToggleUserStatus({
    required this.accessToken,
    required this.id,
    required this.isActive,
  });
}

class AdminFetchRides extends AdminEvent {
  final String accessToken;
  final int page;
  final int pageSize;
  final String? status;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? userId;
  final String? driverId;

  AdminFetchRides({
    required this.accessToken,
    this.page = 1,
    this.pageSize = 10,
    this.status,
    this.fromDate,
    this.toDate,
    this.userId,
    this.driverId,
  });
}

class AdminFetchVehicleTypes extends AdminEvent {
  final String accessToken;
  AdminFetchVehicleTypes(this.accessToken);
}

class AdminCreateVehicleType extends AdminEvent {
  final String accessToken;
  final String name;
  final double basePrice;
  final double pricePerKm;
  final String description;

  AdminCreateVehicleType({
    required this.accessToken,
    required this.name,
    required this.basePrice,
    required this.pricePerKm,
    required this.description,
  });
}

class AdminUpdateVehicleType extends AdminEvent {
  final String accessToken;
  final String id;
  final String name;
  final double basePrice;
  final double pricePerKm;
  final String description;
  final bool isActive;

  AdminUpdateVehicleType({
    required this.accessToken,
    required this.id,
    required this.name,
    required this.basePrice,
    required this.pricePerKm,
    required this.description,
    required this.isActive,
  });
}

class AdminDeleteVehicleType extends AdminEvent {
  final String accessToken;
  final String id;

  AdminDeleteVehicleType({required this.accessToken, required this.id});
}
