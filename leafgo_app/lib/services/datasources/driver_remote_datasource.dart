import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:leafgo_app/models/booking/ride_model.dart';
import 'package:leafgo_app/models/driver/driver_stats_model.dart';
import 'package:leafgo_app/models/driver/driver_vehicle_model.dart';

abstract class DriverRemoteDataSource {
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
}

class DriverRemoteDataSourceImpl implements DriverRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  DriverRemoteDataSourceImpl({required this.client, required this.baseUrl});

  @override
  Future<Map<String, dynamic>> toggleOnline(bool isOnline, String token) async {
    final response = await client.put(
      Uri.parse('$baseUrl/api/Drivers/toggle-online'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'isOnline': isOnline}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['data'];
      }
    }
    throw Exception('Failed to toggle online status: ${response.body}');
  }

  @override
  Future<void> updateLocation(double lat, double lng, String token) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/Drivers/update-location'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'latitude': lat, 'longitude': lng}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update location: ${response.body}');
    }
  }

  @override
  Future<List<dynamic>> getPendingRides(
    double lat,
    double lng,
    int radius,
    String token,
  ) async {
    final response = await client.get(
      Uri.parse(
        '$baseUrl/api/Drivers/pending-rides?latitude=$lat&longitude=$lng&radius=$radius',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['data'] ?? [];
      }
    }
    throw Exception('Failed to load pending rides: ${response.body}');
  }

  @override
  Future<Map<String, dynamic>> acceptRide(
    String rideId,
    String version,
    String token,
  ) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/Drivers/accept-ride'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'rideId': rideId, 'version': version}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['data'];
      }
    }
    throw Exception('Failed to accept ride: ${response.body}');
  }

  @override
  Future<void> updateRideStatus(
    String rideId,
    String status,
    double? finalPrice,
    String token,
  ) async {
    final body = <String, dynamic>{
      'rideId': rideId,
      'status': status,
      if (finalPrice != null) 'finalPrice': finalPrice,
    };

    final response = await client.put(
      Uri.parse('$baseUrl/api/Drivers/update-ride-status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update ride status: ${response.body}');
    }
  }

  @override
  Future<RideModel?> getCurrentRide(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/Drivers/current-ride'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return RideModel.fromJson(data['data']);
      }
      return null;
    }
    throw Exception('Failed to load current ride: ${response.body}');
  }

  @override
  Future<DriverStatsModel> getStatistics(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/Drivers/statistics'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return DriverStatsModel.fromJson(data['data']);
      }
    }
    throw Exception('Failed to load statistics: ${response.body}');
  }

  @override
  Future<DriverVehicleModel?> getVehicle(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/Drivers/vehicle'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return DriverVehicleModel.fromJson(data['data']);
      }
      return null;
    }
    return null;
  }

  @override
  Future<DriverVehicleModel> updateVehicle(
    Map<String, dynamic> vehicleData,
    String token,
  ) async {
    final response = await client.put(
      Uri.parse('$baseUrl/api/Drivers/vehicle'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(vehicleData),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return DriverVehicleModel.fromJson(data['data']);
      }
    }
    throw Exception('Failed to update vehicle: ${response.body}');
  }
}
