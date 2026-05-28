import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:leafgo_app/models/driver/driver_daily_detail.dart';
import 'package:leafgo_app/models/driver/driver_stats_model.dart';
import '../../blocs/driver/driver_bloc.dart';
import 'driver_reviews_screen.dart';

class DriverStatsScreen extends StatefulWidget {
  const DriverStatsScreen({super.key});

  @override
  State<DriverStatsScreen> createState() => _DriverStatsScreenState();
}

class _DriverStatsScreenState extends State<DriverStatsScreen> {
  static const _green = Color(0xFF059669);
  static const _greenDark = Color(0xFF065F46);
  static const _greenMid = Color(0xFF047857);
  static const _greenLight = Color(0xFFECFDF5);
  static const _greenAccent = Color(0xFFA7F3D0);

  @override
  void initState() {
    super.initState();
    context.read<DriverBloc>().add(DriverLoadProfile());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: BlocBuilder<DriverBloc, DriverState>(
        builder: (context, state) {
          if (state.isLoading && state.stats == null) {
            return const Center(
              child: CircularProgressIndicator(color: _green),
            );
          }

          final stats = state.stats;
          if (stats == null) {
            return _buildError(context);
          }

          final vnd = NumberFormat.simpleCurrency(
            locale: 'vi_VN',
            decimalDigits: 0,
          );

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<DriverBloc>().add(DriverLoadProfile()),
            color: _green,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildSliverAppBar(context, stats, vnd),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Tổng quan'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _overviewCard(
                                icon: Icons.wb_sunny_rounded,
                                iconBg: _greenLight,
                                iconColor: _green,
                                label: 'Hôm nay',
                                amount: vnd.format(stats.todayEarnings),
                                rides: '${stats.todayRides} chuyến đi',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _overviewCard(
                                icon: Icons.calendar_view_week_rounded,
                                iconBg: const Color(0xFFEFF6FF),
                                iconColor: const Color(0xFF3B82F6),
                                label: 'Tuần này',
                                amount: vnd.format(stats.thisWeekEarnings),
                                rides: '${stats.thisWeekRides} chuyến đi',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _sectionLabel('Thu nhập 7 ngày qua'),
                        const SizedBox(height: 10),
                        _WeeklyChart(stats: stats, formatter: vnd),
                        const SizedBox(height: 20),
                        _sectionLabel('Chi tiết theo ngày'),
                        const SizedBox(height: 10),
                        _DailyList(stats: stats, formatter: vnd),
                        const SizedBox(height: 16),
                        _TipBanner(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    DriverStatsModel stats,
    NumberFormat vnd,
  ) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: _greenDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        color: Colors.white,
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Doanh Thu Tài Xế',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: _HeroCard(stats: stats, formatter: vnd),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.analytics_outlined, size: 56, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Không thể tải dữ liệu',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () =>
                context.read<DriverBloc>().add(DriverLoadProfile()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Tải lại'),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.black45,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _overviewCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String amount,
    required String rides,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(height: 10),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
          const SizedBox(height: 1),
          Text(
            rides,
            style: const TextStyle(fontSize: 10, color: Colors.black38),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.stats, required this.formatter});
  final DriverStatsModel stats;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = DateFormat('MMMM • yyyy', 'vi_VN').format(now);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF047857), Color(0xFF065F46)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 10,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'THU NHẬP THÁNG NÀY',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatter.format(stats.thisMonthEarnings),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    month,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(0.15)),
                      ),
                    ),
                    padding: const EdgeInsets.only(top: 14),
                    child: Row(
                      children: [
                        _miniStat('${stats.thisMonthRides}', 'Chuyến đi'),
                        _divider(),
                        _miniStat(
                          '${stats.averageRating.toStringAsFixed(1)} ★',
                          'Đánh giá',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DriverReviewsScreen(),
                            ),
                          ),
                        ),
                        _divider(),
                        _miniStat(
                          '${stats.totalReviews}',
                          'Nhận xét',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DriverReviewsScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label, {VoidCallback? onTap}) {
    final content = Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9),
          ),
        ],
      ),
    );
    if (onTap != null) {
      return Expanded(
        child: GestureDetector(onTap: onTap, child: content),
      );
    }
    return content;
  }

  Widget _divider() => Container(
    width: 1,
    height: 30,
    color: Colors.white.withOpacity(0.15),
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );
}

// ─── Weekly Bar Chart ─────────────────────────────────────────────────────────

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.stats, required this.formatter});
  final DriverStatsModel stats;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    final todayWeekday = DateTime.now().weekday; // 1 (Mon) to 7 (Sun)
    final days = [
      _DayData('T2', stats.weekDailyEarnings[0], todayWeekday == 1),
      _DayData('T3', stats.weekDailyEarnings[1], todayWeekday == 2),
      _DayData('T4', stats.weekDailyEarnings[2], todayWeekday == 3),
      _DayData('T5', stats.weekDailyEarnings[3], todayWeekday == 4),
      _DayData('T6', stats.weekDailyEarnings[4], todayWeekday == 5),
      _DayData('T7', stats.weekDailyEarnings[5], todayWeekday == 6),
      _DayData('CN', stats.weekDailyEarnings[6], todayWeekday == 7),
    ];

    final maxVal = days.map((d) => d.amount).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Biểu đồ tuần',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '+12% so tuần trước',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text(
            'Đơn vị: nghìn đồng',
            style: TextStyle(fontSize: 10, color: Colors.black38),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((d) {
                final ratio = maxVal > 0 ? d.amount / maxVal : 0.0;
                final barH = (ratio * 72).clamp(6.0, 72.0);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          height: barH,
                          decoration: BoxDecoration(
                            color: d.isToday
                                ? const Color(0xFF059669)
                                : const Color(0xFFA7F3D0),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          d.label,
                          style: TextStyle(
                            fontSize: 9,
                            color: d.isToday
                                ? const Color(0xFF059669)
                                : Colors.black38,
                            fontWeight: d.isToday
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _legend(const Color(0xFF059669), 'Hôm nay'),
              const SizedBox(width: 14),
              _legend(const Color(0xFFA7F3D0), 'Ngày trước'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45)),
    ],
  );
}

class _DayData {
  const _DayData(this.label, this.amount, this.isToday);
  final String label;
  final double amount;
  final bool isToday;
}

// ─── Daily List ───────────────────────────────────────────────────────────────

class _DailyList extends StatelessWidget {
  const _DailyList({required this.stats, required this.formatter});
  final DriverStatsModel stats;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    final dailyItems = stats.weekDailyDetails;

    if (dailyItems.isEmpty) {
      return _buildFallback(context);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: List.generate(dailyItems.length, (i) {
          final item = dailyItems[i];
          return _DailyRow(
            item: item,
            formatter: formatter,
            isLast: i == dailyItems.length - 1,
          );
        }),
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    final today = DateTime.now();
    final items = List.generate(5, (i) {
      final date = today.subtract(Duration(days: i));
      return DriverDailyDetail(
        date: date,
        amount: i == 0 ? stats.todayEarnings.toDouble() : 0,
        rides: i == 0 ? stats.todayRides : 0,
        isToday: i == 0,
      );
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: List.generate(
          items.length,
          (i) => _DailyRow(
            item: items[i],
            formatter: formatter,
            isLast: i == items.length - 1,
          ),
        ),
      ),
    );
  }
}

class _DailyRow extends StatelessWidget {
  const _DailyRow({
    required this.item,
    required this.formatter,
    required this.isLast,
  });
  final DriverDailyDetail item;
  final NumberFormat formatter;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final weekdays = [
      '',
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
      'CN',
    ];
    final dayLabel = item.isToday
        ? 'Hôm nay, ${item.date.day}/${item.date.month}'
        : '${weekdays[item.date.weekday]}, ${item.date.day}/${item.date.month}';

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.isToday
                  ? const Color(0xFF059669)
                  : const Color(0xFFA7F3D0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: item.isToday
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${item.rides} chuyến đi',
                  style: const TextStyle(fontSize: 10, color: Colors.black38),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatter.format(item.amount),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (item.isToday) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'đang chạy',
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFF065F46),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Tip Banner ───────────────────────────────────────────────────────────────

class _TipBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: Color(0xFF059669),
            size: 18,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF065F46),
                  height: 1.5,
                ),
                children: [
                  TextSpan(text: 'Chạy vào khung giờ cao điểm '),
                  TextSpan(
                    text: '7h–9h',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ' và '),
                  TextSpan(
                    text: '17h–19h',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ' để tăng gấp đôi thu nhập mỗi ngày!'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
