import 'package:leafgo_app/models/admin/ride/ride_driver.dart';
import 'package:leafgo_app/models/admin/ride/ride_rating.dart';
import 'package:leafgo_app/models/admin/ride/ride_use.dart';

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
  final RideRating? rating;

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
    this.rating,
  });

  factory AdminRideModel.fromJson(Map<String, dynamic> json) {
    return AdminRideModel(
      id: json['id'] as String,
      user: json['user'] != null
          ? RideUser.fromJson(json['user'])
          : const RideUser(
              id: '',
              fullName: 'Unknown User',
              phoneNumber: '',
              email: '',
            ),
      driver: json['driver'] != null
          ? RideDriver.fromJson(json['driver'])
          : null,
      pickupAddress: json['pickupAddress'] as String,
      destinationAddress: json['destinationAddress'] as String,
      distance: (json['distance'] as num).toDouble(),
      estimatedPrice: (json['estimatedPrice'] as num).toDouble(),
      finalPrice: (json['finalPrice'] as num).toDouble(),
      status: json['status'] as String,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      cancellationReason: json['cancellationReason'] as String?,
      cancelledBy: json['cancelledBy'] as String?,
      rating: json['rating'] != null
          ? RideRating.fromJson(json['rating'])
          : null,
    );
  }
}
