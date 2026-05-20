// lib/features/admin/presentation/pages/ride_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/models/admin_models.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class RideManagementScreen extends StatefulWidget {
  const RideManagementScreen({super.key});

  @override
  State<RideManagementScreen> createState() => _RideManagementScreenState();
}

class _RideManagementScreenState extends State<RideManagementScreen> {
  String? _status;
  DateTime? _fromDate;
  DateTime? _toDate;
  int _page = 1;

  String _token(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated ? authState.user.accessToken : '';
  }

  void _fetch(BuildContext context, {int? page}) {
    _page = page ?? _page;
    context.read<AdminBloc>().add(
      AdminFetchRides(
        accessToken: _token(context),
        page: _page,
        status: _status,
        fromDate: _fromDate,
        toDate: _toDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<AdminBloc>()..add(AdminFetchRides(accessToken: _token(context))),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(title: const Text('Lịch sử chuyến đi')),
            body: Column(
              children: [
                _RideFilters(
                  status: _status,
                  fromDate: _fromDate,
                  toDate: _toDate,
                  onStatusChanged: (value) {
                    setState(() => _status = value);
                    _fetch(context, page: 1);
                  },
                  onPickFrom: () async {
                    final value = await _pickDate(context, _fromDate);
                    if (value == null || !context.mounted) return;
                    setState(() => _fromDate = value);
                    _fetch(context, page: 1);
                  },
                  onPickTo: () async {
                    final value = await _pickDate(context, _toDate);
                    if (value == null || !context.mounted) return;
                    setState(
                      () => _toDate = DateTime(
                        value.year,
                        value.month,
                        value.day,
                        23,
                        59,
                      ),
                    );
                    _fetch(context, page: 1);
                  },
                  onClearDates: () {
                    setState(() {
                      _fromDate = null;
                      _toDate = null;
                    });
                    _fetch(context, page: 1);
                  },
                ),
                Expanded(
                  child: BlocBuilder<AdminBloc, AdminState>(
                    builder: (context, state) {
                      if (state is AdminLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is AdminRidesLoaded) {
                        return _RideList(
                          rides: state.rides,
                          onRefresh: () async => _fetch(context),
                          onPageChanged: (page) => _fetch(context, page: page),
                        );
                      }
                      if (state is AdminFailure) {
                        return Center(child: Text('Lỗi: ${state.message}'));
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime? initial) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDate: initial ?? now,
    );
  }
}

class _RideFilters extends StatelessWidget {
  final String? status;
  final DateTime? fromDate;
  final DateTime? toDate;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onClearDates;

  const _RideFilters({
    required this.status,
    required this.fromDate,
    required this.toDate,
    required this.onStatusChanged,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onClearDates,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('Tất cả', status == null, () => onStatusChanged(null)),
                _chip(
                  'Pending',
                  status == 'Pending',
                  () => onStatusChanged('Pending'),
                ),
                _chip(
                  'Accepted',
                  status == 'Accepted',
                  () => onStatusChanged('Accepted'),
                ),
                _chip(
                  'Completed',
                  status == 'Completed',
                  () => onStatusChanged('Completed'),
                ),
                _chip(
                  'Cancelled',
                  status == 'Cancelled',
                  () => onStatusChanged('Cancelled'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickFrom,
                  icon: const Icon(Icons.event),
                  label: Text(fromDate == null ? 'Từ ngày' : _date(fromDate!)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickTo,
                  icon: const Icon(Icons.event_available),
                  label: Text(toDate == null ? 'Đến ngày' : _date(toDate!)),
                ),
              ),
              IconButton(
                tooltip: 'Xóa lọc ngày',
                onPressed: onClearDates,
                icon: const Icon(Icons.clear),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _RideList extends StatelessWidget {
  final PaginatedResponse<AdminRideModel> rides;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onPageChanged;

  const _RideList({
    required this.rides,
    required this.onRefresh,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (rides.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: const [
            SizedBox(height: 160),
            Center(child: Text('Không có chuyến đi phù hợp.')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        itemCount: rides.items.length + 1,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == rides.items.length) {
            return _Pagination(
              page: rides.page,
              totalPages: rides.totalPages,
              hasPreviousPage: rides.hasPreviousPage,
              hasNextPage: rides.hasNextPage,
              onPageChanged: onPageChanged,
            );
          }
          final ride = rides.items[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _statusColor(
                ride.status,
              ).withValues(alpha: 0.12),
              child: Icon(Icons.route, color: _statusColor(ride.status)),
            ),
            title: Text('${ride.pickupAddress} → ${ride.destinationAddress}'),
            subtitle: Text(
              '${ride.user.fullName} • ${_dateTime(ride.requestedAt)}\n'
              '${ride.distance.toStringAsFixed(1)} km • ${_money(ride.finalPrice > 0 ? ride.finalPrice : ride.estimatedPrice)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            isThreeLine: true,
            trailing: Chip(
              label: Text(ride.status),
              visualDensity: VisualDensity.compact,
            ),
            onTap: () => _showRideDetails(context, ride),
          );
        },
      ),
    );
  }

  void _showRideDetails(BuildContext context, AdminRideModel ride) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => ListView(
        padding: const EdgeInsets.all(20),
        shrinkWrap: true,
        children: [
          Text(
            'Chi tiết chuyến đi',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _detail(
            'Khách hàng',
            '${ride.user.fullName} - ${ride.user.phoneNumber}',
          ),
          _detail(
            'Tài xế',
            ride.driver == null
                ? 'Chưa có'
                : '${ride.driver!.fullName} - ${ride.driver!.licensePlate}',
          ),
          const Divider(),
          _detail('Điểm đón', ride.pickupAddress),
          _detail('Điểm đến', ride.destinationAddress),
          _detail('Trạng thái', ride.status),
          _detail('Quãng đường', '${ride.distance.toStringAsFixed(1)} km'),
          _detail('Giá ước tính', _money(ride.estimatedPrice)),
          _detail('Giá cuối', _money(ride.finalPrice)),
          const Divider(),
          _detail('Yêu cầu lúc', _dateTime(ride.requestedAt)),
          if (ride.acceptedAt != null)
            _detail('Nhận lúc', _dateTime(ride.acceptedAt!)),
          if (ride.completedAt != null)
            _detail('Hoàn tất lúc', _dateTime(ride.completedAt!)),
          if (ride.cancelledAt != null)
            _detail('Hủy lúc', _dateTime(ride.cancelledAt!)),
          if (ride.cancellationReason != null)
            _detail('Lý do hủy', ride.cancellationReason!),
          if (ride.rating != null)
            _detail(
              'Đánh giá',
              '${ride.rating!.rating.toStringAsFixed(1)} - ${ride.rating!.comment ?? ''}',
            ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  final int page;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final ValueChanged<int> onPageChanged;

  const _Pagination({
    required this.page,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Trang trước',
            onPressed: hasPreviousPage ? () => onPageChanged(page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('Trang $page/$totalPages'),
          IconButton(
            tooltip: 'Trang sau',
            onPressed: hasNextPage ? () => onPageChanged(page + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return Colors.green;
    case 'cancelled':
      return Colors.red;
    case 'accepted':
      return Colors.blue;
    default:
      return Colors.orange;
  }
}

String _date(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}

String _dateTime(DateTime value) {
  return '${_date(value)} ${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

String _money(double value) {
  final rounded = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < rounded.length; i++) {
    final fromEnd = rounded.length - i;
    buffer.write(rounded[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write('.');
  }
  return '$bufferđ';
}
