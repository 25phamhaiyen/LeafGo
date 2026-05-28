class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final DateTime timestamp;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    required this.timestamp,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
