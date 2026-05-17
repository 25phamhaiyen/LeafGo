import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/booking_models.dart';

abstract class BookingRemoteDataSource {
  Future<List<VehicleType>> getVehicleTypes(String token);
  Future<Map<String, dynamic>> calculateTripPrice(double plat, double plng, double dlat, double dlng, String typeId);
  Future<RideModel> createRide(Map<String, dynamic> rideData, String token);
  Future<RideModel?> getActiveRide(String token);
  Future<RideModel> getRideById(String rideId, String token);
  Future<void> cancelRide(String rideId, String reason, String token);
  Future<void> submitRating(String rideId, int rating, String comment, String token);
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  BookingRemoteDataSourceImpl({required this.client, required this.baseUrl});

  @override
  Future<List<VehicleType>> getVehicleTypes(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/Rides/vehicle-types'),
      headers: {'Authorization': 'Bearer $token'},
    );
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
  Future<Map<String, dynamic>> calculateTripPrice(double plat, double plng, double dlat, double dlng, String typeId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/Rides/calculate-price'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'pickupLatitude': plat,
        'pickupLongitude': plng,
        'destinationLatitude': dlat,
        'destinationLongitude': dlng,
        'vehicleTypeId': typeId,
      }),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['data'];
      }
    }
    throw Exception('Failed to calculate price');
  }

  @override
  Future<RideModel> createRide(Map<String, dynamic> rideData, String token) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/Rides'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(rideData),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return RideModel.fromJson(data['data']);
      }
    }
    throw Exception('Failed to create ride: ${response.body}');
  }

  @override
  Future<RideModel?> getActiveRide(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/Rides/active'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return RideModel.fromJson(data['data']);
      }
    }
    return null;
  }

  @override
  Future<RideModel> getRideById(String rideId, String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/Rides/$rideId'),
      headers: {'Authorization': 'Bearer $token'},
    );
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
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'reason': reason}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to cancel ride: ${response.body}');
    }
  }

  @override
  Future<void> submitRating(String rideId, int rating, String comment, String token) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/Rides/$rideId/rate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'rating': rating,
        'comment': comment,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to submit rating');
    }
  }
}
