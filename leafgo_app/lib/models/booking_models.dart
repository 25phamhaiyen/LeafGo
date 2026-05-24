import 'package:latlong2/latlong.dart';

class LocationModel {
  final String fullAddress;
  final double lat;
  final double lng;

  LocationModel({
    required this.fullAddress,
    required this.lat,
    required this.lng,
  });

  LatLng get toLatLng => LatLng(lat, lng);

  bool get hasValidCoordinates {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      fullAddress: json['fullAddress'] ?? json['display_name'] ?? '',
      lat: double.tryParse(json['lat'].toString()) ?? 0.0,
      lng: double.tryParse((json['lon'] ?? json['lng']).toString()) ?? 0.0,
    );
  }
}

class VehicleType {
  final String id;
  final String name;
  final int availableDrivers;
  final double basePrice;
  final double pricePerKm;
  final String? description;

  VehicleType({
    required this.id,
    required this.name,
    required this.availableDrivers,
    required this.basePrice,
    required this.pricePerKm,
    this.description,
  });

  factory VehicleType.fromJson(Map<String, dynamic> json) {
    return VehicleType(
      id: json['id'],
      name: json['name'],
      availableDrivers: json['availableDrivers'] ?? 0,
      basePrice: (json['basePrice'] ?? 0).toDouble(),
      pricePerKm: (json['pricePerKm'] ?? 0).toDouble(),
      description: json['description'],
    );
  }
}

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
      finalPrice: json['finalPrice'] != null ? (json['finalPrice'] as num).toDouble() : null,
      notes: json['notes'],
      driver: json['driver'] != null ? DriverModel.fromJson(json['driver']) : null,
    );
  }
}

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
      vehicle: json['vehicle'] != null ? VehicleInfo.fromJson(json['vehicle']) : null,
    );
  }
}

class VehicleInfo {
  final String licensePlate;
  final String brand;
  final String model;
  final String color;

  VehicleInfo({
    required this.licensePlate,
    required this.brand,
    required this.model,
    required this.color,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      licensePlate: json['licensePlate'] ?? 'N/A',
      brand: json['vehicleBrand'] ?? json['brand'] ?? 'N/A',
      model: json['vehicleModel'] ?? json['model'] ?? 'N/A',
      color: json['vehicleColor'] ?? json['color'] ?? 'N/A',
    );
  }
}
