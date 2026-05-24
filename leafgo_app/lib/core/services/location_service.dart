import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:leafgo_app/models/booking_models.dart';

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
          Uri.parse('$_orsApiUrl/geocode/search').replace(queryParameters: {
            'api_key': _orsApiKey,
            'text': query,
            'boundary.country': 'VN',
            'size': '5',
          }),
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
                lat: double.tryParse(coords[1].toString()) ?? 0.0,
                lng: double.tryParse(coords[0].toString()) ?? 0.0,
              );
            }).where((location) => location.hasValidCoordinates).toList();
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
      Uri.parse('$_nominatimUrl/search').replace(queryParameters: {
        'q': query,
        'format': 'json',
        'addressdetails': '1',
        'limit': '5',
        'countrycodes': 'vn',
      }),
      headers: {
        'Accept-Language': 'vi',
        'User-Agent': 'LeafGoApp/1.0 (com.leafgo.app)',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data
          .map((item) => LocationModel.fromJson(item))
          .where((location) => location.hasValidCoordinates)
          .toList();
    }
    return [];
  }

  Future<List<LatLng>> getRoute(LocationModel pickup, LocationModel dropoff) async {
    if (!pickup.hasValidCoordinates || !dropoff.hasValidCoordinates) {
      return [];
    }

    final response = await http.get(
      Uri.parse('$_osrmUrl/${pickup.lng},${pickup.lat};${dropoff.lng},${dropoff.lat}').replace(queryParameters: {
        'overview': 'full',
        'geometries': 'geojson',
      }),
      headers: {
        'User-Agent': 'LeafGoApp/1.0 (com.leafgo.app)',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final coordinates = data['routes'][0]['geometry']?['coordinates'];
        if (coordinates is List) {
          return coordinates
              .whereType<List>()
              .map((coords) {
                if (coords.length < 2) return null;
                final lat = double.tryParse(coords[1].toString());
                final lng = double.tryParse(coords[0].toString());
                if (lat == null || lng == null) return null;
                return LatLng(lat, lng);
              })
              .whereType<LatLng>()
              .where(_isValidLatLng)
              .toList();
        }
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

    return Future.error('Could not determine current location.');
  }

  Future<LocationModel?> reverseGeocode(double lat, double lng) async {
    if (!_isValidLatLng(LatLng(lat, lng))) {
      return null;
    }

    // 1. Try using OpenRouteService if API Key is configured
    if (_orsApiKey.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse('$_orsApiUrl/geocode/reverse').replace(queryParameters: {
            'api_key': _orsApiKey,
            'point.lon': lng.toString(),
            'point.lat': lat.toString(),
            'size': '1',
          }),
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
            return LocationModel(
              fullAddress: props['label'] ?? props['name'] ?? '',
              lat: lat,
              lng: lng,
            );
          }
        }
      } catch (e) {
        print('OpenRouteService reverse geocode failed: $e. Falling back to Nominatim.');
      }
    }

    // 2. Fallback to Nominatim (Public, no API key required)
    final response = await http.get(
      Uri.parse('$_nominatimUrl/reverse').replace(queryParameters: {
        'lat': lat.toString(),
        'lon': lng.toString(),
        'format': 'json',
      }),
      headers: {
        'Accept-Language': 'vi',
        'User-Agent': 'LeafGoApp/1.0 (com.leafgo.app)',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return LocationModel(
        fullAddress: data['display_name'] ?? '',
        lat: lat,
        lng: lng,
      );
    }
    return null;
  }

  bool _isValidLatLng(LatLng point) {
    return point.latitude >= -90 &&
        point.latitude <= 90 &&
        point.longitude >= -180 &&
        point.longitude <= 180;
  }
}
