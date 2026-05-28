class DriverDailyDetail {
  final DateTime date;
  final double amount;
  final int rides;
  final bool isToday;

  DriverDailyDetail({
    required this.date,
    required this.amount,
    required this.rides,
    required this.isToday,
  });

  factory DriverDailyDetail.fromJson(Map<String, dynamic> json) {
    return DriverDailyDetail(
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      amount: (json['amount'] ?? 0).toDouble(),
      rides: json['rides'] ?? 0,
      isToday: json['isToday'] ?? false,
    );
  }
}
