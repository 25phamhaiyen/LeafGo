import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static const int port = 8000;

  static String get baseUrl {
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:$port';
    }

    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:$port'
        : 'http://127.0.0.1:$port';
  }
}
