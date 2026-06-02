import 'package:leafgo_app/models/admin/statistics/revenue_by_month.dart';
import 'package:leafgo_app/models/admin/statistics/ride_by_status.dart';
import 'package:leafgo_app/models/admin/statistics/top_driver_model.dart';

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
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      todayRevenue: (json['todayRevenue'] as num?)?.toDouble() ?? 0.0,
      thisMonthRevenue: (json['thisMonthRevenue'] as num?)?.toDouble() ?? 0.0,
      topDrivers: (json['topDrivers'] as List)
          .map((e) => TopDriver.fromJson(e))
          .toList(),
      revenueByMonth: (json['revenueByMonth'] as List)
          .map((e) => RevenueByMonth.fromJson(e))
          .toList(),
      ridesByStatus: (json['ridesByStatus'] as List)
          .map((e) => RidesByStatus.fromJson(e))
          .toList(),
    );
  }
}
