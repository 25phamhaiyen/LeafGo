class RidesByStatus {
  final String status;
  final int count;

  const RidesByStatus({required this.status, required this.count});

  factory RidesByStatus.fromJson(Map<String, dynamic> json) {
    return RidesByStatus(
      status: json['status'] as String,
      count: json['count'] as int,
    );
  }
}
