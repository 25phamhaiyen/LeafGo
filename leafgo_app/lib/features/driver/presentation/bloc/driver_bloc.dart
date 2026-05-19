import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leafgo_app/features/booking/data/models/booking_models.dart';
import 'package:leafgo_app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:leafgo_app/core/services/location_service.dart';
import 'package:leafgo_app/core/services/signalr_service.dart';
import '../../domain/repositories/driver_repository.dart';
import '../../data/models/driver_models.dart';

// ── Events ──────────────────────────────────────────────────
abstract class DriverEvent {}

class DriverCheckActiveRide extends DriverEvent {}
class DriverLoadProfile extends DriverEvent {}
class DriverToggleOnline extends DriverEvent {}
class DriverPollPendingRides extends DriverEvent {}
class DriverUpdateLocation extends DriverEvent {}
class DriverAcceptRide extends DriverEvent {
  final String rideId;
  final String version;
  DriverAcceptRide(this.rideId, this.version);
}
class DriverUpdateRideStatus extends DriverEvent {
  final String status;
  final double? finalPrice;
  DriverUpdateRideStatus(this.status, {this.finalPrice});
}
class DriverUpdateVehicle extends DriverEvent {
  final String vehicleTypeId;
  final String licensePlate;
  final String vehicleBrand;
  final String vehicleModel;
  final String vehicleColor;
  DriverUpdateVehicle({
    required this.vehicleTypeId,
    required this.licensePlate,
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.vehicleColor,
  });
}
class DriverResetState extends DriverEvent {}

// ── State ───────────────────────────────────────────────────
class DriverState {
  final bool isOnline;
  final RideModel? currentRide;
  final List<dynamic> pendingRides;
  final DriverStatsModel? stats;
  final DriverVehicleModel? vehicle;
  final bool isLoading;
  final String? error;

  DriverState({
    this.isOnline = false,
    this.currentRide,
    this.pendingRides = const [],
    this.stats,
    this.vehicle,
    this.isLoading = false,
    this.error,
  });

  DriverState copyWith({
    bool? isOnline,
    RideModel? currentRide,
    List<dynamic>? pendingRides,
    DriverStatsModel? stats,
    DriverVehicleModel? vehicle,
    bool? isLoading,
    String? error,
    bool clearCurrentRide = false,
  }) {
    return DriverState(
      isOnline: isOnline ?? this.isOnline,
      currentRide: clearCurrentRide ? null : (currentRide ?? this.currentRide),
      pendingRides: pendingRides ?? this.pendingRides,
      stats: stats ?? this.stats,
      vehicle: vehicle ?? this.vehicle,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ── BLoC ────────────────────────────────────────────────────
class DriverBloc extends Bloc<DriverEvent, DriverState> {
  final DriverRepository repository;
  final LocationService locationService;
  final SignalRService signalRService;
  final AuthLocalDataSource authLocalDataSource;

  Timer? _pollingTimer;
  Timer? _locationTimer;
  String? _token;

  DriverBloc({
    required this.repository,
    required this.locationService,
    required this.signalRService,
    required this.authLocalDataSource,
  }) : super(DriverState()) {
    on<DriverCheckActiveRide>(_onCheckActiveRide);
    on<DriverLoadProfile>(_onLoadProfile);
    on<DriverToggleOnline>(_onToggleOnline);
    on<DriverPollPendingRides>(_onPollPendingRides);
    on<DriverUpdateLocation>(_onUpdateLocation);
    on<DriverAcceptRide>(_onAcceptRide);
    on<DriverUpdateRideStatus>(_onUpdateRideStatus);
    on<DriverUpdateVehicle>(_onUpdateVehicle);
    on<DriverResetState>(_onResetState);
  }

  Future<String?> _getToken() async {
    if (_token != null) return _token;
    final user = await authLocalDataSource.getCachedUser();
    _token = user?.accessToken;
    return _token;
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    _locationTimer?.cancel();
    return super.close();
  }

  Future<void> _onCheckActiveRide(DriverCheckActiveRide event, Emitter<DriverState> emit) async {
    try {
      final token = await _getToken();
      if (token == null) return;
      final activeRide = await repository.getCurrentRide(token);
      if (activeRide != null) {
        emit(state.copyWith(currentRide: activeRide));
        _startLocationUpdates();
        _stopPendingRidesPolling();
      }
    } catch (_) {}
  }

  Future<void> _onLoadProfile(DriverLoadProfile event, Emitter<DriverState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Chưa đăng nhập');
      final stats = await repository.getStatistics(token);
      final vehicle = await repository.getVehicle(token);
      emit(state.copyWith(stats: stats, vehicle: vehicle, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> _onToggleOnline(DriverToggleOnline event, Emitter<DriverState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Chưa đăng nhập');
      final nextOnline = !state.isOnline;
      await repository.toggleOnline(nextOnline, token);

      emit(state.copyWith(isOnline: nextOnline, isLoading: false));

      if (nextOnline) {
        _startPendingRidesPolling();
        _startLocationUpdates();
      } else {
        _stopPendingRidesPolling();
        _stopLocationUpdates();
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  void _startPendingRidesPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      add(DriverPollPendingRides());
    });
  }

  void _stopPendingRidesPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _startLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      add(DriverUpdateLocation());
    });
    add(DriverUpdateLocation()); // Trigger immediately once
  }

  void _stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> _onPollPendingRides(DriverPollPendingRides event, Emitter<DriverState> emit) async {
    if (!state.isOnline || state.currentRide != null) {
      _stopPendingRidesPolling();
      return;
    }
    try {
      final token = await _getToken();
      if (token == null) return;
      final pos = await locationService.getCurrentPosition();
      final rides = await repository.getPendingRides(pos.latitude, pos.longitude, 5, token);
      emit(state.copyWith(pendingRides: rides));
    } catch (_) {}
  }

  Future<void> _onUpdateLocation(DriverUpdateLocation event, Emitter<DriverState> emit) async {
    try {
      final token = await _getToken();
      if (token == null) return;
      final pos = await locationService.getCurrentPosition();
      await repository.updateLocation(pos.latitude, pos.longitude, token);
    } catch (_) {}
  }

  Future<void> _onAcceptRide(DriverAcceptRide event, Emitter<DriverState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Chưa đăng nhập');
      await repository.acceptRide(event.rideId, event.version, token);
      
      final activeRide = await repository.getCurrentRide(token);
      emit(state.copyWith(currentRide: activeRide, isLoading: false));

      if (activeRide != null) {
        await signalRService.joinRideGroup(activeRide.id);
        _stopPendingRidesPolling();
        _startLocationUpdates();
      }
    } catch (e) {
      emit(state.copyWith(error: 'Không thể nhận chuyến: $e', isLoading: false));
    }
  }

  Future<void> _onUpdateRideStatus(DriverUpdateRideStatus event, Emitter<DriverState> emit) async {
    if (state.currentRide == null) return;
    emit(state.copyWith(isLoading: true));
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Chưa đăng nhập');
      final rideId = state.currentRide!.id;
      
      await repository.updateRideStatus(rideId, event.status, event.finalPrice, token);

      if (event.status == 'Completed' || event.status == 'Cancelled') {
        emit(state.copyWith(clearCurrentRide: true, isLoading: false));
        _stopLocationUpdates();
        if (state.isOnline) {
          _startPendingRidesPolling();
        }
      } else {
        final updatedRide = await repository.getCurrentRide(token);
        emit(state.copyWith(currentRide: updatedRide, isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(error: 'Lỗi cập nhật tiến trình: $e', isLoading: false));
    }
  }

  Future<void> _onUpdateVehicle(DriverUpdateVehicle event, Emitter<DriverState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Chưa đăng nhập');
      final updatedVehicle = await repository.updateVehicle({
        'vehicleTypeId': event.vehicleTypeId,
        'licensePlate': event.licensePlate,
        'vehicleBrand': event.vehicleBrand,
        'vehicleModel': event.vehicleModel,
        'vehicleColor': event.vehicleColor,
      }, token);

      emit(state.copyWith(vehicle: updatedVehicle, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: 'Lỗi cập nhật phương tiện: $e', isLoading: false));
    }
  }

  void _onResetState(DriverResetState event, Emitter<DriverState> emit) {
    _pollingTimer?.cancel();
    _locationTimer?.cancel();
    emit(DriverState());
  }
}
