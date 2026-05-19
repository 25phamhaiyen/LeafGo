import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/bloc/user_bloc.dart';

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
                                style: TextStyle(color: _getStatusColor(status), fontSize: 12, fontWeight: FontWeight.bold),
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
                              style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 18),
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
      case 'Completed': return Colors.green;
      case 'Cancelled': return Colors.red;
      case 'InProgress': return Colors.blue;
      default: return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Completed': return 'Hoàn thành';
      case 'Cancelled': return 'Đã hủy';
      case 'InProgress': return 'Đang đi';
      case 'Pending': return 'Đang tìm';
      default: return status;
    }
  }
}
