import 'package:leafgo_app/features/booking/data/datasources/booking_remote_datasource.dart';
import 'package:leafgo_app/features/booking/data/models/booking_models.dart';



abstract class BookingRepository {
  Future<List<VehicleType>> getVehicleTypes(String token);
  Future<Map<String, dynamic>> calculateTripPrice(double plat, double plng, double dlat, double dlng, String typeId);
  Future<RideModel> createRide(Map<String, dynamic> rideData, String token);
  Future<RideModel?> getActiveRide(String token);
  Future<RideModel> getRideById(String rideId, String token);
  Future<void> cancelRide(String rideId, String reason, String token);
  Future<void> submitRating(String rideId, int rating, String comment, String token);
}

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remote;

  BookingRepositoryImpl({required this.remote});

  @override
  Future<List<VehicleType>> getVehicleTypes(String token) => remote.getVehicleTypes(token);

  @override
  Future<Map<String, dynamic>> calculateTripPrice(double plat, double plng, double dlat, double dlng, String typeId) =>
      remote.calculateTripPrice(plat, plng, dlat, dlng, typeId);

  @override
  Future<RideModel> createRide(Map<String, dynamic> rideData, String token) => remote.createRide(rideData, token);

  @override
  Future<RideModel?> getActiveRide(String token) => remote.getActiveRide(token);

  @override
  Future<RideModel> getRideById(String rideId, String token) => remote.getRideById(rideId, token);

  @override
  Future<void> cancelRide(String rideId, String reason, String token) => remote.cancelRide(rideId, reason, token);

  @override
  Future<void> submitRating(String rideId, int rating, String comment, String token) =>
      remote.submitRating(rideId, rating, comment, token);
}
