import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/user/user_bloc.dart';
import '../../injection_container.dart';
import '../../services/datasources/auth_local_datasource.dart';
import '../../services/repositories/booking_repository.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
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
  static const Color _divider = Color(0xFFF3F4F6);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    context.read<UserBloc>().add(UserFetchHistory());
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return _primary;
      case 'Cancelled':
        return const Color(0xFFEF4444);
      case 'InProgress':
        return const Color(0xFF3B82F6);
      case 'Pending':
        return const Color(0xFFF59E0B);
      default:
        return _textSecondary;
    }
  }

  Color _statusBg(String status) => _statusColor(status).withOpacity(0.1);

  String _statusText(String status) {
    switch (status) {
      case 'Completed':
        return 'Hoàn thành';
      case 'Cancelled':
        return 'Đã hủy';
      case 'InProgress':
        return 'Đang đi';
      case 'Pending':
        return 'Đang tìm';
      default:
        return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Completed':
        return Icons.check_circle_rounded;
      case 'Cancelled':
        return Icons.cancel_rounded;
      case 'InProgress':
        return Icons.directions_car_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }

  String _formatCurrency(num amount) {
    final f = NumberFormat('#,###', 'vi_VN');
    return '${f.format(amount)}đ';
  }

  // ─── Stats ───────────────────────────────────────────────────────────────────

  Map<String, dynamic> _computeStats(List items) {
    int completed = 0;
    double totalSpent = 0;
    double totalRating = 0;
    int ratingCount = 0;

    for (final ride in items) {
      if (ride['status'] == 'Completed') {
        completed++;
        totalSpent +=
            (ride['finalPrice'] ?? ride['estimatedPrice'] ?? 0) as num;
        if (ride['rating'] != null) {
          totalRating += (ride['rating']['rating'] as num).toDouble();
          ratingCount++;
        }
      }
    }

    return {
      'completed': completed,
      'totalSpent': totalSpent,
      'avgRating': ratingCount > 0 ? totalRating / ratingCount : 0.0,
      'ratingCount': ratingCount,
    };
  }

  // ─── Rating Dialog ───────────────────────────────────────────────────────────

  void _showRatingDialog(BuildContext context, String rideId) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        int localRating = 5;
        final commentCtrl = TextEditingController();
        bool isSending = false;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 40,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: _primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Đánh giá chuyến đi',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Chia sẻ cảm nhận của bạn về chuyến đi này',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: _textSecondary),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final val = i + 1;
                        return GestureDetector(
                          onTap: () => setDialogState(() => localRating = val),
                          child: AnimatedScale(
                            scale: val <= localRating ? 1.15 : 1.0,
                            duration: const Duration(milliseconds: 150),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: Icon(
                                val <= localRating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: val <= localRating
                                    ? Colors.amber
                                    : Colors.grey.shade300,
                                size: 40,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: commentCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Ý kiến đóng góp (không bắt buộc)...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _primary),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSending
                                ? null
                                : () => Navigator.pop(dialogCtx),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: const Text(
                              'Hủy',
                              style: TextStyle(color: _textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSending
                                ? null
                                : () async {
                                    setDialogState(() => isSending = true);
                                    try {
                                      final authLocal =
                                          sl<AuthLocalDataSource>();
                                      final user = await authLocal
                                          .getCachedUser();
                                      final token = user?.accessToken;
                                      if (token == null) {
                                        throw Exception(
                                          'Vui lòng đăng nhập lại',
                                        );
                                      }
                                      await sl<BookingRepository>()
                                          .submitRating(
                                            rideId,
                                            localRating,
                                            commentCtrl.text,
                                            token,
                                          );
                                      if (!context.mounted) return;
                                      Navigator.pop(dialogCtx);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                              SizedBox(width: 8),
                                              Text('Đánh giá thành công!'),
                                            ],
                                          ),
                                          backgroundColor: _primary,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      );
                                      context.read<UserBloc>().add(
                                        UserFetchHistory(),
                                      );
                                    } catch (e) {
                                      setDialogState(() => isSending = false);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Lỗi: $e'),
                                          backgroundColor: const Color(
                                            0xFFEF4444,
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: isSending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Gửi đánh giá',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Detail Bottom Sheet ─────────────────────────────────────────────────────

  void _showDetailSheet(BuildContext context, Map ride) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(
        ride: ride,
        onRate: () {
          Navigator.pop(context);
          _showRatingDialog(context, ride['id']);
        },
        formatCurrency: _formatCurrency,
        statusColor: _statusColor,
        statusBg: _statusBg,
        statusText: _statusText,
        statusIcon: _statusIcon,
      ),
    );
  }

  // ─── Stats Header ────────────────────────────────────────────────────────────

  Widget _buildStatsHeader(List items) {
    final stats = _computeStats(items);
    final completed = stats['completed'] as int;
    final totalSpent = stats['totalSpent'] as double;
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
          BoxShadow(
            color: _primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // decorative circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng quan',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hành trình của bạn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _StatPill(
                      icon: Icons.directions_car_rounded,
                      value: '$completed',
                      label: 'Chuyến đi',
                    ),
                    const SizedBox(width: 10),
                    _StatPill(
                      icon: Icons.payments_rounded,
                      value: totalSpent >= 1000000
                          ? '${(totalSpent / 1000000).toStringAsFixed(1)}M'
                          : totalSpent >= 1000
                          ? '${(totalSpent / 1000).toStringAsFixed(0)}K'
                          : totalSpent.toStringAsFixed(0),
                      label: 'Tổng chi (đ)',
                    ),
                    const SizedBox(width: 10),
                    _StatPill(
                      icon: Icons.star_rounded,
                      value: ratingCount > 0
                          ? avgRating.toStringAsFixed(1)
                          : '--',
                      label: 'Đánh giá TB',
                      isRating: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Ride Card ───────────────────────────────────────────────────────────────

  Widget _buildRideCard(Map ride, int index) {
    final date = DateTime.parse(ride['requestedAt']);
    final status = ride['status'] as String;
    final price = ride['finalPrice'] ?? ride['estimatedPrice'] ?? 0;
    final driverName = ride['driver'] != null
        ? ride['driver']['fullName']
        : 'Không có tài xế';
    final hasRating = ride['rating'] != null;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 0.08 * (index + 1)),
          end: Offset.zero,
        ).animate(_fadeAnim),
        child: GestureDetector(
          onTap: () => _showDetailSheet(context, ride),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _statusBg(status),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _statusIcon(status),
                                  size: 12,
                                  color: _statusColor(status),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _statusText(status),
                                  style: TextStyle(
                                    color: _statusColor(status),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('dd/MM/yyyy · HH:mm').format(date),
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Route
                      _buildRouteRow(
                        ride['pickupAddress'],
                        ride['destinationAddress'],
                      ),
                    ],
                  ),
                ),
                // Footer
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      // Driver avatar placeholder
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: _primaryLight,
                        backgroundImage:
                            ride['driver']?['avatar'] != null &&
                                ride['driver']['avatar'].toString().isNotEmpty
                            ? NetworkImage(ride['driver']['avatar'])
                            : null,
                        child:
                            ride['driver']?['avatar'] == null ||
                                ride['driver']['avatar'].toString().isEmpty
                            ? Text(
                                driverName.isNotEmpty
                                    ? driverName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: _primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          driverName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                      ),
                      // Rating stars (if completed & rated)
                      if (status == 'Completed' && hasRating) ...[
                        Row(
                          children: List.generate(5, (i) {
                            final r = (ride['rating']['rating'] as num).toInt();
                            return Icon(
                              i < r
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: Colors.amber,
                              size: 13,
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (status == 'Completed' && !hasRating) ...[
                        GestureDetector(
                          onTap: () => _showRatingDialog(context, ride['id']),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: _primary,
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Đánh giá',
                                  style: TextStyle(
                                    color: _primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        _formatCurrency(price as num),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _primary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            Container(width: 1.5, height: 22, color: Colors.grey.shade300),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pickup,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: _textPrimary),
              ),
              const SizedBox(height: 14),
              Text(
                destination,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: _textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Lịch sử chuyến đi',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: _textPrimary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _textPrimary,
      ),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state.isLoading && state.historyData == null) {
            return const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          }

          if (state.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 60,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Lỗi: ${state.error}',
                    style: const TextStyle(color: _textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<UserBloc>().add(UserFetchHistory()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Thử lại'),
                  ),
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
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: _primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_car_rounded,
                      size: 48,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Chưa có chuyến đi nào',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Các chuyến đi của bạn sẽ xuất hiện tại đây',
                    style: TextStyle(fontSize: 13, color: _textSecondary),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: _primary,
            onRefresh: () async =>
                context.read<UserBloc>().add(UserFetchHistory()),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildStatsHeader(items)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _buildRideCard(items[i], i),
                      childCount: items.length,
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
}

// ─── Stat Pill Widget ────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.value,
    required this.label,
    this.isRating = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool isRating;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: Colors.white70),
                if (isRating && value != '--') ...[
                  const SizedBox(width: 3),
                  const Icon(Icons.star_rounded, size: 10, color: Colors.amber),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Detail Bottom Sheet ─────────────────────────────────────────────────────

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({
    required this.ride,
    required this.onRate,
    required this.formatCurrency,
    required this.statusColor,
    required this.statusBg,
    required this.statusText,
    required this.statusIcon,
  });

  final Map ride;
  final VoidCallback onRate;
  final String Function(num) formatCurrency;
  final Color Function(String) statusColor;
  final Color Function(String) statusBg;
  final String Function(String) statusText;
  final IconData Function(String) statusIcon;

  static const Color _primary = Color(0xFF10B981);
  static const Color _primaryLight = Color(0xFFD1FAE5);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textSecondary = Color(0xFF6B7280);

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor ?? _textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: _textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = ride['status'] as String;
    final date = DateTime.parse(ride['requestedAt']);
    final completedAt = ride['completedAt'] != null
        ? DateTime.parse(ride['completedAt'])
        : null;
    final price = ride['finalPrice'] ?? ride['estimatedPrice'] ?? 0;
    final driver = ride['driver'];
    final vehicle = driver?['vehicle'];
    final hasRating = ride['rating'] != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Title bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Chi tiết chuyến đi',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg(status),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon(status),
                          size: 12,
                          color: statusColor(status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText(status),
                          style: TextStyle(
                            color: statusColor(status),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                children: [
                  // Price Hero
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primary, Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.payments_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Tổng cước phí',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const Spacer(),
                        Text(
                          formatCurrency(price as num),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Route Card
                  _sectionCard(
                    title: 'Lộ trình',
                    child: Column(
                      children: [
                        _infoRow(
                          Icons.radio_button_checked_rounded,
                          'Điểm đón',
                          ride['pickupAddress'],
                          iconColor: _primary,
                        ),
                        const SizedBox(height: 4),
                        _infoRow(
                          Icons.location_on_rounded,
                          'Điểm đến',
                          ride['destinationAddress'],
                          iconColor: const Color(0xFFEF4444),
                        ),
                        if (ride['distance'] != null &&
                            ride['distance'] != 0) ...[
                          const Divider(height: 16),
                          _infoRow(
                            Icons.straighten_rounded,
                            'Quãng đường',
                            '${(ride['distance'] as num).toStringAsFixed(1)} km',
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Time Card
                  _sectionCard(
                    title: 'Thời gian',
                    child: Column(
                      children: [
                        _infoRow(
                          Icons.access_time_rounded,
                          'Đặt xe lúc',
                          DateFormat('HH:mm · dd/MM/yyyy').format(date),
                        ),
                        if (completedAt != null) ...[
                          const Divider(height: 16),
                          _infoRow(
                            Icons.flag_rounded,
                            'Hoàn thành lúc',
                            DateFormat(
                              'HH:mm · dd/MM/yyyy',
                            ).format(completedAt),
                            iconColor: _primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Driver Card
                  if (driver != null) ...[
                    _sectionCard(
                      title: 'Tài xế',
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: _primaryLight,
                                backgroundImage:
                                    driver['avatar'] != null &&
                                        driver['avatar'].toString().isNotEmpty
                                    ? NetworkImage(driver['avatar'])
                                    : null,
                                child:
                                    driver['avatar'] == null ||
                                        driver['avatar'].toString().isEmpty
                                    ? Text(
                                        driver['fullName']
                                            .toString()[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: _primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      driver['fullName'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: _textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      driver['phoneNumber'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: _textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (vehicle != null) ...[
                            const Divider(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _vehicleChip(
                                    Icons.directions_car_rounded,
                                    '${vehicle['vehicleBrand']} ${vehicle['vehicleModel']}',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _vehicleChip(
                                    Icons.confirmation_number_rounded,
                                    vehicle['licensePlate'],
                                  ),
                                ),
                              ],
                            ),
                            if (vehicle['vehicleColor'] != null) ...[
                              const SizedBox(height: 8),
                              _vehicleChip(
                                Icons.palette_rounded,
                                'Màu ${vehicle['vehicleColor']}',
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Rating Card
                  if (status == 'Completed')
                    _sectionCard(
                      title: 'Đánh giá',
                      child: hasRating
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Row(
                                      children: List.generate(5, (i) {
                                        final r =
                                            (ride['rating']['rating'] as num)
                                                .toInt();
                                        return Icon(
                                          i < r
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          color: Colors.amber,
                                          size: 22,
                                        );
                                      }),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${(ride['rating']['rating'] as num).toInt()}/5',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: _textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (ride['rating']['comment'] != null &&
                                    ride['rating']['comment']
                                        .toString()
                                        .trim()
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.format_quote_rounded,
                                          size: 16,
                                          color: _textSecondary,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            ride['rating']['comment'],
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontStyle: FontStyle.italic,
                                              color: _textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            )
                          : Column(
                              children: [
                                const Text(
                                  'Bạn chưa đánh giá chuyến đi này',
                                  style: TextStyle(
                                    color: _textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: onRate,
                                    icon: const Icon(
                                      Icons.star_rounded,
                                      size: 16,
                                    ),
                                    label: const Text('Đánh giá ngay'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
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
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _vehicleChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
