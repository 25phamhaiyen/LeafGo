import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:leafgo_app/models/booking/location_model.dart';

class LocationService {
  // =========================
  // API CONFIG
  // =========================

  static const String _nominatimApi = String.fromEnvironment(
    'VITE_NOMINATIM_API',
    defaultValue: 'https://nominatim.openstreetmap.org',
  );

  static const String _orsApi = String.fromEnvironment(
    'VITE_ORS_API',
    defaultValue: 'https://api.openrouteservice.org/v2',
  );

  static const String _orsApiKey = String.fromEnvironment(
    'VITE_ORS_API_KEY',
    defaultValue: '',
  );

  // =========================
  // SEARCH LOCATION
  // =========================

  Future<List<LocationModel>> searchLocations(String query) async {
    if (query.trim().length < 3) {
      return [];
    }

    try {
      final uri = Uri.parse('$_nominatimApi/search').replace(
        queryParameters: {
          'format': 'json',
          'q': query,
          'limit': '10',
          'countrycodes': 'vn',
          'accept-language': 'vi',
        },
      );

      final response = await http
          .get(uri, headers: {'User-Agent': 'LeafGoApp/1.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);

        return data
            .map(
              (item) => LocationModel(
                fullAddress: item['display_name'] ?? 'Unknown location',

                lat: double.tryParse(item['lat'].toString()) ?? 0.0,

                lng: double.tryParse(item['lon'].toString()) ?? 0.0,
              ),
            )
            .where((e) => e.hasValidCoordinates)
            .toList();
      }
    } catch (e) {
      debugPrint('Search location error: $e');
    }

    return [];
  }

  // =========================
  // GET ROUTE
  // =========================

  Future<List<LatLng>> getRoute(LocationModel start, LocationModel end) async {
    try {
      if (!start.hasValidCoordinates || !end.hasValidCoordinates) {
        return [];
      }

      // =========================
      // USE OPENROUTESERVICE
      // =========================

      if (_orsApiKey.isNotEmpty) {
        final uri = Uri.parse('$_orsApi/directions/driving-car');

        final response = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $_orsApiKey',
              },
              body: jsonEncode({
                'coordinates': [
                  [start.lng, start.lat],
                  [end.lng, end.lat],
                ],
              }),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data['routes'] != null && data['routes'].isNotEmpty) {
            final route = data['routes'][0];

            if (route['geometry'] != null &&
                route['geometry']['coordinates'] != null) {
              final coordinates = route['geometry']['coordinates'] as List;

              return coordinates.map((coord) {
                return LatLng(coord[1], coord[0]);
              }).toList();
            }
          }
        }
      }

      // =========================
      // FALLBACK STRAIGHT LINE
      // =========================

      return [LatLng(start.lat, start.lng), LatLng(end.lat, end.lng)];
    } catch (e) {
      debugPrint('Get route error: $e');

      return [LatLng(start.lat, start.lng), LatLng(end.lat, end.lng)];
    }
  }

  // =========================
  // CURRENT POSITION
  // =========================

  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return Future.error('GPS chưa bật');
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return Future.error('Không có quyền vị trí');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Quyền vị trí bị từ chối vĩnh viễn');
    }

    try {
      final lastKnown = await Geolocator.getLastKnownPosition();

      if (lastKnown != null) {
        return lastKnown;
      }
    } catch (_) {}

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).timeout(const Duration(seconds: 15));

    return position;
  }

  // =========================
  // REVERSE GEOCODE
  // =========================

  Future<LocationModel?> reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse('$_nominatimApi/reverse').replace(
        queryParameters: {
          'format': 'json',
          'lat': lat.toString(),
          'lon': lng.toString(),
          'accept-language': 'vi',
        },
      );

      final response = await http
          .get(uri, headers: {'User-Agent': 'LeafGoApp/1.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return LocationModel(
          fullAddress: data['display_name'] ?? 'Unknown location',

          lat: lat,
          lng: lng,
        );
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    }

    return null;
  }

  Future<LocationModel?> getCurrentLocation() async {
    try {
      final position = await getCurrentPosition();

      final location = await reverseGeocode(
        position.latitude,
        position.longitude,
      );

      return location;
    } catch (e) {
      return null;
    }
  }
}
