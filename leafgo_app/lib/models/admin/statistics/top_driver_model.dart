class TopDriver {
  final String id;
  final String fullName;
  final String? avatar;
  final int totalRides;
  final double totalEarnings;
  final double averageRating;

  const TopDriver({
    required this.id,
    required this.fullName,
    this.avatar,
    required this.totalRides,
    required this.totalEarnings,
    required this.averageRating,
  });

  factory TopDriver.fromJson(Map<String, dynamic> json) {
    return TopDriver(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      avatar: json['avatar'] as String?,
      totalRides: json['totalRides'] as int,
      totalEarnings: (json['totalEarnings'] as num).toDouble(),
      averageRating: (json['averageRating'] as num).toDouble(),
    );
  }
}
