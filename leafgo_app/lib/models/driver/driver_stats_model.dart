import 'package:leafgo_app/models/driver/driver_daily_detail.dart';

class DriverStatsModel {
  final int totalRides;
  final double totalEarnings;
  final double averageRating;
  final int totalReviews;
  final int todayRides;
  final double todayEarnings;
  final int thisWeekRides;
  final double thisWeekEarnings;
  final int thisMonthRides;
  final double thisMonthEarnings;
  final List<double> weekDailyEarnings;
  final List<DriverDailyDetail> weekDailyDetails;

  DriverStatsModel({
    required this.totalRides,
    required this.totalEarnings,
    required this.averageRating,
    required this.totalReviews,
    required this.todayRides,
    required this.todayEarnings,
    required this.thisWeekRides,
    required this.thisWeekEarnings,
    required this.thisMonthRides,
    required this.thisMonthEarnings,
    required this.weekDailyEarnings,
    required this.weekDailyDetails,
  });

  factory DriverStatsModel.fromJson(Map<String, dynamic> json) {
    final todayRides = json['todayRides'] ?? 0;
    final todayEarnings = (json['todayEarnings'] ?? 0).toDouble();
    final thisWeekRides = json['thisWeekRides'] ?? 0;
    final thisWeekEarnings = (json['thisWeekEarnings'] ?? 0).toDouble();

    // Parse weekDailyEarnings if present, otherwise calculate
    List<double> parsedWeekDailyEarnings;
    if (json['weekDailyEarnings'] != null) {
      parsedWeekDailyEarnings = List<double>.from(
        (json['weekDailyEarnings'] as List).map((e) => (e ?? 0).toDouble()),
      );
    } else {
      parsedWeekDailyEarnings = _calculateWeekDailyEarnings(
        todayEarnings: todayEarnings,
        thisWeekEarnings: thisWeekEarnings,
      );
    }

    // Parse weekDailyDetails if present, otherwise calculate
    List<DriverDailyDetail> parsedWeekDailyDetails;
    if (json['weekDailyDetails'] != null) {
      parsedWeekDailyDetails = List<DriverDailyDetail>.from(
        (json['weekDailyDetails'] as List).map(
          (e) => DriverDailyDetail.fromJson(e),
        ),
      );
    } else {
      parsedWeekDailyDetails = _calculateWeekDailyDetails(
        todayRides: todayRides,
        todayEarnings: todayEarnings,
        thisWeekRides: thisWeekRides,
        thisWeekEarnings: thisWeekEarnings,
      );
    }

    return DriverStatsModel(
      totalRides: json['totalRides'] ?? 0,
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      todayRides: todayRides,
      todayEarnings: todayEarnings,
      thisWeekRides: thisWeekRides,
      thisWeekEarnings: thisWeekEarnings,
      thisMonthRides: json['thisMonthRides'] ?? 0,
      thisMonthEarnings: (json['thisMonthEarnings'] ?? 0).toDouble(),
      weekDailyEarnings: parsedWeekDailyEarnings,
      weekDailyDetails: parsedWeekDailyDetails,
    );
  }

  static List<double> _calculateWeekDailyEarnings({
    required double todayEarnings,
    required double thisWeekEarnings,
  }) {
    final now = DateTime.now();
    final todayWeekday = now.weekday; // 1 (Mon) to 7 (Sun)
    final result = List<double>.filled(7, 0.0);
    final todayIndex = todayWeekday - 1;

    result[todayIndex] = todayEarnings;

    final remainingEarnings = thisWeekEarnings - todayEarnings;
    if (remainingEarnings <= 0) {
      return result;
    }

    final pastDaysCount = todayIndex;
    if (pastDaysCount <= 0) {
      result[0] = thisWeekEarnings;
      return result;
    }

    final base = remainingEarnings / pastDaysCount;
    for (int i = 0; i < todayIndex; i++) {
      result[i] = base;
    }

    return result;
  }

  static List<DriverDailyDetail> _calculateWeekDailyDetails({
    required int todayRides,
    required double todayEarnings,
    required int thisWeekRides,
    required double thisWeekEarnings,
  }) {
    final now = DateTime.now();
    final result = <DriverDailyDetail>[];
    final todayWeekday = now.weekday;

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final isToday = i == 0;

      double amount = 0;
      int rides = 0;

      if (isToday) {
        amount = todayEarnings;
        rides = todayRides;
      } else {
        if (i < todayWeekday) {
          final remainingDays = todayWeekday - 1;
          if (remainingDays > 0) {
            amount = (thisWeekEarnings - todayEarnings) / remainingDays;
            rides = ((thisWeekRides - todayRides) / remainingDays).round();
          }
        }
      }

      result.add(
        DriverDailyDetail(
          date: date,
          amount: amount,
          rides: rides,
          isToday: isToday,
        ),
      );
    }

    return result;
  }
}
