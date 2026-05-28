class RevenueByMonth {
  final String month;
  final double revenue;
  final int totalRides;

  const RevenueByMonth({
    required this.month,
    required this.revenue,
    required this.totalRides,
  });

  factory RevenueByMonth.fromJson(Map<String, dynamic> json) {
    return RevenueByMonth(
      month: json['month'] as String,
      revenue: (json['revenue'] as num).toDouble(),
      totalRides: json['totalRides'] as int,
    );
  }
}
