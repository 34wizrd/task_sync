import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

/// Reliable online/offline by combining connectivity with a real reachability probe.
/// Compatible with connectivity_plus streams that emit either ConnectivityResult OR List<ConnectivityResult>.
class ConnectivityNotifier extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription<dynamic>? _connSub; // dynamic = both shapes
  StreamSubscription<InternetConnectionStatus>? _internetSub;

  Future<void> init() async {
    _setOnline(await InternetConnectionChecker.instance.hasConnection);

    _connSub = Connectivity().onConnectivityChanged.listen((_) async {
      final ok = await InternetConnectionChecker.instance.hasConnection;
      _setOnline(ok);
    });

    _internetSub = InternetConnectionChecker.instance.onStatusChange.listen((s) {
      _setOnline(s == InternetConnectionStatus.connected);
    });
  }

  void _setOnline(bool v) {
    if (_isOnline == v) return;
    _isOnline = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _internetSub?.cancel();
    super.dispose();
  }
}
