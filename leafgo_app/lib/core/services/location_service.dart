import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:leafgo_app/features/booking/data/models/booking_models.dart';

class LocationService {
  // Env variables resolved at compile time via --dart-define-from-file
  static const String _orsApiKey = String.fromEnvironment(
    'VITE_ORS_API_KEY',
    defaultValue: 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjNiNTRkZDAyZjZhODQwNThiNmI5YzZjOThmNmI5ZGQyIiwiaCI6Im11cm11cjY0In0=',
  );
  static const String _orsApiUrl = String.fromEnvironment('VITE_ORS_API', defaultValue: 'https://api.openrouteservice.org/v2');
  static const String _nominatimUrl = String.fromEnvironment('VITE_NOMINATIM_API', defaultValue: 'https://nominatim.openstreetmap.org');
  static const String _osrmUrl = 'https://router.project-osrm.org/route/v1/driving';

  Future<List<LocationModel>> searchLocations(String query) async {
    // 1. Try using OpenRouteService if API Key is configured
    if (_orsApiKey.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse('$_orsApiUrl/geocode/search?api_key=$_orsApiKey&text=$query&boundary.country=VN&size=5'),
          headers: {
            'Accept-Language': 'vi',
            'User-Agent': 'LeafGoApp/1.0 (com.leafgo.app)',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List features = data['features'] ?? [];
          if (features.isNotEmpty) {
            return features.map((item) {
              final props = item['properties'] ?? {};
              final geom = item['geometry'] ?? {};
              final coords = geom['coordinates'] ?? [0.0, 0.0];
              return LocationModel(
                fullAddress: props['label'] ?? props['name'] ?? '',
                lat: double.parse(coords[1].toString()),
                lng: double.parse(coords[0].toString()),
              );
            }).toList();
          } else {
            print('OpenRouteService returned 0 features. Falling back to Nominatim.');
          }
        }
      } catch (e) {
        print('OpenRouteService geocode search failed: $e. Falling back to Nominatim.');
      }
    }

    // 2. Fallback to Nominatim (Public, no API key required)
    final response = await http.get(
      Uri.parse('$_nominatimUrl/search?q=$query&format=json&addressdetails=1&limit=5&countrycodes=vn'),
      headers: {
        'Accept-Language': 'vi',
        'User-Agent': 'LeafGoApp/1.0 (com.leafgo.app)',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((item) => LocationModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<List<LatLng>> getRoute(LocationModel pickup, LocationModel dropoff) async {
    final response = await http.get(
      Uri.parse('$_osrmUrl/${pickup.lng},${pickup.lat};${dropoff.lng},${dropoff.lat}?overview=full&geometries=polyline'),
      headers: {
        'User-Agent': 'LeafGoApp/1.0 (com.leafgo.app)',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final String encodedPolyline = data['routes'][0]['geometry'];
        return _decodePolyline(encodedPolyline);
      }
    }
    return [];
  }

  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    } 

    Position? lastKnown;
    try {
      lastKnown = await Geolocator.getLastKnownPosition();
    } catch (_) {}

    if (lastKnown != null && lastKnown.latitude != 0.0 && lastKnown.longitude > 0.0) {
      return lastKnown;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 10));
      
      if (pos.latitude != 0.0 && pos.longitude > 0.0) {
        return pos;
      }
    } catch (_) {}

    return Position(
      latitude: 10.8458,
      longitude: 106.7945,
      timestamp: DateTime.now(),
      accuracy: 1.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }

  Future<LocationModel?> reverseGeocode(double lat, double lng) async {
    // 1. Try using OpenRouteService if API Key is configured
    if (_orsApiKey.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse('$_orsApiUrl/geocode/reverse?api_key=$_orsApiKey&point.lon=$lng&point.lat=$lat&size=1'),
          headers: {
            'Accept-Language': 'vi',
            'User-Agent': 'LeafGoApp/1.0 (com.leafgo.app)',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List features = data['features'] ?? [];
          if (features.isNotEmpty) {
            final first = features.first;
            final props = first['properties'] ?? {};
            final geom = first['geometry'] ?? {};
            final coords = geom['coordinates'] ?? [lng, lat];
            return LocationModel(
              fullAddress: props['label'] ?? props['name'] ?? '',
              lat: double.parse(coords[1].toString()),
              lng: double.parse(coords[0].toString()),
            );
          }
        }
      } catch (e) {
        print('OpenRouteService reverse geocode failed: $e. Falling back to Nominatim.');
      }
    }

    // 2. Fallback to Nominatim (Public, no API key required)
    final response = await http.get(
      Uri.parse('$_nominatimUrl/reverse?lat=$lat&lon=$lng&format=json'),
      headers: {
        'Accept-Language': 'vi',
        'User-Agent': 'LeafGoApp/1.0 (com.leafgo.app)',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return LocationModel.fromJson(data);
    }
    return null;
  }

  // Helper to decode Google Polyline algorithm
  List<LatLng> _decodePolyline(String str) {
    var index = 0;
    var lat = 0;
    var lng = 0;
    List<LatLng> polyline = [];

    while (index < str.length) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = str.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = str.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }
}
