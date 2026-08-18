import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:rxdart/rxdart.dart';
import 'package:singleton/singleton.dart';

enum ConnectionStatus { online, offline }

/// Tracks device connectivity and exposes a debounced [ConnectionStatus]
/// stream so brief/flappy drops (e.g. a few seconds of switching towers)
/// don't cause the offline banner to flicker on and off.
class ConnectivityService {
  /// Factory method that reuse same instance automatically
  factory ConnectivityService() => Singleton.lazy(() => ConnectivityService._());

  ConnectivityService._() {
    _init();
  }

  /// How long connectivity must stay down before we report it as offline.
  static const _offlineDebounce = Duration(seconds: 5);

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final BehaviorSubject<ConnectionStatus> statusStream =
      BehaviorSubject<ConnectionStatus>.seeded(ConnectionStatus.online);

  ConnectionStatus get currentStatus => statusStream.value;

  //raw connectivity ticks, debounced before hitting statusStream
  final _rawConnectedController = StreamController<bool>.broadcast();
  StreamSubscription? _debouncedSubscription;

  void _init() async {
    _debouncedSubscription = _rawConnectedController.stream
        .distinct()
        .switchMap((isConnected) {
          //report "back online" immediately, but only report "offline"
          //after it has stayed down for the debounce window, avoiding
          //flicker from connections that drop and recover within seconds
          if (isConnected) {
            return Stream.value(ConnectionStatus.online);
          }
          return Stream.value(ConnectionStatus.offline).delay(_offlineDebounce);
        })
        .listen((status) {
          if (status != statusStream.value) {
            statusStream.add(status);
          }
        });

    final initialResults = await _connectivity.checkConnectivity();
    _emitRaw(_hasConnection(initialResults));

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _emitRaw(_hasConnection(results));
    });
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  void _emitRaw(bool isConnected) {
    _rawConnectedController.add(isConnected);
  }

  void dispose() {
    _subscription?.cancel();
    _debouncedSubscription?.cancel();
    _rawConnectedController.close();
    statusStream.close();
  }
}
