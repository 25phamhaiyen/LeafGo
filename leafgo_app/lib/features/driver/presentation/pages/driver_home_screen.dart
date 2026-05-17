import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:leafgo_app/features/booking/data/models/booking_models.dart';
import 'package:leafgo_app/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:leafgo_app/features/driver/presentation/pages/driver_vehicle_screen.dart';
import 'package:leafgo_app/core/services/location_service.dart';
import '../../../../injection_container.dart';
import '../bloc/driver_bloc.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  bool _isFetchingRoute = false;

  @override
  void initState() {
    super.initState();
    context.read<DriverBloc>().add(DriverCheckActiveRide());
    context.read<DriverBloc>().add(DriverLoadProfile());
  }

  Future<void> _fetchRoute(RideModel ride) async {
    if (_isFetchingRoute) return;
    setState(() => _isFetchingRoute = true);
    try {
      final locService = sl<LocationService>();
      final pickup = LocationModel(fullAddress: ride.pickupAddress, lat: ride.pickupLatitude, lng: ride.pickupLongitude);
      final dropoff = LocationModel(fullAddress: ride.destinationAddress, lat: ride.destinationLatitude, lng: ride.destinationLongitude);
      final points = await locService.getRoute(pickup, dropoff);
      setState(() => _routePoints = points);
    } catch (_) {}
    setState(() => _isFetchingRoute = false);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF10B981);

    return BlocConsumer<DriverBloc, DriverState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), backgroundColor: Colors.red.shade700),
          );
        }
        if (state.currentRide != null && _routePoints.isEmpty && !_isFetchingRoute) {
          _fetchRoute(state.currentRide!);
          _mapController.move(LatLng(state.currentRide!.pickupLatitude, state.currentRide!.pickupLongitude), 14);
        }
        if (state.currentRide == null && _routePoints.isNotEmpty) {
          setState(() => _routePoints = []);
        }
      },
      builder: (context, state) {
        LatLng centerCoords = const LatLng(10.8458, 106.7945); // Default UTC
        if (state.currentRide != null) {
          centerCoords = LatLng(state.currentRide!.pickupLatitude, state.currentRide!.pickupLongitude);
        }

        return Scaffold(
          body: Stack(
            children: [
              // 1. Full Screen Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: centerCoords,
                  initialZoom: 14.5,
                  minZoom: 5,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.example.leafgo_app',
                  ),
                  if (_routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 5,
                          color: primaryColor,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      if (state.currentRide != null) ...[
                        Marker(
                          point: LatLng(state.currentRide!.pickupLatitude, state.currentRide!.pickupLongitude),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: Colors.blue, size: 36),
                        ),
                        Marker(
                          point: LatLng(state.currentRide!.destinationLatitude, state.currentRide!.destinationLongitude),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.flag, color: Colors.red, size: 36),
                        ),
                      ] else ...[
                        Marker(
                          point: centerCoords,
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: primaryColor, width: 2),
                            ),
                            child: const Icon(Icons.navigation, color: primaryColor, size: 24),
                          ),
                        ),
                      ]
                    ],
                  ),
                ],
              ),

              // 2. Leaf Go Header Overlay
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.eco, color: primaryColor, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Leaf Go Tài Xế',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Zoom Controls
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                right: 16,
                child: Column(
                  children: [
                    _circleButton(
                      icon: Icons.add,
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(_mapController.camera.center, currentZoom + 1);
                      },
                    ),
                    const SizedBox(height: 8),
                    _circleButton(
                      icon: Icons.remove,
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(_mapController.camera.center, currentZoom - 1);
                      },
                    ),
                  ],
                ),
              ),

              // 4. Position Pin Lock
              Positioned(
                bottom: state.currentRide != null 
                    ? 320 
                    : (state.isOnline ? 240 : 160),
                right: 16,
                child: _circleButton(
                  icon: Icons.my_location,
                  onPressed: () {
                    _mapController.move(centerCoords, 15);
                  },
                ),
              ),

              // 5. Driver Control Panel
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _buildPanelContent(state, primaryColor),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.grey.shade700, size: 20),
        onPressed: onPressed,
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildPanelContent(DriverState state, Color primaryColor) {
    if (state.currentRide != null) {
      return _buildActiveRidePanel(state.currentRide!, primaryColor, state.isLoading);
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.isOnline ? 'Bạn đang Trực Tuyến' : 'Bạn đang Ngoại Tuyến',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Text(
                    state.isOnline ? 'Sẵn sàng nhận khách...' : 'Bật trực tuyến để nhận chuyến xe',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Switch(
                value: state.isOnline,
                activeColor: primaryColor,
                onChanged: (val) {
                  if (state.vehicle == null) {
                    _showRegisterVehicleDialog(context);
                  } else {
                    context.read<DriverBloc>().add(DriverToggleOnline());
                  }
                },
              ),
            ],
          ),

          if (state.isOnline) ...[
            const Divider(height: 24),
            const Text(
              'Yêu cầu đặt xe gần đây',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            state.pendingRides.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                        ),
                        const SizedBox(height: 12),
                        Text('Đang tìm chuyến xe xung quanh bạn...', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  )
                : Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: state.pendingRides.length,
                      itemBuilder: (ctx, idx) {
                        final item = state.pendingRides[idx];
                        return _buildPendingRideItem(item, primaryColor, state.isLoading);
                      },
                    ),
                  ),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingRideItem(dynamic item, Color primaryColor, bool isLoading) {
    final String pickup = item['pickupAddress'] ?? '';
    final String dest = item['destinationAddress'] ?? '';
    final double price = (item['estimatedPrice'] ?? 0.0).toDouble();
    final double dist = (item['distance'] ?? 0.0).toDouble();
    final double distFromDriver = (item['distanceFromDriver'] ?? 0.0).toDouble();
    final String clientName = item['user']?['fullName'] ?? 'Khách hàng';
    final String rideId = item['id'];
    final String version = item['version'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(
                '${NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0).format(price)}',
                style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.blue, size: 14),
              const SizedBox(width: 6),
              Expanded(child: Text(pickup, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.black54))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.flag, color: Colors.red, size: 14),
              const SizedBox(width: 6),
              Expanded(child: Text(dest, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.black54))),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QĐ: ${dist.toStringAsFixed(1)} km • Cách bạn ${distFromDriver.toStringAsFixed(1)} km',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        context.read<DriverBloc>().add(DriverAcceptRide(rideId, version));
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(90, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('Nhận chuyến', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRidePanel(RideModel ride, Color primaryColor, bool isLoading) {
    String actionText = 'Đã đến điểm đón';
    String nextStatus = 'DriverArrived';
    String descText = 'Hãy di chuyển đến vị trí đón hành khách.';

    if (ride.status == 'Accepted') {
      actionText = 'Tôi đã đến điểm đón';
      nextStatus = 'DriverArrived';
      descText = 'Hãy di chuyển đến vị trí đón hành khách.';
    } else if (ride.status == 'DriverArrived') {
      actionText = 'Bắt đầu hành trình';
      nextStatus = 'InProgress';
      descText = 'Hành khách đã lên xe, bắt đầu đưa khách tới điểm đến.';
    } else if (ride.status == 'InProgress') {
      actionText = 'Hoàn thành chuyến đi';
      nextStatus = 'Completed';
      descText = 'Đang di chuyển tới điểm đến: ${ride.destinationAddress}';
    }

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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('HÀNH TRÌNH HIỆN TẠI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  _getStatusText(ride.status),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(descText, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
          const Divider(height: 20),

          _activeSummaryRow('Điểm đón', ride.pickupAddress, Colors.blue),
          const SizedBox(height: 8),
          _activeSummaryRow('Điểm đến', ride.destinationAddress, Colors.red),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Số tiền dự kiến:', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                '${NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0).format(ride.estimatedPrice)}',
                style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 16),
              ),
            ],
          ),
          const Divider(height: 24),

          ElevatedButton(
            onPressed: isLoading
                ? null
                : () {
                    context.read<DriverBloc>().add(
                          DriverUpdateRideStatus(
                            nextStatus,
                            finalPrice: nextStatus == 'Completed' ? ride.estimatedPrice : 0.0,
                          ),
                        );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(actionText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _activeSummaryRow(String label, String value, Color markerColor) {
    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: markerColor),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                TextSpan(text: value, style: const TextStyle(color: Colors.black87, fontSize: 11)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Accepted':
        return 'Đang đi đón khách';
      case 'DriverArrived':
        return 'Đã tới điểm đón';
      case 'InProgress':
        return 'Đang vận chuyển';
      default:
        return status;
    }
  }

  void _showRegisterVehicleDialog(BuildContext context) {
    const primaryColor = Color(0xFF10B981);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Row(
          children: const [
            Icon(Icons.directions_car, color: primaryColor, size: 28),
            SizedBox(width: 12),
            Text(
              'Thông tin phương tiện',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vui lòng cập nhật đầy đủ thông tin xe trước khi bắt đầu nhận chuyến.',
                      style: TextStyle(fontSize: 12, color: Colors.amber, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bạn cần bổ sung thông tin như loại xe, biển số, hãng xe, màu xe để khách hàng có thể nhận biết.',
              style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Hủy', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              final driverBloc = context.read<DriverBloc>();
              final bookingBloc = context.read<BookingBloc>();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => MultiBlocProvider(
                    providers: [
                      BlocProvider.value(value: driverBloc),
                      BlocProvider.value(value: bookingBloc),
                    ],
                    child: const DriverVehicleScreen(),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Cập nhật ngay', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
