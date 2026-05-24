import 'package:flutter/foundation.dart';

class ApiConstants {
  // Docker Compose / Nginx port is 8000. Local dotnet run port is 8080.
  // Change this port to 8080 if running the backend locally directly (dotnet run).
  static const int port = 8000;

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:$port';
    }
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:$port'
        : 'http://127.0.0.1:$port';
  }
}
