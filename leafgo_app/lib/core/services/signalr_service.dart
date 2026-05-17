import 'package:signalr_netcore/signalr_client.dart';
import 'package:flutter/foundation.dart';

class SignalRService {
  HubConnection? _hubConnection;
  final String baseUrl;

  SignalRService({required this.baseUrl});

  Future<void> startConnection(String? accessToken) async {
    if (_hubConnection != null && _hubConnection!.state == HubConnectionState.Connected) {
      return;
    }

    final httpOptions = HttpConnectionOptions(
      accessTokenFactory: () async => accessToken ?? '',
      logMessageContent: true,
    );

    _hubConnection = HubConnectionBuilder()
        .withUrl('$baseUrl/rideHub', options: httpOptions)
        .withAutomaticReconnect()
        .build();

    try {
      await _hubConnection!.start();
      debugPrint('[SignalR] Connection started');
    } catch (e) {
      debugPrint('[SignalR] Error starting connection: $e');
    }
  }

  void onRideAccepted(Function(Map<String, dynamic>) callback) {
    _hubConnection?.on('RideAccepted', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        callback(arguments[0] as Map<String, dynamic>);
      }
    });
  }

  void onRideStatusChanged(Function(Map<String, dynamic>) callback) {
    _hubConnection?.on('RideStatusChanged', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        callback(arguments[0] as Map<String, dynamic>);
      }
    });
  }

  void onDriverLocationUpdated(Function(Map<String, dynamic>) callback) {
    _hubConnection?.on('DriverLocationUpdated', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        callback(arguments[0] as Map<String, dynamic>);
      }
    });
  }

  void onRideCompleted(Function(Map<String, dynamic>) callback) {
    _hubConnection?.on('RideCompleted', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        callback(arguments[0] as Map<String, dynamic>);
      }
    });
  }

  void onRideCancelled(Function(Map<String, dynamic>) callback) {
    _hubConnection?.on('RideCancelled', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        callback(arguments[0] as Map<String, dynamic>);
      }
    });
  }

  Future<void> joinRideGroup(String rideId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection!.invoke('JoinRideGroup', args: [rideId]);
    }
  }

  Future<void> leaveRideGroup(String rideId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection!.invoke('LeaveRideGroup', args: [rideId]);
    }
  }

  void stopConnection() {
    _hubConnection?.stop();
  }

  void offAll() {
    _hubConnection?.off('RideAccepted');
    _hubConnection?.off('RideStatusChanged');
    _hubConnection?.off('DriverLocationUpdated');
    _hubConnection?.off('RideCompleted');
    _hubConnection?.off('RideCancelled');
  }
}
