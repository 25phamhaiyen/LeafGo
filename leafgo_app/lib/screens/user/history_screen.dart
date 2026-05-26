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

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<UserBloc>().add(UserFetchHistory());
  }

  void _showHistoryRatingDialog(BuildContext context, String rideId) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        int localRating = 5;
        final commentCtrl = TextEditingController();
        bool isSending = false;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Đánh giá chuyến đi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Hãy chọn số sao và chia sẻ cảm nhận của bạn về chuyến đi.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (starIdx) {
                      final starVal = starIdx + 1;
                      final isSelected = starVal <= localRating;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            localRating = starVal;
                          });
                        },
                        child: Icon(
                          isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: isSelected ? Colors.amber : Colors.grey.shade300,
                          size: 36,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentCtrl,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Ý kiến đóng góp (không bắt buộc)...',
                      hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF10B981)),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          setDialogState(() {
                            isSending = true;
                          });
                          try {
                            final authLocal = sl<AuthLocalDataSource>();
                            final user = await authLocal.getCachedUser();
                            final token = user?.accessToken;
                            if (token == null) throw Exception('Vui lòng đăng nhập lại');

                            await sl<BookingRepository>().submitRating(
                              rideId,
                              localRating,
                              commentCtrl.text,
                              token,
                            );

                            if (!context.mounted) return;
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đánh giá thành công!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            // Refresh history
                            context.read<UserBloc>().add(UserFetchHistory());
                          } catch (e) {
                            setDialogState(() {
                              isSending = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Gửi'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF10B981);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử chuyến đi'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state.isLoading && state.historyData == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null) {
            return Center(child: Text('Lỗi: ${state.error}'));
          }

          final items = state.historyData?['items'] as List? ?? [];

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Bạn chưa có chuyến đi nào', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => context.read<UserBloc>().add(UserFetchHistory()),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final ride = items[index];
                final date = DateTime.parse(ride['requestedAt']);
                final status = ride['status'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(date),
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getStatusText(status),
                                style: TextStyle(
                                  color: _getStatusColor(status),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildLocationRow(Icons.circle, Colors.green, ride['pickupAddress']),
                        const Padding(
                          padding: EdgeInsets.only(left: 11),
                          child: SizedBox(height: 10, child: VerticalDivider(width: 1, thickness: 1)),
                        ),
                        _buildLocationRow(Icons.location_on, Colors.red, ride['destinationAddress']),
                        
                        // Rating Display / Submit Rating
                        if (status == 'Completed') ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          if (ride['rating'] != null)
                            Row(
                              children: [
                                Row(
                                  children: List.generate(5, (starIdx) {
                                    final starRating = (ride['rating']['rating'] as num).toInt();
                                    return Icon(
                                      starIdx < starRating ? Icons.star_rounded : Icons.star_outline_rounded,
                                      color: Colors.amber,
                                      size: 16,
                                    );
                                  }),
                                ),
                                if (ride['rating']['comment'] != null &&
                                    ride['rating']['comment'].toString().trim().isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '"${ride['rating']['comment']}"',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontStyle: FontStyle.italic,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Chưa có đánh giá',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _showHistoryRatingDialog(context, ride['id']),
                                  icon: const Icon(Icons.star_rounded, size: 14),
                                  label: const Text(
                                    'Đánh giá ngay',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    minimumSize: const Size(60, 28),
                                  ),
                                ),
                              ],
                            ),
                        ],

                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ride['driver'] != null ? ride['driver']['fullName'] : 'Đã hủy',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${ride['finalPrice'] ?? ride['estimatedPrice'] ?? 0}đ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, Color color, String address) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      case 'InProgress':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
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
}
