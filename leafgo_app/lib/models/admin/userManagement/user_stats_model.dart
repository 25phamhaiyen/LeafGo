class UserStats {
  final int totalRides;
  final double totalSpent;
  final double totalEarnings;
  final double averageRating;

  const UserStats({
    required this.totalRides,
    required this.totalSpent,
    required this.totalEarnings,
    required this.averageRating,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalRides: json['totalRides'] as int,
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0.0,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
