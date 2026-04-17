// lib/features/admin/data/models/admin_models.dart

import 'package:leafgo_app/features/auth/data/models/auth_models.dart';

// ── User Management ──────────────────────────────────────────

class AdminUserModel {
  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String role;
  final String? avatar;
  final bool isActive;
  final bool isOnline;
  final DateTime createdAt;
  final VehicleInfo? vehicle;
  final UserStats? stats;

  const AdminUserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    this.avatar,
    required this.isActive,
    required this.isOnline,
    required this.createdAt,
    this.vehicle,
    this.stats,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      role: json['role'] as String,
      avatar: json['avatar'] as String?,
      isActive: json['isActive'] as bool,
      isOnline: json['isOnline'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      vehicle: json['vehicle'] != null ? VehicleInfo.fromJson(json['vehicle']) : null,
      stats: json['stats'] != null ? UserStats.fromJson(json['stats']) : null,
    );
  }
}

class VehicleInfo {
  final String licensePlate;
  final String vehicleTypeName;
  final String vehicleBrand;

  const VehicleInfo({
    required this.licensePlate,
    required this.vehicleTypeName,
    required this.vehicleBrand,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      licensePlate: json['licensePlate'] as String,
      vehicleTypeName: json['vehicleTypeName'] as String,
      vehicleBrand: json['vehicleBrand'] as String,
    );
  }
}

class UserStats {
  final int totalRides;
  final double totalSpent;
  final double totalEarnings;
  final double averageRating;

  const UserStats({
    required this.totalRides,
    required this.totalSpent,
    required this.totalEarnings,
    required this.averageRating,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalRides: json['totalRides'] as int,
      totalSpent: (json['totalSpent'] as num).toDouble(),
      totalEarnings: (json['totalEarnings'] as num).toDouble(),
      averageRating: (json['averageRating'] as num).toDouble(),
    );
  }
}

class PaginatedResponse<T> {
  final List<T> items;
  final int totalItems;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;

  const PaginatedResponse({
    required this.items,
    required this.totalItems,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  factory PaginatedResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
    return PaginatedResponse<T>(
      items: (json['items'] as List).map(fromJsonT).toList(),
      totalItems: json['totalItems'] as int,
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      totalPages: json['totalPages'] as int,
      hasPreviousPage: json['hasPreviousPage'] as bool,
      hasNextPage: json['hasNextPage'] as bool,
    );
  }
}

// ── Statistics ───────────────────────────────────────────────

class StatisticsModel {
  final int totalUsers;
  final int totalDrivers;
  final int onlineDrivers;
  final int totalCompletedRides;
  final int totalPendingRides;
  final int todayRides;
  final double totalRevenue;
  final double todayRevenue;
  final double thisMonthRevenue;
  final List<TopDriver> topDrivers;
  final List<RevenueByMonth> revenueByMonth;
  final List<RidesByStatus> ridesByStatus;

  const StatisticsModel({
    required this.totalUsers,
    required this.totalDrivers,
    required this.onlineDrivers,
    required this.totalCompletedRides,
    required this.totalPendingRides,
    required this.todayRides,
    required this.totalRevenue,
    required this.todayRevenue,
    required this.thisMonthRevenue,
    required this.topDrivers,
    required this.revenueByMonth,
    required this.ridesByStatus,
  });

  factory StatisticsModel.fromJson(Map<String, dynamic> json) {
    return StatisticsModel(
      totalUsers: json['totalUsers'] as int,
      totalDrivers: json['totalDrivers'] as int,
      onlineDrivers: json['onlineDrivers'] as int,
      totalCompletedRides: json['totalCompletedRides'] as int,
      totalPendingRides: json['totalPendingRides'] as int,
      todayRides: json['todayRides'] as int,
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      todayRevenue: (json['todayRevenue'] as num).toDouble(),
      thisMonthRevenue: (json['thisMonthRevenue'] as num).toDouble(),
      topDrivers: (json['topDrivers'] as List).map((e) => TopDriver.fromJson(e)).toList(),
      revenueByMonth: (json['revenueByMonth'] as List).map((e) => RevenueByMonth.fromJson(e)).toList(),
      ridesByStatus: (json['ridesByStatus'] as List).map((e) => RidesByStatus.fromJson(e)).toList(),
    );
  }
}

class TopDriver {
  final String id;
  final String fullName;
  final String? avatar;
  final int totalRides;
  final double totalEarnings;
  final double averageRating;

  const TopDriver({
    required this.id,
    required this.fullName,
    this.avatar,
    required this.totalRides,
    required this.totalEarnings,
    required this.averageRating,
  });

  factory TopDriver.fromJson(Map<String, dynamic> json) {
    return TopDriver(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      avatar: json['avatar'] as String?,
      totalRides: json['totalRides'] as int,
      totalEarnings: (json['totalEarnings'] as num).toDouble(),
      averageRating: (json['averageRating'] as num).toDouble(),
    );
  }
}

class RevenueByMonth {
  final String month;
  final double revenue;
  final int totalRides;

  const RevenueByMonth({
    required this.month,
    required this.revenue,
    required this.totalRides,
  });

  factory RevenueByMonth.fromJson(Map<String, dynamic> json) {
    return RevenueByMonth(
      month: json['month'] as String,
      revenue: (json['revenue'] as num).toDouble(),
      totalRides: json['totalRides'] as int,
    );
  }
}

class RidesByStatus {
  final String status;
  final int count;

  const RidesByStatus({
    required this.status,
    required this.count,
  });

  factory RidesByStatus.fromJson(Map<String, dynamic> json) {
    return RidesByStatus(
      status: json['status'] as String,
      count: json['count'] as int,
    );
  }
}

// ── Rides ────────────────────────────────────────────────────

class AdminRideModel {
  final String id;
  final RideUser user;
  final RideDriver? driver;
  final String pickupAddress;
  final String destinationAddress;
  final double distance;
  final double estimatedPrice;
  final double finalPrice;
  final String status;
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? cancelledBy;

  const AdminRideModel({
    required this.id,
    required this.user,
    this.driver,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.distance,
    required this.estimatedPrice,
    required this.finalPrice,
    required this.status,
    required this.requestedAt,
    this.acceptedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.cancelledBy,
  });

  factory AdminRideModel.fromJson(Map<String, dynamic> json) {
    return AdminRideModel(
      id: json['id'] as String,
      user: RideUser.fromJson(json['user']),
      driver: json['driver'] != null ? RideDriver.fromJson(json['driver']) : null,
      pickupAddress: json['pickupAddress'] as String,
      destinationAddress: json['destinationAddress'] as String,
      distance: (json['distance'] as num).toDouble(),
      estimatedPrice: (json['estimatedPrice'] as num).toDouble(),
      finalPrice: (json['finalPrice'] as num).toDouble(),
      status: json['status'] as String,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      acceptedAt: json['acceptedAt'] != null ? DateTime.parse(json['acceptedAt'] as String) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt'] as String) : null,
      cancellationReason: json['cancellationReason'] as String?,
      cancelledBy: json['cancelledBy'] as String?,
    );
  }
}

class RideUser {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String email;

  const RideUser({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
  });

  factory RideUser.fromJson(Map<String, dynamic> json) {
    return RideUser(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String,
    );
  }
}

class RideDriver {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String licensePlate;

  const RideDriver({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.licensePlate,
  });

  factory RideDriver.fromJson(Map<String, dynamic> json) {
    return RideDriver(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      licensePlate: json['licensePlate'] as String,
    );
  }
}

// ── Vehicle Types ──────────────────────────────────────────

class VehicleTypeModel {
  final String id;
  final String name;
  final double basePrice;
  final double pricePerKm;
  final String? description;
  final bool isActive;
  final int totalDrivers;
  final int totalRides;

  const VehicleTypeModel({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.pricePerKm,
    this.description,
    required this.isActive,
    required this.totalDrivers,
    required this.totalRides,
  });

  factory VehicleTypeModel.fromJson(Map<String, dynamic> json) {
    return VehicleTypeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      basePrice: (json['basePrice'] as num).toDouble(),
      pricePerKm: (json['pricePerKm'] as num).toDouble(),
      description: json['description'] as String?,
      isActive: json['isActive'] as bool,
      totalDrivers: json['totalDrivers'] as int,
      totalRides: json['totalRides'] as int,
    );
  }
}
