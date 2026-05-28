class ApiError {
  final String error;
  final Map<String, String>? details;
  final DateTime timestamp;

  const ApiError({required this.error, this.details, required this.timestamp});

  factory ApiError.fromJson(Map<String, dynamic> json) {
    final raw = json['details'] as Map<String, dynamic>?;
    return ApiError(
      error: json['error'] as String,
      details: raw?.map((k, v) => MapEntry(k, v.toString())),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  String get firstDetail => details?.values.firstOrNull ?? error;
}
