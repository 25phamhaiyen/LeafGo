import 'package:leafgo_app/models/booking/vehicle_info.dart';

class DriverModel {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? avatar;
  final double averageRating;
  final int totalRides;
  final VehicleInfo? vehicle;

  DriverModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.avatar,
    required this.averageRating,
    required this.totalRides,
    this.vehicle,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? json['name'] ?? 'N/A',
      phoneNumber: json['phoneNumber'] ?? json['phone'] ?? 'N/A',
      avatar: json['avatar'] ?? json['avatarUrl'],
      averageRating: (json['averageRating'] ?? json['rating'] ?? 0).toDouble(),
      totalRides: json['totalRides'] ?? json['numberOfRides'] ?? 0,
      vehicle: json['vehicle'] != null
          ? VehicleInfo.fromJson(json['vehicle'])
          : null,
    );
  }
}
