import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'reachability.dart';

/// App-wide online/offline status.
///
/// Combines [Connectivity] adapter events with an IO DNS lookup so "Wi-Fi
/// connected, no internet" still counts as offline on mobile.
class AppDropConnectivity extends ChangeNotifier {
  AppDropConnectivity._();

  static final AppDropConnectivity instance = AppDropConnectivity._();

  final Connectivity _connectivity = Connectivity();

  bool _isOnline = true;
  bool _started = false;
  int _refreshToken = 0;
  Timer? _offlineDebounce;

  /// Optimistic true until the first check completes, so the first frame
  /// does not flash an overlay on a healthy connection.
  bool get isOnline => _isOnline;

  Future<void> ensureStarted() async {
    if (_started) return;
    _started = true;
    _connectivity.onConnectivityChanged.listen((results) {
      unawaited(_applyAdapterResults(results, debounceOffline: true));
    });
    await refresh();
  }

  /// Immediate re-check (used by "Try again"). Returns the new [isOnline].
  Future<bool> refresh() async {
    _offlineDebounce?.cancel();
    final results = await _connectivity.checkConnectivity();
    await _applyAdapterResults(results, debounceOffline: false);
    return _isOnline;
  }

  Future<void> _applyAdapterResults(
    List<ConnectivityResult> results, {
    required bool debounceOffline,
  }) async {
    final hasAdapter = results.any((r) => r != ConnectivityResult.none);
    if (!hasAdapter) {
      if (debounceOffline) {
        _scheduleOffline();
      } else {
        _setOnline(false);
      }
      return;
    }

    final token = ++_refreshToken;
    final reachable = await verifyInternetReachable();
    if (token != _refreshToken) return;
    if (reachable) {
      _offlineDebounce?.cancel();
      _setOnline(true);
    } else if (debounceOffline) {
      _scheduleOffline();
    } else {
      _setOnline(false);
    }
  }

  void _scheduleOffline() {
    _offlineDebounce?.cancel();
    _offlineDebounce = Timer(const Duration(milliseconds: 400), () {
      _setOnline(false);
    });
  }

  void _setOnline(bool value) {
    if (_isOnline == value) return;
    _isOnline = value;
    notifyListeners();
  }
}
