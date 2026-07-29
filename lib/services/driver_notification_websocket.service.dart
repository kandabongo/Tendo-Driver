import 'package:fuodz/services/auth.service.dart';
import 'package:fuodz/services/websocket.service.dart';
import 'package:laravel_echo_null/laravel_echo_null.dart';

class DriverNotificationWebsocketService {
  static final DriverNotificationWebsocketService _instance =
      DriverNotificationWebsocketService._internal();
  factory DriverNotificationWebsocketService() => _instance;

  DriverNotificationWebsocketService._internal();

  PrivateChannel? _eventChannel;
  Function(dynamic data)? _onNewOrder;
  Function(dynamic data)? _onAssignment;
  String? _channelName;
  bool _isListeningToNewOrder = false;
  bool _isListeningToAssignment = false;

  Future<void> connect({
    Function(dynamic data)? onNewOrder,
    Function(dynamic data)? onAssignment,
  }) async {
    final driverId = (await AuthServices.getCurrentUser()).id.toString();
    _channelName = "driver.new-order.$driverId";
    await WebsocketService().init();

    if (onNewOrder != null) {
      _onNewOrder = onNewOrder;
      _isListeningToNewOrder = true;
    }
    if (onAssignment != null) {
      _onAssignment = onAssignment;
      _isListeningToAssignment = true;
    }

    _subscribeToChannel();
  }

  void _subscribeToChannel() {
    final echo = WebsocketService().echoClient;
    if (echo == null || _channelName == null) return;

    // Only unsubscribe and re-subscribe if it's not already active or name changed
    if (_eventChannel == null) {
      _eventChannel = echo.private(_channelName!);
      _eventChannel?.subscribe();

      // Setup Listeners
      _eventChannel?.listen(".WebsocketDriverNewOrderEvent", (event) {
        if (_isListeningToNewOrder) {
          print("[DriverNotification] New Order Event: $event");
          _onNewOrder?.call(event);
        }
      });

      _eventChannel?.listen(".DriverOrderAssignmentEvent", (event) {
        if (_isListeningToAssignment) {
          print("[DriverNotification] Order Assignment Event: $event");
          _onAssignment?.call(event);
        }
      });
    }
  }

  void disconnectNewOrder() {
    _onNewOrder = null;
    _isListeningToNewOrder = false;
    _maybeFullDisconnect();
  }

  void disconnectAssignment() {
    _onAssignment = null;
    _isListeningToAssignment = false;
    _maybeFullDisconnect();
  }

  void _maybeFullDisconnect() {
    if (!_isListeningToNewOrder && !_isListeningToAssignment) {
      print("[DriverNotification] Both listeners inactive. Disconnecting channel.");
      disconnect();
    }
  }

  Future<void> disconnect() async {
    try {
      _eventChannel?.unsubscribe();
    } catch (error) {
      print("Error unsubscribing from DriverNotification channel: $error");
    }
    _eventChannel = null;
    _onNewOrder = null;
    _onAssignment = null;
    _channelName = null;
    _isListeningToNewOrder = false;
    _isListeningToAssignment = false;
  }
}
