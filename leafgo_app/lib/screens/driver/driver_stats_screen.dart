import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/driver/driver_bloc.dart';
import 'driver_reviews_screen.dart';

class DriverStatsScreen extends StatefulWidget {
  const DriverStatsScreen({super.key});

  @override
  State<DriverStatsScreen> createState() => _DriverStatsScreenState();
}

class _DriverStatsScreenState extends State<DriverStatsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DriverBloc>().add(DriverLoadProfile());
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF10B981);
    const gradientStart = Color(0xFF0F9F70);
    const gradientEnd = Color(0xFF076F4B);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Doanh Thu Tài Xế', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        centerTitle: true,
        backgroundColor: gradientEnd,
        elevation: 0,
      ),
      body: BlocBuilder<DriverBloc, DriverState>(
        builder: (context, state) {
          if (state.isLoading && state.stats == null) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          final stats = state.stats;
          if (stats == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Không thể tải dữ liệu thống kê', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<DriverBloc>().add(DriverLoadProfile()),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                    child: const Text('Tải lại'),
                  ),
                ],
              ),
            );
          }

          final formatter = NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0);

          return RefreshIndicator(
            onRefresh: () async {
              context.read<DriverBloc>().add(DriverLoadProfile());
            },
            color: primaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // 1. Sleek Gradient Card Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [gradientStart, gradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TỔNG THU NHẬP', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const SizedBox(height: 8),
                        Text(
                          formatter.format(stats.totalEarnings),
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _headerMiniStat('Chuyến đi', stats.totalRides.toString()),
                            _headerMiniStat(
                              'Đánh giá',
                              '${stats.averageRating.toStringAsFixed(1)} ★',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const DriverReviewsScreen()),
                                );
                              },
                            ),
                            _headerMiniStat(
                              'Đánh giá từ khách',
                              stats.totalReviews.toString(),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const DriverReviewsScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 2. Earnings Grid Breakdown
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chi tiết thu nhập',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.4,
                          children: [
                            _statsCard(
                              title: 'Hôm nay',
                              value: formatter.format(stats.todayEarnings),
                              subValue: '${stats.todayRides} chuyến đi',
                              icon: Icons.today,
                              color: Colors.blue,
                            ),
                            _statsCard(
                              title: 'Tuần này',
                              value: formatter.format(stats.thisWeekEarnings),
                              subValue: '${stats.thisWeekRides} chuyến đi',
                              icon: Icons.calendar_view_week,
                              color: Colors.orange,
                            ),
                            _statsCard(
                              title: 'Tháng này',
                              value: formatter.format(stats.thisMonthEarnings),
                              subValue: '${stats.thisMonthRides} chuyến đi',
                              icon: Icons.calendar_month,
                              color: Colors.purple,
                            ),
                            _statsCard(
                              title: 'Hiệu suất',
                              value: '100%',
                              subValue: 'Không hủy chuyến',
                              icon: Icons.trending_up,
                              color: primaryColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F7F0),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: primaryColor.withOpacity(0.15)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.tips_and_updates, color: primaryColor, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Chạy xe vào khung giờ cao điểm (7h - 9h, 17h - 19h) để tăng gấp đôi thu nhập của bạn nhé!',
                                  style: TextStyle(fontSize: 12, color: Colors.green.shade800, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _headerMiniStat(String label, String value, {VoidCallback? onTap}) {
    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: child,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: child,
    );
  }

  Widget _statsCard({
    required String title,
    required String value,
    required String subValue,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold)),
              Icon(icon, color: color.withOpacity(0.8), size: 18),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 2),
              Text(subValue, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }
}
