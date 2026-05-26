
class DriverVehicleModel {
  final String id;
  final String vehicleTypeId;
  final String vehicleTypeName;
  final double basePrice;
  final double pricePerKm;
  final String licensePlate;
  final String vehicleBrand;
  final String vehicleModel;
  final String vehicleColor;
  final bool isActive;

  DriverVehicleModel({
    required this.id,
    required this.vehicleTypeId,
    required this.vehicleTypeName,
    required this.basePrice,
    required this.pricePerKm,
    required this.licensePlate,
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.isActive,
  });

  factory DriverVehicleModel.fromJson(Map<String, dynamic> json) {
    final vt = json['vehicleType'] ?? {};
    return DriverVehicleModel(
      id: json['id'] ?? '',
      vehicleTypeId: vt['id'] ?? '',
      vehicleTypeName: vt['name'] ?? '',
      basePrice: (vt['basePrice'] ?? 0).toDouble(),
      pricePerKm: (vt['pricePerKm'] ?? 0).toDouble(),
      licensePlate: json['licensePlate'] ?? '',
      vehicleBrand: json['vehicleBrand'] ?? '',
      vehicleModel: json['vehicleModel'] ?? '',
      vehicleColor: json['vehicleColor'] ?? '',
      isActive: json['isActive'] ?? false,
    );
  }
}

class DriverStatsModel {
  final int totalRides;
  final double totalEarnings;
  final double averageRating;
  final int totalReviews;
  final int todayRides;
  final double todayEarnings;
  final int thisWeekRides;
  final double thisWeekEarnings;
  final int thisMonthRides;
  final double thisMonthEarnings;

  DriverStatsModel({
    required this.totalRides,
    required this.totalEarnings,
    required this.averageRating,
    required this.totalReviews,
    required this.todayRides,
    required this.todayEarnings,
    required this.thisWeekRides,
    required this.thisWeekEarnings,
    required this.thisMonthRides,
    required this.thisMonthEarnings,
  });

  factory DriverStatsModel.fromJson(Map<String, dynamic> json) {
    return DriverStatsModel(
      totalRides: json['totalRides'] ?? 0,
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      todayRides: json['todayRides'] ?? 0,
      todayEarnings: (json['todayEarnings'] ?? 0).toDouble(),
      thisWeekRides: json['thisWeekRides'] ?? 0,
      thisWeekEarnings: (json['thisWeekEarnings'] ?? 0).toDouble(),
      thisMonthRides: json['thisMonthRides'] ?? 0,
      thisMonthEarnings: (json['thisMonthEarnings'] ?? 0).toDouble(),
    );
  }
}
