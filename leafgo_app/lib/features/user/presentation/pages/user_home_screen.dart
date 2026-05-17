import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:leafgo_app/features/booking/presentation/bloc/booking_bloc.dart';

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

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF10B981);

    return BlocListener<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
        }
        
        // Auto-populate or clear controllers based on BLoC state
        if (state.pickupLocation != null && _pickupController.text != state.pickupLocation!.fullAddress) {
          _pickupController.text = state.pickupLocation!.fullAddress;
        } else if (state.pickupLocation == null && _pickupController.text.isNotEmpty) {
          _pickupController.clear();
        }

        if (state.dropoffLocation != null && _destController.text != state.dropoffLocation!.fullAddress) {
          _destController.text = state.dropoffLocation!.fullAddress;
        } else if (state.dropoffLocation == null && _destController.text.isNotEmpty) {
          _destController.clear();
        }

        if (state.pickupLocation != null) {
          _mapController.move(state.pickupLocation!.toLatLng, 15);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: Stack(
          children: [
            // 1. Full Screen Map in background
            Positioned.fill(
              child: _buildMap(),
            ),

            // 2. Leaf Go Badge Overlay at top
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                      child: const Icon(Icons.eco, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Leaf Go',
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),

            // Zoom Controls overlay
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                child: Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.black87, size: 20),
                      onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
                      constraints: const BoxConstraints.tightFor(width: 38, height: 38),
                    ),
                    const Divider(height: 1),
                    IconButton(
                      icon: const Icon(Icons.remove, color: Colors.black87, size: 20),
                      onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
                      constraints: const BoxConstraints.tightFor(width: 38, height: 38),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Bottom Premium Booking Card Sheet
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -3))],
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

            // 4. Floating Suggestion List above bottom sheet to prevent layout shifting
            _buildFloatingSuggestions(),
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
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
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

          // 1. Vehicle selection dropdown
          const Text(
            'Loại phương tiện',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                value: state.selectedVehicleTypeId,
                decoration: const InputDecoration(border: InputBorder.none),
                hint: const Text('Chọn loại phương tiện', style: TextStyle(fontSize: 13)),
                items: state.vehicleTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type.id,
                    child: Text(
                      '${type.name} - ${type.pricePerKm.toInt()}đ/km',
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    context.read<BookingBloc>().add(BookingSelectVehicleType(val));
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Pickup Location Form
          Row(
            children: [
              const Icon(Icons.fiber_manual_record, color: Colors.green, size: 12),
              const SizedBox(width: 6),
              const Text(
                'Điểm đón',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
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
          
          // 3. Swap Locations Button
          const SizedBox(height: 6),
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: IconButton(
                icon: const Icon(Icons.swap_vert, color: Color(0xFF10B981), size: 18),
                onPressed: _swapLocations,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // 4. Destination Location Form
          Row(
            children: [
              const Icon(Icons.navigation, color: Colors.red, size: 12),
              const SizedBox(width: 6),
              const Text(
                'Điểm đến',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
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
          const SizedBox(height: 12),

          // 5. Confirmation and Cancel actions
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: (state.pickupLocation != null && state.dropoffLocation != null)
                        ? const Color(0xFFE6F7F0)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (state.pickupLocation != null && state.dropoffLocation != null)
                          ? primaryColor.withOpacity(0.3)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: (state.pickupLocation != null && state.dropoffLocation != null)
                              ? primaryColor
                              : Colors.grey,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Đã xác nhận',
                          style: TextStyle(
                            color: (state.pickupLocation != null && state.dropoffLocation != null)
                                ? primaryColor
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
                onPressed: () {
                  context.read<BookingBloc>().add(BookingReset());
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  side: BorderSide(color: Colors.grey.shade300),
                  minimumSize: const Size(50, 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 6. Summary Card
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
                  _buildSummaryRow('Khoảng cách', '${state.priceData!['distance']} km', isBold: false),
                  const Divider(height: 12),
                  _buildSummaryRow('Thời gian', '${state.priceData!['estimatedDuration']} phút', isBold: false),
                  const Divider(height: 12),
                  _buildSummaryRow(
                    'Giá dự kiến',
                    '${NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0).format(state.priceData!['estimatedPrice'])}',
                    isBold: true,
                    valueColor: primaryColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 7. Book Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (state.pickupLocation != null && state.dropoffLocation != null && state.selectedVehicleTypeId != null)
                  ? () => context.read<BookingBloc>().add(BookingRequestRide())
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                disabledBackgroundColor: Colors.grey.shade200,
                disabledForegroundColor: Colors.grey.shade400,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Đặt xe ngay', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileActiveRidePanel(BookingState state, Color primaryColor) {
    final ride = state.currentRide!;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'Hành trình hiện tại',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
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
                const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusText(ride.status),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor),
                      ),
                      Text(
                        ride.driver == null ? 'Đang tìm tài xế gần bạn...' : 'Tài xế đang đến điểm đón',
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Trip Info
          _buildSummaryRow('Điểm đón', ride.pickupAddress, isBold: false),
          const SizedBox(height: 6),
          _buildSummaryRow('Điểm đến', ride.destinationAddress, isBold: false),
          const SizedBox(height: 6),
          _buildSummaryRow(
            'Số tiền', 
            '${NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0).format(ride.estimatedPrice)}', 
            isBold: true,
            valueColor: primaryColor,
          ),
          
          if (ride.driver != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFE6F7F0),
                  child: const Icon(Icons.person, color: Color(0xFF10B981), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ride.driver!.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(
                        ride.driver!.vehicle?.licensePlate ?? 'N/A', 
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(color: const Color(0xFFE6F7F0), borderRadius: BorderRadius.circular(10)),
                  child: IconButton(
                    icon: const Icon(Icons.phone, color: Color(0xFF10B981), size: 16),
                    onPressed: () {},
                    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          
          if (ride.status == 'Pending')
            OutlinedButton(
              onPressed: () => context.read<BookingBloc>().add(BookingCancelRide('Người dùng hủy')),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.redAccent),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Hủy chuyến xe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {required bool isBold, Color? valueColor}) {
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

  Widget _buildFloatingSuggestions() {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        if (state.searchResults.isEmpty) return const SizedBox.shrink();
        
        // Float suggestion above the bottom sheet beautifully
        return Positioned(
          bottom: 300, 
          left: 16,
          right: 16,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 3))],
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
                  leading: const Icon(Icons.place_outlined, color: Colors.grey, size: 16),
                  title: Text(
                    loc.fullAddress, 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    context.read<BookingBloc>().add(BookingSelectLocation(loc, _isPickupActive));
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMap() {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        return FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(10.8458, 106.7945), // Lê Văn Việt HCMC
            initialZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.leafgo.app',
            ),
            if (state.routeCoordinates.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: state.routeCoordinates,
                    color: const Color(0xFF10B981),
                    strokeWidth: 5,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (state.pickupLocation != null)
                  Marker(
                    point: state.pickupLocation!.toLatLng,
                    width: 36, height: 36,
                    child: const Icon(Icons.location_on, color: Colors.green, size: 36),
                  ),
                if (state.dropoffLocation != null)
                  Marker(
                    point: state.dropoffLocation!.toLatLng,
                    width: 36, height: 36,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                  ),
                if (state.driverLocation != null)
                  Marker(
                    point: state.driverLocation!,
                    width: 36, height: 36,
                    child: const Icon(Icons.directions_car, color: Colors.blue, size: 36),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildLocationInput({required TextEditingController controller, required String hint, required Color iconColor, required bool isPickup}) {
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
        onTap: () => _isPickupActive = isPickup,
        onChanged: (val) {
          _isPickupActive = isPickup;
          context.read<BookingBloc>().add(BookingSearchLocation(val, isPickup));
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
            ),
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.gps_fixed, size: 16, color: Colors.grey),
            onPressed: () => context.read<BookingBloc>().add(BookingGetCurrentLocation(isPickup)),
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
      case 'Pending': return 'Đang tìm xe...';
      case 'Accepted': return 'Đã tìm thấy tài xế';
      case 'DriverArriving': return 'Tài xế đang đến';
      case 'DriverArrived': return 'Tài xế đã đến';
      case 'InProgress': return 'Đang di chuyển';
      case 'Completed': return 'Hoàn thành';
      case 'Cancelled': return 'Đã hủy';
      default: return status;
    }
  }
}
