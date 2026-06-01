import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:leafgo_app/blocs/booking/booking_bloc.dart';
import 'package:leafgo_app/models/booking/location_model.dart';
import 'package:leafgo_app/models/booking/ride_model.dart';
import '../chat_screen.dart';
import 'package:leafgo_app/screens/driver/driver_vehicle_screen.dart';
import 'package:leafgo_app/core/services/location_service.dart';
import '../../core/utils/avatar_utils.dart';
import '../../injection_container.dart';
import '../../blocs/driver/driver_bloc.dart';

const _green = Color(0xFF10B981);
const _greenDark = Color(0xFF065F46);
const _greenLight = Color(0xFFD1FAE5);
const _surface = Color(0xFFF8FAFC);
const _border = Color(0xFFE2E8F0);

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  bool _isFetchingRoute = false;
  final Set<String> _dismissedRides = {};

  late AnimationController _panelAnimController;
  late Animation<double> _panelAnim;

  @override
  void initState() {
    super.initState();
    _panelAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _panelAnim = CurvedAnimation(
      parent: _panelAnimController,
      curve: Curves.easeOutCubic,
    );
    _panelAnimController.forward();

    context.read<DriverBloc>().add(DriverCheckActiveRide());
    context.read<DriverBloc>().add(DriverLoadProfile());
  }

  @override
  void dispose() {
    _panelAnimController.dispose();
    super.dispose();
  }

  Future<void> _fetchRoute(RideModel ride) async {
    if (_isFetchingRoute) return;
    setState(() => _isFetchingRoute = true);
    try {
      final locService = sl<LocationService>();
      final pickup = LocationModel(
        fullAddress: ride.pickupAddress,
        lat: ride.pickupLatitude,
        lng: ride.pickupLongitude,
      );
      final dropoff = LocationModel(
        fullAddress: ride.destinationAddress,
        lat: ride.destinationLatitude,
        lng: ride.destinationLongitude,
      );
      final points = await locService.getRoute(pickup, dropoff);
      setState(() => _routePoints = points);
    } catch (_) {}
    setState(() => _isFetchingRoute = false);
  }

  bool _isValidLatLng(LatLng point) =>
      point.latitude >= -90 &&
      point.latitude <= 90 &&
      point.longitude >= -180 &&
      point.longitude <= 180;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: BlocConsumer<DriverBloc, DriverState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: const Color(0xFFDC2626),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
          if (state.currentRide != null &&
              _routePoints.isEmpty &&
              !_isFetchingRoute) {
            _fetchRoute(state.currentRide!);
            final pp = LatLng(
              state.currentRide!.pickupLatitude,
              state.currentRide!.pickupLongitude,
            );
            if (_isValidLatLng(pp)) _mapController.move(pp, 14);
          }
          if (state.currentRide == null && _routePoints.isNotEmpty) {
            setState(() => _routePoints = []);
          }
        },
        builder: (context, state) {
          final routePoints = _routePoints.where(_isValidLatLng).toList();
          LatLng center =
              state.currentLocation ?? const LatLng(10.8458, 106.7945);
          if (state.currentRide != null) {
            final pp = LatLng(
              state.currentRide!.pickupLatitude,
              state.currentRide!.pickupLongitude,
            );
            if (_isValidLatLng(pp)) center = pp;
          }

          final pendingVisible = (state.pendingRides as List)
              .where((r) => !_dismissedRides.contains(r['id']))
              .toList();

          return Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                // ── MAP ──────────────────────────────────────
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 14.5,
                    minZoom: 5,
                    maxZoom: 18,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.leafgo.app',
                    ),
                    if (routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePoints,
                            strokeWidth: 5,
                            color: _green,
                            strokeCap: StrokeCap.round,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        if (state.currentRide != null &&
                            _isValidLatLng(
                              LatLng(
                                state.currentRide!.pickupLatitude,
                                state.currentRide!.pickupLongitude,
                              ),
                            )) ...[
                          Marker(
                            point: LatLng(
                              state.currentRide!.pickupLatitude,
                              state.currentRide!.pickupLongitude,
                            ),
                            width: 40,
                            height: 40,
                            child: _mapPin(Colors.blue),
                          ),
                          Marker(
                            point: LatLng(
                              state.currentRide!.destinationLatitude,
                              state.currentRide!.destinationLongitude,
                            ),
                            width: 40,
                            height: 40,
                            child: _mapPin(const Color(0xFFEF4444)),
                          ),
                        ] else ...[
                          Marker(
                            point: center,
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _green.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: _green, width: 2),
                              ),
                              child: const Icon(
                                Icons.navigation,
                                color: _green,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                // ── TOP BAR ──────────────────────────────────
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 14,
                  right: 14,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Brand pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: state.isOnline
                              ? const Color(0xFFECFDF5).withOpacity(0.95)
                              : Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: state.isOnline
                                    ? _green
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              state.isOnline
                                  ? 'Đang hoạt động'
                                  : 'Leaf Go Tài Xế',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: state.isOnline
                                    ? _greenDark
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Zoom controls
                      Column(
                        children: [
                          _mapControlBtn(
                            icon: Icons.add,
                            onTap: () {
                              _mapController.move(
                                _mapController.camera.center,
                                _mapController.camera.zoom + 1,
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          _mapControlBtn(
                            icon: Icons.remove,
                            onTap: () {
                              _mapController.move(
                                _mapController.camera.center,
                                _mapController.camera.zoom - 1,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── MY LOCATION BTN ──────────────────────────
                Positioned(
                  bottom: _bottomOffset(state) + 16,
                  right: 14,
                  child: _mapControlBtn(
                    icon: Icons.my_location_rounded,
                    onTap: () => _mapController.move(center, 15),
                  ),
                ),

                // ── BOTTOM PANEL ──────────────────────────────
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(_panelAnim),
                    child: FadeTransition(
                      opacity: _panelAnim,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 24,
                              offset: const Offset(0, -6),
                            ),
                          ],
                        ),
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                          child: _buildPanel(state, pendingVisible),
                        ),
                      ),
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

  double _bottomOffset(DriverState state) {
    if (state.currentRide != null) return 440;
    if (state.isOnline) return 280;
    return 170;
  }

  // ── MAP HELPERS ─────────────────────────────────────────────────────

  Widget _mapPin(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        Container(
          width: 2,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  Widget _mapControlBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
      ),
    );
  }

  // ── PANEL ROUTING ────────────────────────────────────────────────────

  Widget _buildPanel(DriverState state, List pendingVisible) {
    if (state.currentRide != null) {
      return _ActiveRidePanel(
        ride: state.currentRide!,
        isLoading: state.isLoading,
        onUpdateStatus: (status, price) {
          context.read<DriverBloc>().add(
            DriverUpdateRideStatus(status, finalPrice: price),
          );
        },
      );
    }
    return _IdlePanel(
      state: state,
      pendingRides: pendingVisible,
      dismissedRides: _dismissedRides,
      onDismiss: (id) => setState(() => _dismissedRides.add(id)),
      onAccept: (id, version) {
        context.read<DriverBloc>().add(DriverAcceptRide(id, version));
      },
      onToggleOnline: () {
        if (state.vehicle == null) {
          _showVehicleDialog(context);
        } else {
          context.read<DriverBloc>().add(DriverToggleOnline());
        }
      },
    );
  }

  // ── VEHICLE DIALOG ────────────────────────────────────────────────────

  void _showVehicleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _greenLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: _green,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Thông tin phương tiện',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFDE68A),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFF59E0B),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cập nhật thông tin xe để bắt đầu nhận chuyến.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bạn cần bổ sung loại xe, biển số, hãng xe, màu xe để khách hàng nhận biết.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: _border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        final driverBloc = context.read<DriverBloc>();
                        final bookingBloc = context.read<BookingBloc>();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => MultiBlocProvider(
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
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cập nhật ngay',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// IDLE PANEL (Offline / Online waiting)
// ════════════════════════════════════════════════════════════════════════════

class _IdlePanel extends StatelessWidget {
  final DriverState state;
  final List pendingRides;
  final Set<String> dismissedRides;
  final void Function(String id) onDismiss;
  final void Function(String id, String version) onAccept;
  final VoidCallback onToggleOnline;

  const _IdlePanel({
    required this.state,
    required this.pendingRides,
    required this.dismissedRides,
    required this.onDismiss,
    required this.onAccept,
    required this.onToggleOnline,
  });

  @override
  Widget build(BuildContext context) {
    final todayRides = state.stats?.todayRides ?? 0;
    final averageRating = state.stats?.averageRating ?? 5.0;
    final todayEarnings = state.stats?.todayEarnings ?? 0.0;
    final formattedEarnings = NumberFormat.simpleCurrency(
      locale: 'vi_VN',
      decimalDigits: 0,
    ).format(todayEarnings);

    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Online toggle row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.isOnline
                          ? 'Bạn đang Trực Tuyến'
                          : 'Bạn đang Ngoại Tuyến',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.isOnline
                          ? 'Sẵn sàng nhận chuyến...'
                          : 'Bật trực tuyến để nhận chuyến xe',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: state.isOnline,
                activeColor: _green,
                onChanged: (_) => onToggleOnline(),
              ),
            ],
          ),

          // Stats row (always visible)
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(label: 'Hôm nay', value: '$todayRides chuyến'),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Đánh giá',
                value: '${averageRating.toStringAsFixed(1)} ★',
              ),
              const SizedBox(width: 8),
              _StatChip(label: 'Doanh thu', value: formattedEarnings),
            ],
          ),

          // Pending rides
          if (state.isOnline) ...[
            const SizedBox(height: 16),
            Row(
              children: const [
                Text(
                  'YÊU CẦU GẦN ĐÂY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (pendingRides.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _green.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Đang tìm chuyến xung quanh bạn...',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: pendingRides.length,
                  itemBuilder: (ctx, i) {
                    final item = pendingRides[i];
                    return _PendingRideCard(
                      data: item,
                      isLoading: state.isLoading,
                      onAccept: () =>
                          onAccept(item['id'], item['version'] ?? ''),
                      onDismiss: () => onDismiss(item['id']),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border, width: 0.5),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// PENDING RIDE CARD
// ────────────────────────────────────────────────────────────────────────────

class _PendingRideCard extends StatefulWidget {
  final dynamic data;
  final bool isLoading;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  const _PendingRideCard({
    required this.data,
    required this.isLoading,
    required this.onAccept,
    required this.onDismiss,
  });

  @override
  State<_PendingRideCard> createState() => _PendingRideCardState();
}

class _PendingRideCardState extends State<_PendingRideCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final pickup = data['pickupAddress'] ?? '';
    final dest = data['destinationAddress'] ?? '';
    final price = (data['estimatedPrice'] ?? 0.0).toDouble();
    final dist = (data['distance'] ?? 0.0).toDouble();
    final distFromDriver = (data['distanceFromDriver'] ?? 0.0).toDouble();
    final clientName = data['user']?['fullName'] ?? 'Khách hàng';
    final initials = clientName.length >= 2
        ? clientName.substring(0, 2).toUpperCase()
        : clientName.toUpperCase();
    final rating = (data['user']?['rating'] ?? 5.0).toDouble();
    final totalRides = data['user']?['totalRides'] ?? 0;
    final formattedPrice = NumberFormat.simpleCurrency(
      locale: 'vi_VN',
      decimalDigits: 0,
    ).format(price);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F5E9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Green left accent bar
            Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_green, Color(0xFF34D399)]),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Column(
                children: [
                  // Header: avatar + name + price
                  Row(
                    children: [
                      buildAvatarCircle(
                        data['user']?['avatar']?.toString() ??
                            data['user']?['avatarUrl']?.toString(),
                        radius: 36,
                        backgroundColor: _green,
                        placeholderIconColor: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              clientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 12,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${rating.toStringAsFixed(1)} • $totalRides chuyến',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formattedPrice,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: _greenDark,
                              ),
                            ),
                            Text(
                              '${dist.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Route preview
                  _RouteRow(
                    icon: Icons.location_on_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    text: pickup,
                  ),
                  const SizedBox(height: 4),
                  _RouteRow(
                    icon: Icons.flag_rounded,
                    iconColor: const Color(0xFFEF4444),
                    text: dest,
                  ),

                  // Expanded detail
                  if (_expanded) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          _DetailChip(
                            icon: Icons.route_rounded,
                            label: 'Quãng đường',
                            value: '${dist.toStringAsFixed(1)} km',
                          ),
                          const SizedBox(width: 8),
                          _DetailChip(
                            icon: Icons.near_me_rounded,
                            label: 'Cách bạn',
                            value: '${distFromDriver.toStringAsFixed(1)} km',
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Action row
                  Row(
                    children: [
                      // Dismiss button
                      GestureDetector(
                        onTap: widget.onDismiss,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFFECACA),
                              width: 0.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Detail toggle
                      GestureDetector(
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFBBF7D0),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _expanded ? 'Ẩn bớt' : 'Chi tiết',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _greenDark,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _expanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: _greenDark,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Accept
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: widget.isLoading
                                ? null
                                : widget.onAccept,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: widget.isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Nhận chuyến',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ACTIVE RIDE PANEL
// ════════════════════════════════════════════════════════════════════════════

class _ActiveRidePanel extends StatelessWidget {
  final RideModel ride;
  final bool isLoading;
  final void Function(String status, double? price) onUpdateStatus;

  const _ActiveRidePanel({
    required this.ride,
    required this.isLoading,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final (actionText, nextStatus, desc) = _resolveAction(ride.status);
    final clientName = ride.user?.fullName ?? 'Hành khách';
    final initials = clientName.length >= 2
        ? clientName.substring(0, 2).toUpperCase()
        : clientName.toUpperCase();
    final rating = ride.user?.rating ?? 5.0;
    final totalRides = ride.user?.totalRides ?? 0;
    final formattedPrice = NumberFormat.simpleCurrency(
      locale: 'vi_VN',
      decimalDigits: 0,
    ).format(ride.estimatedPrice);

    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Status progress bar
          _StatusProgressBar(status: ride.status),
          const SizedBox(height: 14),

          // Status desc
          Text(
            desc,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          // User card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border, width: 0.5),
            ),
            child: Row(
              children: [
                buildAvatarCircle(
                  ride.user?.avatar,
                  radius: 44,
                  backgroundColor: _surface,
                  placeholderIconColor: _green,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 13,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${rating.toStringAsFixed(1)} • $totalRides chuyến',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Phone button
                _ActionButton(
                  icon: Icons.phone_rounded,
                  color: _green,
                  bgColor: const Color(0xFFECFDF5),
                  borderColor: const Color(0xFFBBF7D0),
                  onTap: () {
                    final phone = ride.user?.phoneNumber;
                    if (phone != null && phone.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gọi cho khách hàng: $phone'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 6),
                // Message button
                _ActionButton(
                  icon: Icons.chat_bubble_rounded,
                  color: const Color(0xFF3B82F6),
                  bgColor: const Color(0xFFEFF6FF),
                  borderColor: const Color(0xFFBFDBFE),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          rideId: ride.id,
                          currentUserId: ride.driver?.id ?? 'driver',
                          recipientName: ride.user?.fullName ?? 'Khách hàng',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Route card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border, width: 0.5),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Điểm đón',
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ride.pickupAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Column(
                    children: List.generate(
                      3,
                      (_) => Container(
                        width: 2,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 1),
                        color: const Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.flag_rounded,
                        size: 16,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Điểm đến',
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ride.destinationAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(height: 16, color: _border),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tiền chuyến đi',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    Text(
                      formattedPrice,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _greenDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // CTA button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () => onUpdateStatus(
                      nextStatus,
                      nextStatus == 'Completed' ? ride.estimatedPrice : null,
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      actionText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  (String, String, String) _resolveAction(String status) {
    return switch (status) {
      'Accepted' => (
        'Bắt đầu đi đón',
        'DriverArriving',
        'Hãy di chuyển đến vị trí đón hành khách.',
      ),
      'DriverArriving' => (
        'Tôi đã đến điểm đón',
        'DriverArrived',
        'Đang trên đường đến điểm đón...',
      ),
      'DriverArrived' => (
        'Bắt đầu hành trình',
        'InProgress',
        'Hành khách đã lên xe, bắt đầu chuyến đi.',
      ),
      'InProgress' => (
        'Hoàn thành chuyến đi',
        'Completed',
        'Đang di chuyển đến: ${ride.destinationAddress}',
      ),
      _ => ('Cập nhật trạng thái', status, ''),
    };
  }
}

// ────────────────────────────────────────────────────────────────────────────
// STATUS PROGRESS BAR
// ────────────────────────────────────────────────────────────────────────────

class _StatusProgressBar extends StatelessWidget {
  final String status;
  const _StatusProgressBar({required this.status});

  int get _currentStep => switch (status) {
    'Accepted' => 0,
    'DriverArriving' => 1,
    'DriverArrived' => 2,
    'InProgress' => 3,
    'Completed' => 4,
    _ => 0,
  };

  @override
  Widget build(BuildContext context) {
    final steps = ['Nhận', 'Đang đón', 'Đã đến', 'Đang đi'];
    final current = _currentStep;

    return Row(
      children: List.generate(steps.length, (i) {
        final isDone = i < current;
        final isActive = i == current;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? _green
                            : isActive
                            ? Colors.white
                            : const Color(0xFFF1F5F9),
                        border: isActive
                            ? Border.all(color: _green, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: Colors.white,
                              )
                            : isActive
                            ? Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _green,
                                ),
                              )
                            : Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFCBD5E1),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[i],
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isActive
                            ? _green
                            : isDone
                            ? const Color(0xFF64748B)
                            : const Color(0xFFCBD5E1),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 22),
                    decoration: BoxDecoration(
                      color: isDone ? _green : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ────────────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String initials;
  final double size;
  final double fontSize;

  const _Avatar({required this.initials, this.size = 36, this.fontSize = 13});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_green, Color(0xFF059669)],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _RouteRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
