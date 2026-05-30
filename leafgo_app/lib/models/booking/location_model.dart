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
    // Reject (0,0) — the default "no data" value returned when GPS fails.
    if (lat == 0.0 && lng == 0.0) return false;
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
