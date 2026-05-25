import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/booking_models.dart';

abstract class BookingRemoteDataSource {
  Future<List<VehicleType>> getVehicleTypes(String token);

  Future<Map<String, dynamic>> calculateTripPrice(
    double plat,
    double plng,
    double dlat,
    double dlng,
    String typeId,
  );

  Future<RideModel> createRide(Map<String, dynamic> rideData, String token);

  Future<RideModel?> getActiveRide(String token);

  Future<RideModel> getRideById(String rideId, String token);

  Future<void> cancelRide(String rideId, String reason, String token);

  Future<void> submitRating(
    String rideId,
    int rating,
    String comment,
    String token,
  );
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  BookingRemoteDataSourceImpl({required this.client, required this.baseUrl});

  Map<String, String> authHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<String> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('leafgo_access_token');

    if (token == null || token.isEmpty) {
      throw Exception('User not logged in');
    }

    return token;
  }

  @override
  Future<List<VehicleType>> getVehicleTypes(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/Rides/vehicle-types'),
      headers: authHeaders(token),
    );

    print('VEHICLE TYPES: ${response.statusCode}');
    print(response.body);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['success'] == true) {
        final List list = data['data'];

        return list.map((e) => VehicleType.fromJson(e)).toList();
      }
    }

    throw Exception('Failed to load vehicle types');
  }

  @override
  Future<Map<String, dynamic>> calculateTripPrice(
    double plat,
    double plng,
    double dlat,
    double dlng,
    String typeId,
  ) async {
    final token = await getSavedToken();

    final response = await client.post(
      Uri.parse('$baseUrl/api/Rides/calculate-price'),
      headers: authHeaders(token),
      body: json.encode({
        'pickupLatitude': plat,
        'pickupLongitude': plng,
        'destinationLatitude': dlat,
        'destinationLongitude': dlng,
        'vehicleTypeId': typeId,
      }),
    );

    print('CALCULATE PRICE: ${response.statusCode}');
    print(response.body);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['success'] == true) {
        return data['data'];
      }

      throw Exception(data['message'] ?? 'Calculate failed');
    }

    if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    }

    throw Exception('Failed to calculate price');
  }

  @override
  Future<RideModel> createRide(
    Map<String, dynamic> rideData,
    String token,
  ) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/Rides'),
      headers: authHeaders(token),
      body: json.encode(rideData),
    );

    print('CREATE RIDE: ${response.statusCode}');
    print(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);

      if (data['success'] == true) {
        return RideModel.fromJson(data['data']);
      }
    }

    throw Exception('Failed to create ride');
  }

  @override
  Future<RideModel?> getActiveRide(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/Rides/active'),
      headers: authHeaders(token),
    );

    print('ACTIVE RIDE: ${response.statusCode}');
    print(response.body);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['success'] == true && data['data'] != null) {
        return RideModel.fromJson(data['data']);
      }

      return null;
    }

    if (response.statusCode == 403) {
      throw Exception('Forbidden - Driver role not allowed');
    }

    throw Exception('Failed to get active ride');
  }

  @override
  Future<RideModel> getRideById(String rideId, String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/Rides/$rideId'),
      headers: authHeaders(token),
    );

    print('GET RIDE: ${response.statusCode}');
    print(response.body);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['success'] == true) {
        return RideModel.fromJson(data['data']);
      }
    }

    throw Exception('Failed to get ride details');
  }

  @override
  Future<void> cancelRide(String rideId, String reason, String token) async {
    final response = await client.put(
      Uri.parse('$baseUrl/api/Rides/$rideId/cancel'),
      headers: authHeaders(token),
      body: json.encode({'reason': reason}),
    );

    print('CANCEL RIDE: ${response.statusCode}');
    print(response.body);

    if (response.statusCode != 200) {
      throw Exception('Failed to cancel ride');
    }
  }

  @override
  Future<void> submitRating(
    String rideId,
    int rating,
    String comment,
    String token,
  ) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/Rides/$rideId/rate'),
      headers: authHeaders(token),
      body: json.encode({'rating': rating, 'comment': comment}),
    );

    print('RATE RIDE: ${response.statusCode}');
    print(response.body);

    if (response.statusCode != 200) {
      throw Exception('Failed to submit rating');
    }
  }
}
