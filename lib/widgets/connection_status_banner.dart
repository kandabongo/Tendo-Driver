import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fuodz/services/connectivity.service.dart';
import 'package:localize_and_translate/localize_and_translate.dart';

/// Shows a persistent red banner while the device is offline, and a
/// brief auto-dismissing green banner when connectivity is restored.
class ConnectionStatusBanner extends StatefulWidget {
  const ConnectionStatusBanner({Key? key}) : super(key: key);

  @override
  State<ConnectionStatusBanner> createState() =>
      _ConnectionStatusBannerState();
}

class _ConnectionStatusBannerState extends State<ConnectionStatusBanner> {
  static const _restoredBannerDuration = Duration(seconds: 3);

  static final _offlineBackgroundColor = Colors.red.shade100;
  static final _offlineIconColor = Colors.red.shade900;
  static final _restoredBackgroundColor = Colors.green.shade100;
  static final _restoredIconColor = Colors.green.shade900;

  StreamSubscription<ConnectionStatus>? _subscription;
  bool _visible = false;
  bool _isOffline = false;
  Timer? _restoredTimer;
  ConnectionStatus? _lastStatus;

  @override
  void initState() {
    super.initState();
    _subscription = ConnectivityService().statusStream.listen(_onStatus);
  }

  void _onStatus(ConnectionStatus status) {
    final previousStatus = _lastStatus;
    _lastStatus = status;
    _restoredTimer?.cancel();

    if (status == ConnectionStatus.offline) {
      setState(() {
        _visible = true;
        _isOffline = true;
      });
      return;
    }

    //connection restored
    if (previousStatus == ConnectionStatus.offline) {
      setState(() {
        _visible = true;
        _isOffline = false;
      });
      _restoredTimer = Timer(_restoredBannerDuration, () {
        if (mounted) setState(() => _visible = false);
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _restoredTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1,
            child: child,
          ),
          child: _visible
              ? Material(
                  key: ValueKey(_isOffline),
                  color: _isOffline
                      ? _offlineBackgroundColor
                      : _restoredBackgroundColor,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isOffline ? Icons.cloud_off : Icons.cloud_done,
                          color: _isOffline
                              ? _offlineIconColor
                              : _restoredIconColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _isOffline
                                ? "No internet connection".tr()
                                : "Back online".tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isOffline
                                  ? _offlineIconColor
                                  : _restoredIconColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
