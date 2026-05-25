import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:leafgo_app/models/booking_models.dart';
import 'package:leafgo_app/services/repositories/booking_repository.dart';
import '../../core/services/location_service.dart';
import '../../core/services/signalr_service.dart';
import '../../services/datasources/auth_local_datasource.dart';

// ── Events ──────────────────────────────────────────────────
abstract class BookingEvent {}

class BookingLoadVehicleTypes extends BookingEvent {}
class BookingSearchLocation extends BookingEvent {
  final String query;
  final bool isPickup;
  BookingSearchLocation(this.query, this.isPickup);
}
class BookingSelectLocation extends BookingEvent {
  final LocationModel location;
  final bool isPickup;
  BookingSelectLocation(this.location, this.isPickup);
}
class BookingGetCurrentLocation extends BookingEvent {
  final bool isPickup;
  BookingGetCurrentLocation(this.isPickup);
}
class BookingFetchRoute extends BookingEvent {}
class BookingConfirmRoute extends BookingEvent {}
class BookingRequestRide extends BookingEvent {}
class BookingCancelRide extends BookingEvent {
  final String reason;
  BookingCancelRide(this.reason);
}
class BookingSubmitRating extends BookingEvent {
  final int rating;
  final String comment;
  BookingSubmitRating(this.rating, this.comment);
}
class BookingCheckActiveRide extends BookingEvent {}
class BookingUpdateStatus extends BookingEvent {
  final String status;
  BookingUpdateStatus(this.status);
}
class BookingReset extends BookingEvent {}
class BookingUpdateDriverLocation extends BookingEvent {
  final LatLng location;
  BookingUpdateDriverLocation(this.location);
}
class BookingSelectVehicleType extends BookingEvent {
  final String vehicleTypeId;
  BookingSelectVehicleType(this.vehicleTypeId);
}

// ── State ───────────────────────────────────────────────────
class BookingState {
  final List<VehicleType> vehicleTypes;
  final String? selectedVehicleTypeId;
  final LocationModel? pickupLocation;
  final LocationModel? dropoffLocation;
  final List<LocationModel> searchResults;
  final List<LatLng> routeCoordinates;
  final Map<String, dynamic>? priceData;
  final RideModel? currentRide;
  final LatLng? driverLocation;
  final bool isLoading;
  final String? error;
  final int resetCounter;

  BookingState({
    this.vehicleTypes = const [],
    this.selectedVehicleTypeId,
    this.pickupLocation,
    this.dropoffLocation,
    this.searchResults = const [],
    this.routeCoordinates = const [],
    this.priceData,
    this.currentRide,
    this.driverLocation,
    this.isLoading = false,
    this.error,
    this.resetCounter = 0,
  });

  BookingState copyWith({
    List<VehicleType>? vehicleTypes,
    String? selectedVehicleTypeId,
    LocationModel? pickupLocation,
    LocationModel? dropoffLocation,
    List<LocationModel>? searchResults,
    List<LatLng>? routeCoordinates,
    Map<String, dynamic>? priceData,
    RideModel? currentRide,
    LatLng? driverLocation,
    bool? isLoading,
    String? error,
    int? resetCounter,
    bool clearPickup = false,
    bool clearDropoff = false,
  }) {
    return BookingState(
      vehicleTypes: vehicleTypes ?? this.vehicleTypes,
      selectedVehicleTypeId: selectedVehicleTypeId ?? this.selectedVehicleTypeId,
      pickupLocation: clearPickup ? null : (pickupLocation ?? this.pickupLocation),
      dropoffLocation: clearDropoff ? null : (dropoffLocation ?? this.dropoffLocation),
      searchResults: searchResults ?? this.searchResults,
      routeCoordinates: routeCoordinates ?? this.routeCoordinates,
      priceData: priceData ?? this.priceData,
      currentRide: currentRide ?? this.currentRide,
      driverLocation: driverLocation ?? this.driverLocation,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      resetCounter: resetCounter ?? this.resetCounter,
    );
  }
}

// ── BLoC ────────────────────────────────────────────────────
class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository repository;
  final LocationService locationService;
  final SignalRService signalRService;
  final AuthLocalDataSource authLocalDataSource;
  String? _token;
  int _pickupLocationVersion = 0;
  int _dropoffLocationVersion = 0;

  BookingBloc({
    required this.repository,
    required this.locationService,
    required this.signalRService,
    required this.authLocalDataSource,
  }) : super(BookingState()) {
    on<BookingLoadVehicleTypes>(_onLoadVehicleTypes);
    on<BookingSearchLocation>(
      _onSearchLocation,
      transformer: _debounce(const Duration(milliseconds: 300)),
    );
    on<BookingSelectLocation>(_onSelectLocation);
    on<BookingGetCurrentLocation>(_onGetCurrentLocation);
    on<BookingFetchRoute>(_onFetchRoute);
    on<BookingRequestRide>(_onRequestRide);
    on<BookingCancelRide>(_onCancelRide);
    on<BookingCheckActiveRide>(_onCheckActiveRide);
    on<BookingUpdateStatus>(_onUpdateStatus);
    on<BookingUpdateDriverLocation>(_onUpdateDriverLocation);
    on<BookingSelectVehicleType>((event, emit) {
      final updatedState = state.copyWith(selectedVehicleTypeId: event.vehicleTypeId);
      emit(updatedState);
      if (updatedState.pickupLocation != null && updatedState.dropoffLocation != null) {
        add(BookingFetchRoute());
      }
    });
    on<BookingReset>((event, emit) {
      emit(BookingState(
        vehicleTypes: state.vehicleTypes,
        selectedVehicleTypeId: state.selectedVehicleTypeId,
        resetCounter: state.resetCounter + 1,
      ));
    });
    
    _initialize();
  }

  Future<void> _initialize() async {
    final user = await authLocalDataSource.getCachedUser();
    _token = user?.accessToken;
    if (_token != null) {
      await signalRService.startConnection(_token);
      _setupSignalR();
      add(BookingCheckActiveRide());
    }
  }

  void _setupSignalR() {
    signalRService.onRideAccepted((data) {
      add(BookingUpdateStatus('Accepted'));
      // Re-fetch full ride to get driver info
      add(BookingCheckActiveRide());
    });
    signalRService.onRideStatusChanged((data) {
      add(BookingUpdateStatus(data['status']));
    });
    signalRService.onDriverLocationUpdated((data) {
      final lat = double.tryParse(data['latitude'].toString());
      final lng = double.tryParse(data['longitude'].toString());
      if (lat != null && lng != null && _isValidLatLng(lat, lng)) {
        add(BookingUpdateDriverLocation(LatLng(lat, lng)));
      }
    });
    signalRService.onRideCompleted((data) => add(BookingUpdateStatus('Completed')));
    signalRService.onRideCancelled((data) => add(BookingUpdateStatus('Cancelled')));
  }

  Future<void> _onLoadVehicleTypes(BookingLoadVehicleTypes event, Emitter<BookingState> emit) async {
    try {
      if (_token == null) {
        final user = await authLocalDataSource.getCachedUser();
        _token = user?.accessToken;
      }
      if (_token == null) {
        throw Exception('Token not found. Please log in again.');
      }
      final types = await repository.getVehicleTypes(_token!);
      emit(state.copyWith(
        vehicleTypes: types,
        selectedVehicleTypeId: types.isNotEmpty ? types.first.id : null,
      ));
      
      if (types.isNotEmpty && state.pickupLocation != null && state.dropoffLocation != null) {
        add(BookingFetchRoute());
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onSearchLocation(BookingSearchLocation event, Emitter<BookingState> emit) async {
    if (event.isPickup) {
      _pickupLocationVersion++;
    } else {
      _dropoffLocationVersion++;
    }

    if (event.query.trim().isEmpty) {
      emit(event.isPickup
          ? state.copyWith(clearPickup: true, searchResults: [])
          : state.copyWith(clearDropoff: true, searchResults: []));
      return;
    }
    
    // Clear the active selected location from state so the listener doesn't overwrite the user's typing
    emit(event.isPickup
        ? state.copyWith(clearPickup: true, searchResults: [])
        : state.copyWith(clearDropoff: true, searchResults: []));

    try {
      final results = await locationService.searchLocations(event.query);
      emit(state.copyWith(searchResults: results));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onSelectLocation(BookingSelectLocation event, Emitter<BookingState> emit) {
    if (event.isPickup) {
      _pickupLocationVersion++;
    } else {
      _dropoffLocationVersion++;
    }

    final updatedState = event.isPickup
        ? state.copyWith(pickupLocation: event.location, searchResults: [])
        : state.copyWith(dropoffLocation: event.location, searchResults: []);
    
    emit(updatedState);

    if (updatedState.pickupLocation != null && updatedState.dropoffLocation != null) {
      add(BookingFetchRoute());
    }
  }

  Future<void> _onGetCurrentLocation(BookingGetCurrentLocation event, Emitter<BookingState> emit) async {
    // 5. Fix race condition: Tăng version ngay lập tức khi bắt đầu fetch để chặn các kết quả cũ hoặc chồng chéo
    if (event.isPickup) {
      _pickupLocationVersion++;
    } else {
      _dropoffLocationVersion++;
    }
    final locationVersionAtStart = event.isPickup ? _pickupLocationVersion : _dropoffLocationVersion;
    emit(state.copyWith(isLoading: true));
    try {
      // 1. Dùng getCurrentPosition() theo đúng locationService hiện tại
      final pos = await locationService.getCurrentPosition();
      final loc = await locationService.reverseGeocode(pos.latitude, pos.longitude);
      
      if (loc != null) {
        final locationVersionNow = event.isPickup ? _pickupLocationVersion : _dropoffLocationVersion;
        if (locationVersionNow != locationVersionAtStart) return;
        add(BookingSelectLocation(loc, event.isPickup));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onFetchRoute(BookingFetchRoute event, Emitter<BookingState> emit) async {
    if (state.pickupLocation == null || state.dropoffLocation == null) return;
    emit(state.copyWith(isLoading: true));
    try {
      final route = await locationService.getRoute(state.pickupLocation!, state.dropoffLocation!);
      
      Map<String, dynamic>? price;
      if (state.selectedVehicleTypeId != null) {
        try {
          price = await repository.calculateTripPrice(
            state.pickupLocation!.lat,
            state.pickupLocation!.lng,
            state.dropoffLocation!.lat,
            state.dropoffLocation!.lng,
            state.selectedVehicleTypeId!,
          );
        } catch (e) {
          print('Price calculation API failed: $e');
        }
      }
      
      // If price API failed or vehicle type is missing, calculate a beautiful fallback price client-side
      if (price == null) {
        final distanceMeters = Geolocator.distanceBetween(
          state.pickupLocation!.lat,
          state.pickupLocation!.lng,
          state.dropoffLocation!.lat,
          state.dropoffLocation!.lng,
        );
        final distanceKm = double.parse((distanceMeters / 1000.0).toStringAsFixed(1));
        final rate = 15000.0; // 15,000 VND per KM standard rate
        final estimatedPrice = distanceKm * rate;
        
        price = {
          'distance': distanceKm,
          'estimatedDuration': (distanceKm * 2).toInt(), // Approx 2 mins per KM
          'estimatedPrice': estimatedPrice,
        };
      }

      emit(state.copyWith(routeCoordinates: route, priceData: price));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onRequestRide(BookingRequestRide event, Emitter<BookingState> emit) async {
    // 4. Fix null safety: Kiểm tra toàn bộ state liên quan trước khi request
    if (state.pickupLocation == null ||
        state.dropoffLocation == null ||
        state.selectedVehicleTypeId == null ||
        state.priceData == null) {
      return;
    }
    
    emit(state.copyWith(isLoading: true));
    if (_token == null) {
      emit(state.copyWith(isLoading: false, error: 'Chưa đăng nhập.'));
      return;
    }
    
    try {
      final rideData = {
        'vehicleTypeId': state.selectedVehicleTypeId,
        'pickupAddress': state.pickupLocation!.fullAddress,
        'pickupLatitude': state.pickupLocation!.lat,
        'pickupLongitude': state.pickupLocation!.lng,
        'destinationAddress': state.dropoffLocation!.fullAddress,
        'destinationLatitude': state.dropoffLocation!.lat,
        'destinationLongitude': state.dropoffLocation!.lng,
        'distance': state.priceData!['distance'],
        'estimatedDuration': state.priceData!['estimatedDuration'],
        'estimatedPrice': state.priceData!['estimatedPrice'],
      };
      final ride = await repository.createRide(rideData, _token!);
      emit(state.copyWith(currentRide: ride));
      await signalRService.joinRideGroup(ride.id);
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onCancelRide(BookingCancelRide event, Emitter<BookingState> emit) async {
    if (state.currentRide == null || _token == null) return;
    final rideId = state.currentRide!.id;
    try {
      await repository.cancelRide(rideId, event.reason, _token!);
      emit(state.copyWith(
        currentRide: null,
        driverLocation: null,
        routeCoordinates: [],
        priceData: null,
      ));
      try {
        await signalRService.leaveRideGroup(rideId);
      } catch (_) {}
    } catch (e) {
      emit(state.copyWith(
        currentRide: null,
        driverLocation: null,
        routeCoordinates: [],
        priceData: null,
        error: 'Lỗi hủy chuyến: $e',
      ));
    }
  }

  Future<void> _onCheckActiveRide(BookingCheckActiveRide event, Emitter<BookingState> emit) async {
    if (_token == null) return;
    try {
      final ride = await repository.getActiveRide(_token!);
      if (ride != null) {
        emit(state.copyWith(currentRide: ride));
        await signalRService.joinRideGroup(ride.id);
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onUpdateStatus(BookingUpdateStatus event, Emitter<BookingState> emit) {
    if (state.currentRide != null) {
      // Create updated ride model
      final updatedRide = RideModel(
        id: state.currentRide!.id,
        status: event.status,
        pickupAddress: state.currentRide!.pickupAddress,
        pickupLatitude: state.currentRide!.pickupLatitude,
        pickupLongitude: state.currentRide!.pickupLongitude,
        destinationAddress: state.currentRide!.destinationAddress,
        destinationLatitude: state.currentRide!.destinationLatitude,
        destinationLongitude: state.currentRide!.destinationLongitude,
        distance: state.currentRide!.distance,
        estimatedDuration: state.currentRide!.estimatedDuration,
        estimatedPrice: state.currentRide!.estimatedPrice,
        finalPrice: state.currentRide!.finalPrice,
        notes: state.currentRide!.notes,
        driver: state.currentRide!.driver,
      );
      emit(state.copyWith(currentRide: updatedRide));
    }
  }

  void _onUpdateDriverLocation(BookingUpdateDriverLocation event, Emitter<BookingState> emit) {
    if (!_isValidLatLng(event.location.latitude, event.location.longitude)) return;
    emit(state.copyWith(driverLocation: event.location));
  }

  bool _isValidLatLng(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  EventTransformer<Event> _debounce<Event>(Duration duration) {
    return (events, mapper) {
      Timer? timer;
      StreamController<Event>? controller;
      StreamSubscription<Event>? subscription;

      controller = StreamController<Event>(
        onListen: () {
          subscription = events.listen(
            (data) {
              timer?.cancel();
              timer = Timer(duration, () => controller?.add(data));
            },
            onError: (err) => controller?.addError(err),
            onDone: () => controller?.close(),
          );
        },
        onCancel: () {
          timer?.cancel();
          subscription?.cancel();
        },
      );

      return controller.stream.asyncExpand(mapper);
    };
  }
}
