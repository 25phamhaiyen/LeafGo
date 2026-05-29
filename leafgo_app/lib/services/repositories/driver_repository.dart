import 'package:leafgo_app/models/booking/ride_model.dart';
import 'package:leafgo_app/models/driver/driver_stats_model.dart';
import 'package:leafgo_app/models/driver/driver_vehicle_model.dart';

import '../datasources/driver_remote_datasource.dart';

abstract class DriverRepository {
  Future<Map<String, dynamic>> toggleOnline(bool isOnline, String token);
  Future<void> updateLocation(double lat, double lng, String token);
  Future<List<dynamic>> getPendingRides(
    double lat,
    double lng,
    int radius,
    String token,
  );
  Future<Map<String, dynamic>> acceptRide(
    String rideId,
    String version,
    String token,
  );
  Future<void> updateRideStatus(
    String rideId,
    String status,
    double? finalPrice,
    String token,
  );
  Future<RideModel?> getCurrentRide(String token);
  Future<DriverStatsModel> getStatistics(String token);
  Future<DriverVehicleModel?> getVehicle(String token);
  Future<DriverVehicleModel> updateVehicle(
    Map<String, dynamic> vehicleData,
    String token,
  );
  Future<Map<String, dynamic>> getRideHistory(int page, int pageSize, String token);
}

class DriverRepositoryImpl implements DriverRepository {
  final DriverRemoteDataSource remote;

  DriverRepositoryImpl({required this.remote});

  @override
  Future<Map<String, dynamic>> toggleOnline(bool isOnline, String token) =>
      remote.toggleOnline(isOnline, token);

  @override
  Future<void> updateLocation(double lat, double lng, String token) =>
      remote.updateLocation(lat, lng, token);

  @override
  Future<List<dynamic>> getPendingRides(
    double lat,
    double lng,
    int radius,
    String token,
  ) => remote.getPendingRides(lat, lng, radius, token);

  @override
  Future<Map<String, dynamic>> acceptRide(
    String rideId,
    String version,
    String token,
  ) => remote.acceptRide(rideId, version, token);

  @override
  Future<void> updateRideStatus(
    String rideId,
    String status,
    double? finalPrice,
    String token,
  ) => remote.updateRideStatus(rideId, status, finalPrice, token);

  @override
  Future<RideModel?> getCurrentRide(String token) =>
      remote.getCurrentRide(token);

  @override
  Future<DriverStatsModel> getStatistics(String token) =>
      remote.getStatistics(token);

  @override
  Future<DriverVehicleModel?> getVehicle(String token) =>
      remote.getVehicle(token);

  @override
  Future<DriverVehicleModel> updateVehicle(
    Map<String, dynamic> vehicleData,
    String token,
  ) => remote.updateVehicle(vehicleData, token);

  @override
  Future<Map<String, dynamic>> getRideHistory(int page, int pageSize, String token) =>
      remote.getRideHistory(page, pageSize, token);
}
