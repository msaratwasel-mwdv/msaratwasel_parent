import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';

class OfflineBannerWrapper extends StatefulWidget {
  final Widget child;

  const OfflineBannerWrapper({super.key, required this.child});

  @override
  State<OfflineBannerWrapper> createState() => _OfflineBannerWrapperState();
}

class _OfflineBannerWrapperState extends State<OfflineBannerWrapper> {
  bool _hasInternet = true;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;
  Timer? _offlineTimer;

  @override
  void initState() {
    super.initState();
    _checkInitial();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });
  }

  Future<void> _checkInitial() async {
    final results = await Connectivity().checkConnectivity();
    await _updateStatus(results);
  }

  Future<void> _updateStatus(List<ConnectivityResult> results) async {
    bool hasConnection = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    
    if (!hasConnection) {
      _setInternetStatus(false);
      return;
    }

    try {
      final lookupResult = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 3),
      );
      final hasActualInternet = lookupResult.isNotEmpty && lookupResult[0].rawAddress.isNotEmpty;
      _setInternetStatus(hasActualInternet);
    } catch (_) {
      _setInternetStatus(false);
    }
  }

  void _setInternetStatus(bool hasInternet) {
    if (_hasInternet == hasInternet) return;
    
    if (mounted) {
      setState(() {
        _hasInternet = hasInternet;
      });
    }

    if (!hasInternet) {
      _startOfflineTimer();
    } else {
      _stopOfflineTimer();
    }
  }

  void _startOfflineTimer() {
    _offlineTimer?.cancel();
    _offlineTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final lookupResult = await InternetAddress.lookup('google.com').timeout(
          const Duration(seconds: 3),
        );
        if (lookupResult.isNotEmpty && lookupResult[0].rawAddress.isNotEmpty) {
          _setInternetStatus(true);
        }
      } catch (_) {
        // Still offline
      }
    });
  }

  void _stopOfflineTimer() {
    _offlineTimer?.cancel();
    _offlineTimer = null;
  }

  @override
  void dispose() {
    _subscription.cancel();
    _stopOfflineTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Stack(
      children: [
        widget.child,
        if (!_hasInternet)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.shade700,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        context.t('noInternetConnection'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'GoogleSans',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
