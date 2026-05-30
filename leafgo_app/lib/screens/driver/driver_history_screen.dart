import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/driver/driver_bloc.dart';
import '../../injection_container.dart';

class DriverHistoryScreen extends StatefulWidget {
  const DriverHistoryScreen({super.key});

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const Color _primary = Color(0xFF10B981);
  static const Color _primaryDark = Color(0xFF059669);
  static const Color _primaryLight = Color(0xFFD1FAE5);
  static const Color _bg = Color(0xFFF8FAFB);
  static const Color _cardBg = Colors.white;
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textSecondary = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    context.read<DriverBloc>().add(DriverFetchHistory());
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed': return _primary;
      case 'Cancelled': return const Color(0xFFEF4444);
      case 'InProgress': return const Color(0xFF3B82F6);
      case 'Pending': return const Color(0xFFF59E0B);
      default: return _textSecondary;
    }
  }

  Color _statusBg(String status) => _statusColor(status).withOpacity(0.1);

  String _statusText(String status) {
    switch (status) {
      case 'Completed': return 'Hoàn thành';
      case 'Cancelled': return 'Đã hủy';
      case 'InProgress': return 'Đang đi';
      case 'Pending': return 'Đang tìm';
      default: return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Completed': return Icons.check_circle_rounded;
      case 'Cancelled': return Icons.cancel_rounded;
      case 'InProgress': return Icons.directions_car_rounded;
      default: return Icons.access_time_rounded;
    }
  }

  String _formatCurrency(num amount) {
    final f = NumberFormat('#,###', 'vi_VN');
    return '${f.format(amount)}đ';
  }

  Map<String, dynamic> _computeStats(List items) {
    int completed = 0;
    double totalEarned = 0;
    double totalRating = 0;
    int ratingCount = 0;

    for (final ride in items) {
      if (ride['status'] == 'Completed') {
        completed++;
        totalEarned += (ride['finalPrice'] ?? ride['estimatedPrice'] ?? 0) as num;
        if (ride['rating'] != null) {
          totalRating += (ride['rating']['rating'] as num).toDouble();
          ratingCount++;
        }
      }
    }

    return {
      'completed': completed,
      'totalEarned': totalEarned,
      'avgRating': ratingCount > 0 ? totalRating / ratingCount : 0.0,
      'ratingCount': ratingCount,
    };
  }

  Widget _buildStatsHeader(List items) {
    final stats = _computeStats(items);
    final completed = stats['completed'] as int;
    final totalEarned = stats['totalEarned'] as double;
    final avgRating = stats['avgRating'] as double;
    final ratingCount = stats['ratingCount'] as int;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(right: -20, top: -20, child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)))),
          Positioned(right: 30, bottom: -30, child: Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tổng quan', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                const Text('Hành trình của bạn', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _StatPill(icon: Icons.directions_car_rounded, value: '$completed', label: 'Chuyến đi'),
                    const SizedBox(width: 10),
                    _StatPill(icon: Icons.payments_rounded, value: totalEarned >= 1000000 ? '${(totalEarned / 1000000).toStringAsFixed(1)}M' : totalEarned >= 1000 ? '${(totalEarned / 1000).toStringAsFixed(0)}K' : totalEarned.toStringAsFixed(0), label: 'Doanh thu'),
                    const SizedBox(width: 10),
                    _StatPill(icon: Icons.star_rounded, value: ratingCount > 0 ? avgRating.toStringAsFixed(1) : '--', label: 'Đánh giá', isRating: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(Map ride, int index) {
    final date = DateTime.tryParse(ride['requestedAt'] ?? '') ?? DateTime.now();
    final status = ride['status'] as String? ?? 'Unknown';
    final price = ride['finalPrice'] ?? ride['estimatedPrice'] ?? 0;
    final userName = ride['user'] != null ? ride['user']['fullName'] ?? 'Khách' : 'Khách';
    final hasRating = ride['rating'] != null;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset(0, 0.08 * (index + 1)), end: Offset.zero).animate(_fadeAnim),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: _statusBg(status), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_statusIcon(status), size: 12, color: _statusColor(status)),
                              const SizedBox(width: 4),
                              Text(_statusText(status), style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(DateFormat('dd/MM/yyyy · HH:mm').format(date), style: const TextStyle(color: _textSecondary, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildRouteRow(ride['pickupAddress'] ?? '', ride['destinationAddress'] ?? ''),
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(color: Color(0xFFF9FAFB), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18))),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: _primaryLight,
                      backgroundImage: ride['user']?['avatar'] != null && ride['user']['avatar'].toString().isNotEmpty ? NetworkImage(ride['user']['avatar']) : null,
                      child: ride['user']?['avatar'] == null || ride['user']['avatar'].toString().isEmpty ? Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?', style: const TextStyle(color: _primary, fontSize: 12, fontWeight: FontWeight.bold)) : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(userName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textPrimary))),
                    if (status == 'Completed' && hasRating) ...[
                      Row(children: List.generate(5, (i) {
                        final r = (ride['rating']['rating'] as num).toInt();
                        return Icon(i < r ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 13);
                      })),
                      const SizedBox(width: 8),
                    ],
                    Text(_formatCurrency(price as num), style: const TextStyle(fontWeight: FontWeight.w800, color: _primary, fontSize: 15)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteRow(String pickup, String destination) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: _primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5), boxShadow: [BoxShadow(color: _primary.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 1))])),
            Container(width: 1.5, height: 22, color: Colors.grey.shade300),
            Container(width: 10, height: 10, decoration: BoxDecoration(color: const Color(0xFFEF4444), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5), boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 1))])),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pickup, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: _textPrimary)),
              const SizedBox(height: 14),
              Text(destination, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: _textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(title: const Text('Lịch sử cuốc xe', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: _textPrimary)), centerTitle: true, elevation: 0, backgroundColor: _bg, surfaceTintColor: Colors.transparent, foregroundColor: _textPrimary),
      body: BlocBuilder<DriverBloc, DriverState>(
        builder: (context, state) {
          if (state.isLoading && state.historyData == null) {
            return const Center(child: CircularProgressIndicator(color: _primary));
          }

          if (state.error != null && state.historyData == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('Lỗi: ${state.error}', style: const TextStyle(color: _textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => context.read<DriverBloc>().add(DriverFetchHistory()), style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Thử lại')),
                ],
              ),
            );
          }

          final items = state.historyData?['items'] as List? ?? [];

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 96, height: 96, decoration: BoxDecoration(color: _primaryLight, shape: BoxShape.circle), child: const Icon(Icons.directions_car_rounded, size: 48, color: _primary)),
                  const SizedBox(height: 20),
                  const Text('Chưa có chuyến đi nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textPrimary)),
                  const SizedBox(height: 6),
                  const Text('Các cuốc xe của bạn sẽ xuất hiện tại đây', style: TextStyle(fontSize: 13, color: _textSecondary)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: _primary,
            onRefresh: () async => context.read<DriverBloc>().add(DriverFetchHistory()),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildStatsHeader(items)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  sliver: SliverList(delegate: SliverChildBuilderDelegate((_, i) => _buildRideCard(items[i], i), childCount: items.length)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.value, required this.label, this.isRating = false});
  final IconData icon;
  final String value;
  final String label;
  final bool isRating;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, size: 14, color: Colors.white70), if (isRating && value != '--') ...[const SizedBox(width: 3), const Icon(Icons.star_rounded, size: 10, color: Colors.amber)]]),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
