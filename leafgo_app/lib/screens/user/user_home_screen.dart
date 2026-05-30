import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:leafgo_app/blocs/auth/auth_bloc.dart';
import 'package:leafgo_app/blocs/booking/booking_bloc.dart';
import 'package:leafgo_app/core/utils/avatar_utils.dart';
import 'package:leafgo_app/models/booking/ride_model.dart';
import '../chat_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  bool _isPickupActive = true;
  int _lastHandledResetCounter = 0;

  void _swapLocations() {
    final state = context.read<BookingBloc>().state;
    final pickup = state.pickupLocation;
    final dropoff = state.dropoffLocation;

    if (pickup != null && dropoff != null) {
      context.read<BookingBloc>().add(BookingSelectLocation(dropoff, true));
      context.read<BookingBloc>().add(BookingSelectLocation(pickup, false));
    } else if (pickup != null) {
      context.read<BookingBloc>().add(BookingSelectLocation(pickup, false));
      context.read<BookingBloc>().add(BookingReset());
    } else if (dropoff != null) {
      context.read<BookingBloc>().add(BookingSelectLocation(dropoff, true));
      context.read<BookingBloc>().add(BookingReset());
    }
  }

  void _openRideChat(RideModel ride) {
    final authState = context.read<AuthBloc>().state;
    final authUserId = authState is AuthAuthenticated ? authState.user.id : '';
    final rideUserId = ride.user?.id ?? '';
    final currentUserId = rideUserId.isNotEmpty ? rideUserId : authUserId;

    if (currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin người dùng')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          rideId: ride.id,
          currentUserId: currentUserId,
          recipientName: ride.driver?.fullName ?? 'Tài xế',
        ),
      ),
    );
  }

  /// Map vehicle type name to an icon. Extend as needed.
  IconData _vehicleIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('xe máy') || n.contains('motor') || n.contains('bike')) {
      return Icons.two_wheeler;
    } else if (n.contains('tải') || n.contains('truck')) {
      return Icons.local_shipping;
    } else if (n.contains('7 chỗ') || n.contains('suv') || n.contains('van')) {
      return Icons.airport_shuttle;
    } else if (n.contains('4 chỗ') ||
        n.contains('sedan') ||
        n.contains('car') ||
        n.contains('ô tô')) {
      return Icons.directions_car;
    } else if (n.contains('điện') || n.contains('electric')) {
      return Icons.electric_car;
    } else {
      return Icons.directions_car_filled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF10B981);

    return BlocListener<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error!)));
        }

        if (state.resetCounter != _lastHandledResetCounter) {
          _lastHandledResetCounter = state.resetCounter;
          _pickupController.clear();
          _destController.clear();
        }

        if (state.pickupLocation != null &&
            _pickupController.text != state.pickupLocation!.fullAddress) {
          _pickupController.text = state.pickupLocation!.fullAddress;
        }

        if (state.dropoffLocation != null &&
            _destController.text != state.dropoffLocation!.fullAddress) {
          _destController.text = state.dropoffLocation!.fullAddress;
        }

        if (state.pickupLocation != null &&
            state.pickupLocation!.hasValidCoordinates) {
          _mapController.move(state.pickupLocation!.toLatLng, 15);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: Stack(
          children: [
            // 1. Full Screen Map
            Positioned.fill(child: _buildMap()),

            // 2. Leaf Go Badge
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.eco,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Leaf Go',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Zoom Controls
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8),
                  ],
                ),
                child: Column(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.add,
                        color: Colors.black87,
                        size: 20,
                      ),
                      onPressed: () => _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom + 1,
                      ),
                      constraints: const BoxConstraints.tightFor(
                        width: 38,
                        height: 38,
                      ),
                    ),
                    const Divider(height: 1),
                    IconButton(
                      icon: const Icon(
                        Icons.remove,
                        color: Colors.black87,
                        size: 20,
                      ),
                      onPressed: () => _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom - 1,
                      ),
                      constraints: const BoxConstraints.tightFor(
                        width: 38,
                        height: 38,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Bottom Booking Card
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 15,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: BlocBuilder<BookingBloc, BookingState>(
                    builder: (context, state) {
                      if (state.currentRide != null) {
                        return _buildMobileActiveRidePanel(state, primaryColor);
                      }
                      return _buildMobileBookingFormPanel(state, primaryColor);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileBookingFormPanel(BookingState state, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'Đặt chuyến xe',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // ── 1. Pickup Location ──────────────────────────────────────
          Row(
            children: const [
              Icon(Icons.fiber_manual_record, color: Colors.green, size: 12),
              SizedBox(width: 6),
              Text(
                'Điểm đón',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildLocationInput(
            controller: _pickupController,
            hint: 'Nhập điểm đón',
            iconColor: Colors.green,
            isPickup: true,
          ),
          if (state.searchResults.isNotEmpty && _isPickupActive)
            _buildInlineSuggestions(state),

          // Swap button
          const SizedBox(height: 6),
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.swap_vert,
                  color: Color(0xFF10B981),
                  size: 18,
                ),
                onPressed: _swapLocations,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // ── 2. Destination Location ─────────────────────────────────
          Row(
            children: const [
              Icon(Icons.navigation, color: Colors.red, size: 12),
              SizedBox(width: 6),
              Text(
                'Điểm đến',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildLocationInput(
            controller: _destController,
            hint: 'Nhập điểm đến',
            iconColor: Colors.red,
            isPickup: false,
          ),
          if (state.searchResults.isNotEmpty && !_isPickupActive)
            _buildInlineSuggestions(state),

          const SizedBox(height: 16),

          // ── 3. Vehicle Type Selection (visual cards) ────────────────
          if (state.vehicleTypes.isNotEmpty) ...[
            const Text(
              'Loại phương tiện',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.vehicleTypes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final type = state.vehicleTypes[index];
                  final isSelected = state.selectedVehicleTypeId == type.id;
                  return GestureDetector(
                    onTap: () => context.read<BookingBloc>().add(
                      BookingSelectVehicleType(type.id),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 80,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE6F7F0)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF10B981)
                              : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withOpacity(0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF10B981)
                                  : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _vehicleIcon(type.name),
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            type.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? const Color(0xFF10B981)
                                  : Colors.black54,
                            ),
                          ),
                          Text(
                            '${type.pricePerKm.toInt()}đ/km',
                            style: TextStyle(
                              fontSize: 9,
                              color: isSelected
                                  ? const Color(0xFF10B981)
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── 4. Confirm / Cancel ─────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        (state.pickupLocation != null &&
                            state.dropoffLocation != null)
                        ? const Color(0xFFE6F7F0)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          (state.pickupLocation != null &&
                              state.dropoffLocation != null)
                          ? const Color(0xFF10B981).withOpacity(0.3)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color:
                              (state.pickupLocation != null &&
                                  state.dropoffLocation != null)
                              ? const Color(0xFF10B981)
                              : Colors.grey,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Đã xác nhận',
                          style: TextStyle(
                            color:
                                (state.pickupLocation != null &&
                                    state.dropoffLocation != null)
                                ? const Color(0xFF10B981)
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () =>
                    context.read<BookingBloc>().add(BookingReset()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  side: BorderSide(color: Colors.grey.shade300),
                  minimumSize: const Size(50, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text(
                  'Hủy',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 5. Summary Card ─────────────────────────────────────────
          if (state.priceData != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    'Khoảng cách',
                    '${state.priceData!['distance']} km',
                    isBold: false,
                  ),
                  const Divider(height: 12),
                  _buildSummaryRow(
                    'Thời gian',
                    '${state.priceData!['estimatedDuration']} phút',
                    isBold: false,
                  ),
                  const Divider(height: 12),
                  _buildSummaryRow(
                    'Giá dự kiến',
                    NumberFormat.simpleCurrency(
                      locale: 'vi_VN',
                      decimalDigits: 0,
                    ).format(state.priceData!['estimatedPrice']),
                    isBold: true,
                    valueColor: const Color(0xFF10B981),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── 6. Book Button ──────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  (state.pickupLocation != null &&
                      state.dropoffLocation != null &&
                      state.selectedVehicleTypeId != null)
                  ? () => context.read<BookingBloc>().add(BookingRequestRide())
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                disabledBackgroundColor: Colors.grey.shade200,
                disabledForegroundColor: Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Đặt xe ngay',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileActiveRidePanel(BookingState state, Color primaryColor) {
    final ride = state.currentRide!;
    if (ride.status == 'Completed') {
      return _ActiveRideRatingPanel(ride: ride, primaryColor: primaryColor);
    }
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Hành trình hiện tại',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Status Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F7F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                ride.status == 'Completed'
                    ? const Icon(
                        Icons.check_circle,
                        color: Color(0xFF10B981),
                        size: 20,
                      )
                    : ride.status == 'Cancelled'
                    ? const Icon(Icons.cancel, color: Colors.red, size: 20)
                    : const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF10B981),
                        ),
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusText(ride.status),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: primaryColor,
                        ),
                      ),
                      Text(
                        ride.driver == null
                            ? 'Đang tìm tài xế gần bạn...'
                            : 'Tài xế đang đến điểm đón',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSummaryRow('Điểm đón', ride.pickupAddress, isBold: false),
          const SizedBox(height: 6),
          _buildSummaryRow('Điểm đến', ride.destinationAddress, isBold: false),
          const SizedBox(height: 6),
          _buildSummaryRow(
            'Số tiền',
            NumberFormat.simpleCurrency(
              locale: 'vi_VN',
              decimalDigits: 0,
            ).format(ride.estimatedPrice),
            isBold: true,
            valueColor: primaryColor,
          ),

          if (ride.driver != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                buildAvatarCircle(ride.driver!.avatar, radius: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.driver!.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 12,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              ride.driver!.phoneNumber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.confirmation_number_outlined,
                            size: 12,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              ride.driver!.vehicle?.licensePlate ?? 'N/A',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chat,
                          color: Color(0xFF10B981),
                          size: 16,
                        ),
                        onPressed: () => _openRideChat(ride),
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.phone,
                          color: Color(0xFF10B981),
                          size: 16,
                        ),
                        onPressed: () {},
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openRideChat(ride),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text(
                  'Nhắn tin với tài xế',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(42),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          if (ride.status == 'Pending')
            OutlinedButton(
              onPressed: () => context.read<BookingBloc>().add(
                BookingCancelRide('Người dùng hủy'),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.redAccent),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Hủy chuyến xe',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    required bool isBold,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 14 : 12,
              color: valueColor ?? Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInlineSuggestions(BookingState state) {
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 6),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: state.searchResults.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final loc = state.searchResults[index];
          return ListTile(
            dense: true,
            leading: const Icon(
              Icons.place_outlined,
              color: Color(0xFF10B981),
              size: 16,
            ),
            title: Text(
              loc.fullAddress,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
            onTap: () {
              FocusScope.of(context).unfocus();
              context.read<BookingBloc>().add(
                BookingSelectLocation(loc, _isPickupActive),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMap() {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        final routeCoordinates = state.routeCoordinates
            .where(_isValidLatLng)
            .toList();
        return FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(10.8458, 106.7945),
            initialZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.leafgo.app',
            ),
            if (routeCoordinates.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routeCoordinates,
                    color: const Color(0xFF10B981),
                    strokeWidth: 5,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (state.pickupLocation != null &&
                    state.pickupLocation!.hasValidCoordinates)
                  Marker(
                    point: state.pickupLocation!.toLatLng,
                    width: 36,
                    height: 36,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.green,
                      size: 36,
                    ),
                  ),
                if (state.dropoffLocation != null &&
                    state.dropoffLocation!.hasValidCoordinates)
                  Marker(
                    point: state.dropoffLocation!.toLatLng,
                    width: 36,
                    height: 36,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 36,
                    ),
                  ),
                if (state.driverLocation != null &&
                    _isValidLatLng(state.driverLocation!))
                  Marker(
                    point: state.driverLocation!,
                    width: 36,
                    height: 36,
                    child: const Icon(
                      Icons.directions_car,
                      color: Colors.blue,
                      size: 36,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  bool _isValidLatLng(LatLng point) {
    return point.latitude >= -90 &&
        point.latitude <= 90 &&
        point.longitude >= -180 &&
        point.longitude <= 180;
  }

  Widget _buildLocationInput({
    required TextEditingController controller,
    required String hint,
    required Color iconColor,
    required bool isPickup,
  }) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13),
        onTap: () => setState(() => _isPickupActive = isPickup),
        onChanged: (val) {
          setState(() => _isPickupActive = isPickup);
          context.read<BookingBloc>().add(BookingSearchLocation(val, isPickup));
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.gps_fixed, size: 16, color: Colors.grey),
            onPressed: () => context.read<BookingBloc>().add(
              BookingGetCurrentLocation(isPickup),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Pending':
        return 'Đang tìm xe...';
      case 'Accepted':
        return 'Đã tìm thấy tài xế';
      case 'DriverArriving':
        return 'Tài xế đang đến';
      case 'DriverArrived':
        return 'Tài xế đã đến';
      case 'InProgress':
        return 'Đang di chuyển';
      case 'Completed':
        return 'Hoàn thành';
      case 'Cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }
}

class _ActiveRideRatingPanel extends StatefulWidget {
  final RideModel ride;
  final Color primaryColor;

  const _ActiveRideRatingPanel({
    required this.ride,
    required this.primaryColor,
  });

  @override
  State<_ActiveRideRatingPanel> createState() => _ActiveRideRatingPanelState();
}

class _ActiveRideRatingPanelState extends State<_ActiveRideRatingPanel> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Success icon & text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFE6F7F0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF10B981),
              size: 40,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Chuyến đi đã hoàn thành!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.ride.driver != null
                ? 'Hãy đánh giá dịch vụ của tài xế ${widget.ride.driver!.fullName}'
                : 'Hãy để lại đánh giá của bạn về chuyến đi nhé!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Stars selection
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              final isSelected = starValue <= _rating;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _rating = starValue;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    isSelected
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: isSelected ? Colors.amber : Colors.grey.shade300,
                    size: 42,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Comment Textfield
          TextField(
            controller: _commentController,
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Nhập ý kiến đóng góp của bạn (không bắt buộc)...',
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              contentPadding: const EdgeInsets.all(12),
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
                borderSide: const BorderSide(color: Color(0xFF10B981)),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Skip rating, reset state
                    context.read<BookingBloc>().add(BookingReset());
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Bỏ qua',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.read<BookingBloc>().add(
                      BookingSubmitRating(_rating, _commentController.text),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Gửi đánh giá',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
