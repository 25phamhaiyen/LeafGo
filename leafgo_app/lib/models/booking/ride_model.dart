import 'package:leafgo_app/models/booking/driver_model.dart';
import 'package:leafgo_app/models/booking/ride_user_model.dart';

class RideModel {
  final String id;
  final String status;
  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final String destinationAddress;
  final double destinationLatitude;
  final double destinationLongitude;
  final double distance;
  final int estimatedDuration;
  final double estimatedPrice;
  final double? finalPrice;
  final String? notes;
  final DriverModel? driver;
  final RideUserModel? user;

  RideModel({
    required this.id,
    required this.status,
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.destinationAddress,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.distance,
    required this.estimatedDuration,
    required this.estimatedPrice,
    this.finalPrice,
    this.notes,
    this.driver,
    this.user,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['id'],
      status: json['status'],
      pickupAddress: json['pickupAddress'],
      pickupLatitude: (json['pickupLatitude'] ?? 0).toDouble(),
      pickupLongitude: (json['pickupLongitude'] ?? 0).toDouble(),
      destinationAddress: json['destinationAddress'],
      destinationLatitude: (json['destinationLatitude'] ?? 0).toDouble(),
      destinationLongitude: (json['destinationLongitude'] ?? 0).toDouble(),
      distance: (json['distance'] ?? 0).toDouble(),
      estimatedDuration: json['estimatedDuration'] ?? 0,
      estimatedPrice: (json['estimatedPrice'] ?? 0).toDouble(),
      finalPrice: json['finalPrice'] != null
          ? (json['finalPrice'] as num).toDouble()
          : null,
      notes: json['notes'],
      driver: json['driver'] != null
          ? DriverModel.fromJson(json['driver'])
          : null,
      user: json['user'] != null ? RideUserModel.fromJson(json['user']) : null,
    );
  }
}
